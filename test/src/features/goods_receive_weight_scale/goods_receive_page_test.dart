import 'package:bs_mobile/src/app/di/injection.dart';
import 'package:bs_mobile/src/core/localization/locale_service.dart';
import 'package:bs_mobile/src/features/device_settings/models/device_connection_settings.dart';
import 'package:bs_mobile/src/features/device_settings/repository/device_settings_repository.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/bloc/goods_receive_bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/pages/goods_receive_page.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockDeviceSettingsRepository extends Mock
    implements DeviceSettingsRepository {}

class MockGoodsReceiveRepository extends Mock
    implements GoodsReceiveRepository {}

void main() {
  late MockDeviceSettingsRepository deviceRepository;
  late MockGoodsReceiveRepository goodsRepository;

  const mapping = WeightScaleMapping(
    id: 'S01',
    packingLine: 'Line 1',
    scaleName: 'Scale 1',
    scaleIp: '10.60.61.62',
    scalePort: 4660,
    printerName: 'Printer 1',
    printerIp: '10.60.10.135',
    printerToken: 'mapping-token',
    isActive: true,
  );
  const setup = GoodsReceiveSetup(
    station: WeightScaleStation(
      lineId: 'L01',
      lineName: 'Line 1',
      scaleId: 'S01',
      scaleName: 'Scale 1',
      printerId: 'P01',
      printerName: 'Printer 1',
      scaleIp: '10.60.61.62',
    ),
    skus: [ReceiveSku(id: '1', code: 'FG001', name: 'Chicken')],
    packagings: [PackagingOption(id: 'PK5', name: '5 kg', capacityKg: 5)],
  );

  setUp(() async {
    await getIt.reset();
    deviceRepository = MockDeviceSettingsRepository();
    goodsRepository = MockGoodsReceiveRepository();
    getIt.registerSingleton<DeviceSettingsRepository>(deviceRepository);
    getIt.registerSingleton<GoodsReceiveRepository>(goodsRepository);

    when(
      () => deviceRepository.load(),
    ).thenAnswer((_) async => const DeviceConnectionSettings());
    when(
      () => goodsRepository.fetchSetup(deviceId: ''),
    ).thenAnswer((_) async => setup);
    when(
      () => goodsRepository.readWeight(
        scaleId: 'S01',
        scaleIp: mapping.scaleIp,
        scalePort: mapping.scalePort,
      ),
    ).thenAnswer(
      (_) async => WeightReading(
        weightKg: 12.5,
        readAt: DateTime(2026, 10, 30),
        isStable: true,
      ),
    );
    LocaleService.instance.setMessages({
      'goods_receive.line': 'L',
      'goods_receive.scale': 'S',
      'goods_receive.printer': 'P',
      'goods_receive.close_order': 'Close',
      'goods_receive.confirm_print': 'Print',
    });
  });

  tearDown(() async {
    LocaleService.instance.clear();
    await getIt.reset();
  });

  testWidgets('uses scanner-only Cart ID input without a soft keyboard', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GoodsReceiveBloc(goodsRepository),
        child: const MaterialApp(home: GoodsReceivePage()),
      ),
    );
    await tester.pumpAndSettle();

    final cartField = tester.widget<EditableText>(find.byType(EditableText));
    expect(cartField.keyboardType, TextInputType.none);
    expect(cartField.focusNode.hasFocus, isTrue);

    await tester.enterText(find.byType(EditableText), 'CART-001');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pump(const Duration(milliseconds: 100));

    expect(cartField.controller.text, 'CART-001');
  });

  testWidgets('starts reading the configured scale when the page opens', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GoodsReceiveBloc(goodsRepository),
        child: const MaterialApp(home: GoodsReceivePage()),
      ),
    );
    await tester.pumpAndSettle();

    verify(
      () => goodsRepository.readWeight(
        scaleId: 'S01',
        scaleIp: mapping.scaleIp,
        scalePort: mapping.scalePort,
      ),
    ).called(1);
    expect(find.text('12.50 kg'), findsOneWidget);
    expect(find.text('อ่านน้ำหนักจากเครื่องชั่ง'), findsNothing);
  });

  testWidgets('keeps reading and displays a changed scale weight', (
    tester,
  ) async {
    var readCount = 0;
    when(
      () => goodsRepository.readWeight(
        scaleId: 'S01',
        scaleIp: mapping.scaleIp,
        scalePort: mapping.scalePort,
      ),
    ).thenAnswer((_) async {
      readCount++;
      return WeightReading(
        weightKg: readCount == 1 ? 12.5 : 13.75,
        readAt: DateTime(2026, 10, 30, 0, 0, readCount),
        isStable: true,
      );
    });
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GoodsReceiveBloc(goodsRepository),
        child: const MaterialApp(home: GoodsReceivePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('12.50 kg'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(readCount, 2);
    expect(find.text('13.75 kg'), findsOneWidget);
  });

  testWidgets('displays zero after the item is removed from the scale', (
    tester,
  ) async {
    var readCount = 0;
    when(
      () => goodsRepository.readWeight(
        scaleId: 'S01',
        scaleIp: mapping.scaleIp,
        scalePort: mapping.scalePort,
      ),
    ).thenAnswer((_) async {
      readCount++;
      return WeightReading(
        weightKg: readCount == 1 ? 0.2 : 0,
        readAt: DateTime(2026, 10, 30, 0, 0, readCount),
        isStable: true,
      );
    });
    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GoodsReceiveBloc(goodsRepository),
        child: const MaterialApp(home: GoodsReceivePage()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('0.20 kg'), findsOneWidget);

    await tester.pump(const Duration(seconds: 1));
    await tester.pump();

    expect(readCount, 2);
    expect(find.text('0.00 kg'), findsOneWidget);
  });

  testWidgets('scrolls the SKU grid beyond the first four items', (
    tester,
  ) async {
    final manySkus = List.generate(
      8,
      (index) => ReceiveSku(
        id: '${index + 1}',
        code: 'FG${index + 1}',
        name: 'SKU ${index + 1}',
      ),
    );
    when(() => goodsRepository.fetchSetup(deviceId: '')).thenAnswer(
      (_) async => GoodsReceiveSetup(
        station: setup.station,
        skus: manySkus,
        packagings: setup.packagings,
      ),
    );

    await tester.binding.setSurfaceSize(const Size(1200, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BlocProvider(
        create: (_) => GoodsReceiveBloc(goodsRepository),
        child: const MaterialApp(home: GoodsReceivePage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('SKU 8'), findsNothing);
    await tester.drag(
      find.byKey(const Key('goods-receive-sku-grid')),
      const Offset(0, -500),
    );
    await tester.pumpAndSettle();

    expect(find.text('SKU 8'), findsOneWidget);
  });
}
