import 'package:bs_mobile/src/core/theme/app_color_palette.dart';
import 'package:bs_mobile/src/core/theme/theme_config.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/bloc/config_rfid_bloc.dart';
import 'package:bs_mobile/src/features/config_rfid/presentation/pages/config_rfid_page.dart';
import 'package:bs_mobile/src/features/config_rfid/service/rfid_device_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRfidDeviceService extends Mock implements RfidDeviceService {}

void main() {
  late _MockRfidDeviceService service;

  Widget buildTestApp() {
    return MaterialApp(
      theme: ThemeConfig.theme(
        palette: AppColorPalette.freshGreen,
        brightness: Brightness.light,
      ),
      home: BlocProvider(
        create: (_) =>
            ConfigRfidBloc(service)..add(const ConfigRfidPowerLoadRequested()),
        child: const ConfigRfidPage(),
      ),
    );
  }

  setUp(() {
    service = _MockRfidDeviceService();
    when(() => service.getPower()).thenAnswer((_) async => null);
    when(() => service.setPower(any())).thenAnswer((_) async => true);
  });

  Future<void> pumpUntilLoaded(WidgetTester tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
  }

  group('ConfigRfidPage', () {
    testWidgets('displays title and power range after loading', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpUntilLoaded(tester);

      expect(find.text('Config RFID'), findsOneWidget);
      expect(find.text('พลังงาน RFID ปัจจุบัน'), findsOneWidget);
      expect(find.text('ช่วงที่รองรับ: 1 – 33'), findsOneWidget);
      expect(find.text('-'), findsOneWidget);
      expect(find.text('ตั้งค่าพลังงาน'), findsOneWidget);
      expect(find.text('รีเฟรชค่าปัจจุบัน'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('opens power picker bottom sheet', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpUntilLoaded(tester);

      await tester.tap(find.text('ตั้งค่าพลังงาน'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('เลือกระดับพลังงาน RFID'), findsOneWidget);
      expect(find.text('บันทึก'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });

    testWidgets('refresh button keeps page usable after reload', (
      tester,
    ) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.windows;
      await pumpUntilLoaded(tester);

      await tester.tap(find.text('รีเฟรชค่าปัจจุบัน'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('รีเฟรชค่าปัจจุบัน'), findsOneWidget);
      expect(find.text('ตั้งค่าพลังงาน'), findsOneWidget);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
