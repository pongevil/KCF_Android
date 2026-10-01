/// Per-page hidden constraints appended to AI user messages (not shown in chat UI).
class AiPageContext {
  const AiPageContext({this.condition});

  /// Developer-defined scope, e.g. "กรองเฉพาะ order_type = 'BLIND RECEIPT' เท่านั้น".
  final String? condition;

  bool get hasCondition => condition != null && condition!.trim().isNotEmpty;

  /// Appends hidden page constraint to [message] for API calls only.
  String augmentUserMessage(String message) {
    if (!hasCondition) return message;
    return '$message\n\n[ข้อจำกัดหน้านี้: ${condition!.trim()}]';
  }
}
