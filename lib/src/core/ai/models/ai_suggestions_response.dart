import 'package:bs_mobile/index.dart';

class AiSuggestionsResponse {
  const AiSuggestionsResponse({
    required this.success,
    this.suggestions = const [],
    this.errorMessage,
  });

  final bool success;
  final List<String> suggestions;
  final String? errorMessage;

  factory AiSuggestionsResponse.fromDynamic(dynamic data) {
    if (data is! Map) {
      return const AiSuggestionsResponse(success: false);
    }

    final map = Map<String, dynamic>.from(data);
    final payload = map['data'] is Map
        ? Map<String, dynamic>.from(map['data'] as Map)
        : map;

    final raw = payload['suggestions'] ?? payload['Suggestions'];
    final suggestions = Parse.parseStringList(raw);

    final success =
        Parse.parseBool(payload['success'] ?? payload['Success']) ?? true;

    return AiSuggestionsResponse(
      success: success,
      suggestions: suggestions,
      errorMessage: Parse.parseString(
        payload['error_message'] ?? payload['errorMessage'],
      ),
    );
  }
}
