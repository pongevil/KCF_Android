import 'package:bs_mobile/src/core/ai/models/ai_proposal.dart';

enum AiChatRole {
  user,
  assistant,
  system;

  String get apiValue => name;

  static AiChatRole fromApi(String? value) {
    switch (value?.toLowerCase()) {
      case 'assistant':
        return AiChatRole.assistant;
      case 'system':
        return AiChatRole.system;
      default:
        return AiChatRole.user;
    }
  }
}

class AiChatMessage {
  const AiChatMessage({
    required this.id,
    required this.role,
    required this.content,
    this.createdAt,
    this.dataRows = const [],
    this.reportData,
    this.proposal,
  });

  final String id;
  final AiChatRole role;
  final String content;
  final DateTime? createdAt;
  final List<Map<String, dynamic>> dataRows;
  final Map<String, dynamic>? reportData;
  final AiProposal? proposal;

  factory AiChatMessage.user(String content, {DateTime? createdAt}) {
    return AiChatMessage(
      id: _newId(),
      role: AiChatRole.user,
      content: content,
      createdAt: createdAt ?? DateTime.now(),
    );
  }

  factory AiChatMessage.assistant(
    String content, {
    DateTime? createdAt,
    List<Map<String, dynamic>> dataRows = const [],
    Map<String, dynamic>? reportData,
    AiProposal? proposal,
  }) {
    return AiChatMessage(
      id: _newId(),
      role: AiChatRole.assistant,
      content: content,
      createdAt: createdAt ?? DateTime.now(),
      dataRows: dataRows,
      reportData: reportData,
      proposal: proposal,
    );
  }

  AiChatMessage copyWith({AiProposal? proposal}) {
    return AiChatMessage(
      id: id,
      role: role,
      content: content,
      createdAt: createdAt,
      dataRows: dataRows,
      reportData: reportData,
      proposal: proposal ?? this.proposal,
    );
  }

  static String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  Map<String, dynamic> toJson() => {'role': role.apiValue, 'content': content};
}
