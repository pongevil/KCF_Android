import 'dart:convert';

/// Flattened lookup map stored on disk after API resources are mapped.
class LocaleStringsResponse {
  final String localeId;
  final Map<String, String> messages;

  const LocaleStringsResponse({required this.localeId, required this.messages});

  factory LocaleStringsResponse.fromJson(Map<String, dynamic> json) {
    final rawMessages = json['messages'];
    final messages = <String, String>{};

    if (rawMessages is Map) {
      rawMessages.forEach((key, value) {
        if (key != null && value != null) {
          messages[key.toString()] = value.toString();
        }
      });
    }

    return LocaleStringsResponse(
      localeId: json['locale_id']?.toString() ?? '',
      messages: messages,
    );
  }

  Map<String, dynamic> toJson() => {
    'locale_id': localeId,
    'messages': messages,
  };

  String toJsonString() => jsonEncode(toJson());
}
