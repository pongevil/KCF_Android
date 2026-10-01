import 'package:bs_mobile/src/core/ai/models/ai_page_context.dart';
import 'package:bs_mobile/src/core/localization/locale_extension.dart';
import 'package:bs_mobile/src/core/theme/theme_extensions.dart';
import 'package:bs_mobile/src/features/ai/presentation/ai_action_coordinator.dart';
import 'package:bs_mobile/src/features/ai/presentation/bloc/ai_chat_bloc.dart';
import 'package:bs_mobile/src/core/ai/models/ai_chat_message.dart';
import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';
import 'package:bs_mobile/src/features/ai/presentation/widgets/ai_formatted_message.dart';
import 'package:bs_mobile/src/features/ai/presentation/widgets/ai_proposal_card.dart';
import 'package:bs_mobile/src/features/ai/presentation/widgets/ai_suggestion_chips.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_modal_bottom_sheet.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_text_field.dart';
import 'package:bs_mobile/src/shared/ui/widgets/app_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class AiChatSheet extends StatefulWidget {
  const AiChatSheet({
    super.key,
    required this.process,
    this.title,
    this.greeting,
    this.systemPromptId,
    this.pageContext,
  });

  final String process;
  final String? title;
  final String? greeting;
  final int? systemPromptId;
  final AiPageContext? pageContext;

  @override
  State<AiChatSheet> createState() => _AiChatSheetState();
}

