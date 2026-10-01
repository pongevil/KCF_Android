import 'package:bs_mobile/src/core/app_config/quantity_config.dart';

class AppConfigResponse {
  final QuantityConfig quantity;
  final String? messageCode;
  final String? messageText;

  const AppConfigResponse({
    required this.quantity,
    this.messageCode,
    this.messageText,
  });

  factory AppConfigResponse.fromJson(Map<String, dynamic> json) {
    final quantityJson = json['quantity'];
    return AppConfigResponse(
      messageCode: json['message_code']?.toString(),
      messageText: json['message_text']?.toString(),
      quantity: QuantityConfig.fromJson(
        quantityJson is Map ? Map<String, dynamic>.from(quantityJson) : null,
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    if (messageCode != null) 'message_code': messageCode,
    if (messageText != null) 'message_text': messageText,
    'quantity': quantity.toJson(),
  };
}
