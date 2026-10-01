import 'package:bs_mobile/src/core/app_config/quantity_config.dart';
import 'package:bs_mobile/src/core/helpers/quantity_formatter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const config = QuantityConfig(decimalPlaces: 3, maxIntegerDigits: 10);

  group('QuantityFormatter', () {
    test('formatDisplay uses decimal places', () {
      expect(QuantityFormatter.formatDisplay(12.3, config: config), '12.300');
    });

    test('formatDisplay returns fallback for null', () {
      expect(QuantityFormatter.formatDisplay(null, config: config), '-');
    });

    test('parse returns double or fallback', () {
      expect(QuantityFormatter.parse('1.5'), 1.5);
      expect(QuantityFormatter.parse('', fallback: 9), 9);
    });

    test('roundForApi rounds to configured decimals', () {
      expect(QuantityFormatter.roundForApi(1.23456, config: config), 1.235);
    });
  });
}