class _AiChatSheetState extends State<AiChatSheet> {
  final _controller = TextEditingController();
  final _inputFocus = FocusNode();
  ScrollController? _scrollController;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onInputChanged);
    context.read<AiChatBloc>().add(
      OpenAiChatEvent(
        process: widget.process,
        greeting:
            widget.greeting ??
            context.tr(
              'mobile.ai_greeting',
              fallback: 'สวัสดีครับ มีอะไรให้ช่วยไหม?',
            ),
        systemPromptId: widget.systemPromptId,
        pageContext: widget.pageContext,
      ),
    );
  }

  @override
  void dispose() {
    _controller.removeListener(_onInputChanged);
    _controller.dispose();
    _inputFocus.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final scrollController = _scrollController;
      if (!mounted ||
          scrollController == null ||
          !scrollController.hasClients) {
        return;
      }
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  void _onInputChanged() {
    if (_controller.text.trim().isNotEmpty) {
      context.read<AiChatBloc>().add(HideAiSuggestionsEvent());
    }
  }

  void _sendSuggestion(String text) {
    context.read<AiChatBloc>().add(SendAiMessageEvent(text));
    _scrollToBottom();
  }

  void _send() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    _controller.clear();
    context.read<AiChatBloc>().add(SendAiMessageEvent(text));
    _scrollToBottom();
  }

  Future<void> _handlePendingAction(AiChatState state) async {
    final pending = state.pendingResponse;
    if (pending == null) return;

    await AiActionCoordinator.handle(context, pending);

    if (!mounted) return;
    context.read<AiChatBloc>().add(DismissPendingActionEvent());
  }

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.88,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scrollController) {
        _scrollController = scrollController;
        return Material(
          color: cs.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.outlineVariant,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                child: Row(
                  children: [
                    Icon(Icons.smart_toy_outlined, color: cs.primary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: AppText(
                        widget.title ??
                            context.tr(
                              'mobile.ai_assistant',
                              fallback: 'asdsd 1234',
                            ),
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: context.tr('mobile.clear', fallback: 'ล้าง'),
                      onPressed: () {
                        context.read<AiChatBloc>().add(ClearAiChatEvent());
                        context.read<AiChatBloc>().add(
                          OpenAiChatEvent(
                            process: widget.process,
                            greeting: widget.greeting,
                            systemPromptId: widget.systemPromptId,
                            pageContext: widget.pageContext,
                          ),
                        );
                      },
                      icon: Icon(
                        Icons.refresh_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: Icon(
                        Icons.close_rounded,
                        color: cs.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: cs.outlineVariant.withValues(alpha: 0.4),
              ),
              Expanded(
                child: BlocConsumer<AiChatBloc, AiChatState>(
                  listenWhen: (previous, current) =>
                      current.pendingResponse != null &&
                      previous.pendingResponse != current.pendingResponse,
                  listener: (context, state) {
                    _scrollToBottom();
                    if (state.pendingResponse != null) {
                      _handlePendingAction(state);
                    }
                  },
                  builder: (context, state) {
                    return ListView.builder(
                      controller: scrollController,
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      itemCount:
                          state.messages.length + (state.isSending ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.messages.length) {
                          return _TypingIndicator(color: cs.primary);
                        }

                        final message = state.messages[index];
                        return _MessageBubble(
                          message: message,
                          isProposalBusy: state.proposalBusyIds.contains(
                            message.id,
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                decoration: BoxDecoration(
                  color: cs.surface,
                  border: Border(
                    top: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    BlocBuilder<AiChatBloc, AiChatState>(
                      buildWhen: (previous, current) =>
                          previous.suggestions != current.suggestions ||
                          previous.suggestionsLoading !=
                              current.suggestionsLoading ||
                          previous.suggestionsHidden !=
                              current.suggestionsHidden ||
                          previous.isSending != current.isSending,
                      builder: (context, state) {
                        if (state.isSending) {
                          return const SizedBox.shrink();
                        }

                        return AiSuggestionChips(
                          suggestions: state.suggestions,
                          isLoading: state.suggestionsLoading,
                          isHidden: state.suggestionsHidden,
                          onSuggestionTap: _sendSuggestion,
                          onHide: () => context.read<AiChatBloc>().add(
                            HideAiSuggestionsEvent(),
                          ),
                          onShow: () => context.read<AiChatBloc>().add(
                            ShowAiSuggestionsEvent(),
                          ),
                        );
                      },
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _controller,
                            focusNode: _inputFocus,
                            hintText: context.tr(
                              'mobile.ai_input_hint',
                              fallback: 'พิมพ์คำถาม...',
                            ),
                            maxLines: 1,
                            textInputAction: TextInputAction.send,
                            onFieldSubmitted: (_) => _send(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BlocBuilder<AiChatBloc, AiChatState>(
                          builder: (context, state) {
                            return IconButton.filled(
                              onPressed: state.isSending ? null : _send,
                              icon: state.isSending
                                  ? SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: cs.onPrimary,
                                      ),
                                    )
                                  : const Icon(Icons.send_rounded),
                              style: IconButton.styleFrom(
                                backgroundColor: cs.primary,
                                foregroundColor: cs.onPrimary,
                                minimumSize: const Size(48, 48),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message, this.isProposalBusy = false});

  final AiChatMessage message;
  final bool isProposalBusy;

  @override
  Widget build(BuildContext context) {
    final cs = context.colorScheme;
    final isUser = message.role == AiChatRole.user;

    final hasProposal =
        !isUser &&
        message.proposal != null &&
        isCrudProposalAction(message.proposal!.action);

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(bottom: hasProposal ? 0 : 10),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.sizeOf(context).width * (isUser ? 0.78 : 0.92),
            ),
            decoration: BoxDecoration(
              color: isUser ? cs.primary : cs.surfaceContainerHighest,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(14),
                topRight: const Radius.circular(14),
                bottomLeft: Radius.circular(
                  isUser ? 14 : (hasProposal ? 4 : 4),
                ),
                bottomRight: Radius.circular(
                  isUser ? 4 : (hasProposal ? 4 : 14),
                ),
              ),
            ),
            child: isUser
                ? AppText(
                    message.content,
                    style: TextStyle(color: cs.onPrimary, height: 1.35),
                  )
                : AiFormattedMessage(
                    text: message.content,
                    dataRows: message.dataRows,
                    reportData: message.reportData,
                    textColor: cs.onSurface,
                  ),
          ),
          if (hasProposal)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.sizeOf(context).width * 0.92,
                ),
                child: AiProposalCard(
                  proposal: message.proposal!,
                  isBusy: isProposalBusy,
                  onConfirm: message.proposal!.canInteract && !isProposalBusy
                      ? () => context.read<AiChatBloc>().add(
                          ConfirmAiProposalEvent(message.id),
                        )
                      : null,
                  onReject: message.proposal!.canInteract && !isProposalBusy
                      ? () => context.read<AiChatBloc>().add(
                          RejectAiProposalEvent(message.id),
                        )
                      : null,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(strokeWidth: 2, color: color),
        ),
      ),
    );
  }
}

void showAiChatSheet(
  BuildContext context, {
  required String process,
  String? title,
  String? greeting,
  int? systemPromptId,
  AiPageContext? pageContext,
}) {
  showCustomModalBottomSheet<void>(
    context: context,
    builder: (_) => BlocProvider.value(
      value: context.read<AiChatBloc>(),
      child: AiChatSheet(
        process: process,
        title: title,
        greeting: greeting,
        systemPromptId: systemPromptId,
        pageContext: pageContext,
      ),
    ),
  );
}
