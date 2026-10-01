import 'package:bs_mobile/src/core/ai/ai_config.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_message.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_response.dart';
import 'package:bs_mobile/src/core/ai/models/ai_page_context.dart';
import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';
import 'package:bs_mobile/src/features/ai/repository/ai_chat_repository.dart';
import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:meta/meta.dart';

part 'ai_chat_event.dart';
part 'ai_chat_state.dart';

class AiChatBloc extends Bloc<AiChatEvent, AiChatState> {
  AiChatBloc({required AiChatRepository repository})
    : _repository = repository,
      super(const AiChatState()) {
    on<OpenAiChatEvent>(_onOpen);
    on<SendAiMessageEvent>(_onSend);
    on<ClearAiChatEvent>(_onClear);
    on<ConfirmAiProposalEvent>(_onConfirmProposal);
    on<RejectAiProposalEvent>(_onRejectProposal);
    on<DismissPendingActionEvent>(_onDismissPending);
    on<LoadAiSuggestionsEvent>(_onLoadSuggestions);
    on<HideAiSuggestionsEvent>(_onHideSuggestions);
    on<ShowAiSuggestionsEvent>(_onShowSuggestions);
  }

  final AiChatRepository _repository;

  Future<void> _onOpen(OpenAiChatEvent event, Emitter<AiChatState> emit) async {
    final greeting = event.greeting?.trim();
    final messages =
        state.messages.isEmpty && greeting != null && greeting.isNotEmpty
        ? [AiChatMessage.assistant(greeting)]
        : state.messages;

    emit(
      state.copyWith(
        process: event.process,
        messages: messages,
        systemPromptId: event.systemPromptId,
        pageContext: event.pageContext,
        clearError: true,
        clearPendingResponse: true,
        proposalBusyIds: const {},
        suggestions: const [],
        suggestionsHidden: false,
      ),
    );

    add(LoadAiSuggestionsEvent());
  }

  Future<void> _onSend(
    SendAiMessageEvent event,
    Emitter<AiChatState> emit,
  ) async {
    final text = event.text.trim();
    if (text.isEmpty || state.isSending) return;

    final history = [...state.messages, AiChatMessage.user(text)];

    emit(
      state.copyWith(
        messages: history,
        isSending: true,
        clearError: true,
        clearPendingResponse: true,
        suggestionsHidden: true,
      ),
    );

    try {
      final response = await _repository.sendMessage(
        process: state.process,
        userMessage: text,
        conversationHistory: state.messages,
        pageContext: state.pageContext,
      );

      final assistantText = response.content.trim();
      if (assistantText.isNotEmpty) {
        final updated = [
          ...history,
          AiChatMessage.assistant(
            assistantText,
            dataRows: response.dataRows,
            reportData: response.reportData,
            proposal: response.proposal,
          ),
        ];

        emit(
          state.copyWith(
            messages: updated,
            isSending: false,
            error: response.isSuccess ? null : response.errorMessage,
            pendingResponse: response.isSuccess && response.needsExecutorAction
                ? response
                : null,
            suggestionsHidden: false,
          ),
        );
        if (response.isSuccess) {
          add(LoadAiSuggestionsEvent());
        }
        return;
      }

      emit(
        state.copyWith(
          messages: history,
          isSending: false,
          error: response.errorMessage ?? 'AI request failed',
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          messages: history,
          isSending: false,
          error: e.toString(),
        ),
      );
    }
  }

  void _onClear(ClearAiChatEvent event, Emitter<AiChatState> emit) {
    emit(
      AiChatState(
        process: state.process,
        systemPromptId: state.systemPromptId,
        pageContext: state.pageContext,
      ),
    );
    add(LoadAiSuggestionsEvent());
  }

  Future<void> _onLoadSuggestions(
    LoadAiSuggestionsEvent event,
    Emitter<AiChatState> emit,
  ) async {
    if (state.process.isEmpty) return;

    emit(state.copyWith(suggestionsLoading: true));

    try {
      final suggestions = await _repository.fetchSuggestions(
        process: state.process,
        systemPromptId: state.systemPromptId,
      );

      emit(state.copyWith(suggestions: suggestions, suggestionsLoading: false));
    } catch (_) {
      emit(state.copyWith(suggestions: const [], suggestionsLoading: false));
    }
  }

