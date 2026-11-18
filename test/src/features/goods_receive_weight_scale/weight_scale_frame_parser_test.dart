import 'package:bs_mobile/src/features/goods_receive_weight_scale/service/weight_scale_tcp_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WeightScaleFrameParser', () {
    test('parses a stable kilogram frame', () {
      final reading = WeightScaleFrameParser.tryParse('ST,GS,+  12.340 kg');

      expect(reading, isNotNull);
      expect(reading!.weightKg, closeTo(12.34, 0.0001));
      expect(reading.isStable, isTrue);
    });

    test('rejects an unstable frame', () {
      final reading = WeightScaleFrameParser.tryParse('US,GS,+  12.340 kg');

      expect(reading, isNull);
    });

    test('converts grams to kilograms', () {
      final reading = WeightScaleFrameParser.tryParse('S 12340 g');

      expect(reading, isNotNull);
      expect(reading!.weightKg, closeTo(12.34, 0.0001));
    });

    test('accepts a numeric frame when scale transmits stable values only', () {
      final reading = WeightScaleFrameParser.tryParse('8.75 kg');

      expect(reading, isNotNull);
      expect(reading!.weightKg, closeTo(8.75, 0.0001));
    });
  });
}
