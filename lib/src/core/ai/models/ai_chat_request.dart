import 'package:bs_mobile/src/core/ai/models/ai_chat_message.dart';

class AiChatRequest {
  const AiChatRequest({
    required this.process,
    required this.userMessage,
    required this.conversationHistory,
    this.userId,
    this.userName,
  });

  final String process;
  final String userMessage;
  final List<AiChatMessage> conversationHistory;
  final String? userId;
  final String? userName;

  Map<String, dynamic> toJson() => {
    'process': process,
    'user_message': userMessage,
    if (userId != null && userId!.isNotEmpty) 'user_id': userId,
    if (userName != null && userName!.isNotEmpty) 'user_name': userName,
    'conversation_history': conversationHistory.map((m) => m.toJson()).toList(),
  };
}