  void _onHideSuggestions(
    HideAiSuggestionsEvent event,
    Emitter<AiChatState> emit,
  ) {
    emit(state.copyWith(suggestionsHidden: true));
  }

  void _onShowSuggestions(
    ShowAiSuggestionsEvent event,
    Emitter<AiChatState> emit,
  ) {
    emit(state.copyWith(suggestionsHidden: false));
  }

  Future<void> _onConfirmProposal(
    ConfirmAiProposalEvent event,
    Emitter<AiChatState> emit,
  ) async {
    await _handleProposalAction(
      emit: emit,
      messageId: event.messageId,
      busyStatus: AiProposalStatus.confirming,
      successStatus: AiProposalStatus.confirmed,
      failureStatus: AiProposalStatus.failed,
      call: (proposal, messageId) => _repository.confirmProposal(
        process: state.process,
        proposal: proposal,
        fallbackRequestId: messageId,
      ),
      defaultSuccessMessage: 'บันทึกรายการเรียบร้อยแล้ว',
      defaultFailureMessage: 'ไม่สามารถบันทึกรายการได้',
    );
  }

  Future<void> _onRejectProposal(
    RejectAiProposalEvent event,
    Emitter<AiChatState> emit,
  ) async {
    await _handleProposalAction(
      emit: emit,
      messageId: event.messageId,
      busyStatus: AiProposalStatus.rejecting,
      successStatus: AiProposalStatus.rejected,
      failureStatus: AiProposalStatus.failed,
      call: (proposal, messageId) => _repository.rejectProposal(
        process: state.process,
        proposal: proposal,
        fallbackRequestId: messageId,
      ),
      defaultSuccessMessage: 'ยกเลิกรายการเรียบร้อยแล้ว',
      defaultFailureMessage: 'ไม่สามารถยกเลิกรายการได้',
    );
  }

  Future<void> _handleProposalAction({
    required Emitter<AiChatState> emit,
    required String messageId,
    required AiProposalStatus busyStatus,
    required AiProposalStatus successStatus,
    required AiProposalStatus failureStatus,
    required Future<AiActionResult> Function(
      AiProposal proposal,
      String messageId,
    )
    call,
    required String defaultSuccessMessage,
    required String defaultFailureMessage,
  }) async {
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index < 0) return;

    final message = state.messages[index];
    final proposal = message.proposal;
    if (proposal == null || !proposal.canInteract) return;

    final busyIds = {...state.proposalBusyIds, messageId};
    final busyMessages = [...state.messages];
    busyMessages[index] = message.copyWith(
      proposal: proposal.copyWith(
        status: busyStatus,
        clearConfirmError: true,
        clearConfirmMessage: true,
      ),
    );

    emit(state.copyWith(messages: busyMessages, proposalBusyIds: busyIds));

    try {
      final result = await call(proposal, messageId);
      final success = result.success;
      final messageText =
          result.message ??
          (success ? defaultSuccessMessage : defaultFailureMessage);

      final doneMessages = [...state.messages];
      doneMessages[index] = message.copyWith(
        proposal: proposal.copyWith(
          status: success ? successStatus : failureStatus,
          confirmMessage: messageText,
          confirmError: success ? null : messageText,
        ),
      );

      final nextBusy = {...busyIds}..remove(messageId);
      emit(
        state.copyWith(
          messages: doneMessages,
          proposalBusyIds: nextBusy,
          error: success ? null : messageText,
        ),
      );
    } catch (e) {
      final nextBusy = {...busyIds}..remove(messageId);
      final failedMessages = [...state.messages];
      failedMessages[index] = message.copyWith(
        proposal: proposal.copyWith(
          status: failureStatus,
          confirmMessage: e.toString(),
          confirmError: e.toString(),
        ),
      );

      emit(
        state.copyWith(
          messages: failedMessages,
          proposalBusyIds: nextBusy,
          error: e.toString(),
        ),
      );
    }
  }

  void _onDismissPending(
    DismissPendingActionEvent event,
    Emitter<AiChatState> emit,
  ) {
    emit(state.copyWith(clearPendingResponse: true));
  }
}
