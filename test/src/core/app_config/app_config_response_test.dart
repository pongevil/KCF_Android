import 'package:bs_mobile/src/core/app_config/app_config_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parses the flat GetDecimal production response', () {
    final response = AppConfigResponse.fromJson({
      'message_code': '0',
      'is_success': true,
      'decimal_places': 2,
      'max_integer_digits': 8,
    });

    expect(response.quantity.decimalPlaces, 2);
    expect(response.quantity.maxIntegerDigits, 8);
  });
}
