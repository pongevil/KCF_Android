part of 'ai_chat_bloc.dart';

@immutable
final class AiChatState {
  const AiChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
    this.process = AiConfig.defaultMobileHomeProcess,
    this.pendingResponse,
    this.proposalBusyIds = const {},
    this.systemPromptId,
    this.pageContext,
    this.suggestions = const [],
    this.suggestionsLoading = false,
    this.suggestionsHidden = false,
  });

  final List<AiChatMessage> messages;
  final bool isSending;
  final String? error;
  final String process;
  final AiChatResponse? pendingResponse;
  final Set<String> proposalBusyIds;
  final int? systemPromptId;
  final AiPageContext? pageContext;
  final List<String> suggestions;
  final bool suggestionsLoading;
  final bool suggestionsHidden;

  AiChatState copyWith({
    List<AiChatMessage>? messages,
    bool? isSending,
    String? error,
    bool clearError = false,
    String? process,
    AiChatResponse? pendingResponse,
    bool clearPendingResponse = false,
    Set<String>? proposalBusyIds,
    int? systemPromptId,
    AiPageContext? pageContext,
    List<String>? suggestions,
    bool? suggestionsLoading,
    bool? suggestionsHidden,
  }) {
    return AiChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: clearError ? null : (error ?? this.error),
      process: process ?? this.process,
      pendingResponse: clearPendingResponse
          ? null
          : (pendingResponse ?? this.pendingResponse),
      proposalBusyIds: proposalBusyIds ?? this.proposalBusyIds,
      systemPromptId: systemPromptId ?? this.systemPromptId,
      pageContext: pageContext ?? this.pageContext,
      suggestions: suggestions ?? this.suggestions,
      suggestionsLoading: suggestionsLoading ?? this.suggestionsLoading,
      suggestionsHidden: suggestionsHidden ?? this.suggestionsHidden,
    );
  }
}
