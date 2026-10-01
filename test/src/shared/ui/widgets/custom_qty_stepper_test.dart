import 'package:bs_mobile/src/core/app_config/app_config_service.dart';
import 'package:bs_mobile/src/core/app_config/quantity_config.dart';
import 'package:bs_mobile/src/shared/ui/widgets/custom_qty_stepper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late TextEditingController controller;

  setUp(() {
    controller = TextEditingController();
    AppConfigService.instance.applyQuantity(QuantityConfig.defaults);
  });

  tearDown(() {
    controller.dispose();
    AppConfigService.instance.applyQuantity(QuantityConfig.defaults);
  });

  Widget buildStepper({
    bool useQuantityConfig = true,
    bool allowDecimal = false,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: CustomQtyStepper(
          controller: controller,
          useQuantityConfig: useQuantityConfig,
          allowDecimal: allowDecimal,
          onDecrement: () {},
          onIncrement: () {},
        ),
      ),
    );
  }

  group('CustomQtyStepper', () {
    testWidgets('allows decimal input from QuantityConfig by default', (
      tester,
    ) async {
      AppConfigService.instance.applyQuantity(
        const QuantityConfig(decimalPlaces: 3, maxIntegerDigits: 10),
      );

      await tester.pumpWidget(buildStepper());
      await tester.enterText(find.byType(TextField), '12.345');
      await tester.pump();

      expect(controller.text, '12.345');
    });

    testWidgets('allows input within decimalPlaces limit', (tester) async {
      AppConfigService.instance.applyQuantity(
        const QuantityConfig(decimalPlaces: 2, maxIntegerDigits: 10),
      );

      await tester.pumpWidget(buildStepper());
      await tester.enterText(find.byType(TextField), '1.23');
      await tester.pump();

      expect(controller.text, '1.23');
    });

    testWidgets(
      'useQuantityConfig false with allowDecimal false is digits only',
      (tester) async {
        await tester.pumpWidget(
          buildStepper(useQuantityConfig: false, allowDecimal: false),
        );
        await tester.enterText(find.byType(TextField), '12a.3');
        await tester.pump();

        expect(controller.text, '123');
      },
    );

    testWidgets('integer-only config accepts whole numbers', (tester) async {
      AppConfigService.instance.applyQuantity(
        const QuantityConfig(decimalPlaces: 0, maxIntegerDigits: 10),
      );

      await tester.pumpWidget(buildStepper());
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();

      expect(controller.text, '123');
    });
  });
}
