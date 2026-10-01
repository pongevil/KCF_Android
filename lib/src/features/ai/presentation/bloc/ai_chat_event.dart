part of 'ai_chat_bloc.dart';

@immutable
sealed class AiChatEvent extends Equatable {
  const AiChatEvent();

  @override
  List<Object?> get props => [];
}

final class OpenAiChatEvent extends AiChatEvent {
  OpenAiChatEvent({
    required this.process,
    this.greeting,
    this.systemPromptId,
    this.pageContext,
  });

  final String process;
  final String? greeting;
  final int? systemPromptId;
  final AiPageContext? pageContext;
}

final class SendAiMessageEvent extends AiChatEvent {
  SendAiMessageEvent(this.text);

  final String text;
}

final class ClearAiChatEvent extends AiChatEvent {}

final class ConfirmAiProposalEvent extends AiChatEvent {
  ConfirmAiProposalEvent(this.messageId);

  final String messageId;
}

final class RejectAiProposalEvent extends AiChatEvent {
  RejectAiProposalEvent(this.messageId);

  final String messageId;
}

final class DismissPendingActionEvent extends AiChatEvent {}

final class LoadAiSuggestionsEvent extends AiChatEvent {}

final class HideAiSuggestionsEvent extends AiChatEvent {}

final class ShowAiSuggestionsEvent extends AiChatEvent {}
