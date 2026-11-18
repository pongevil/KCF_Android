import 'package:bloc_test/bloc_test.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/models/goods_receive_models.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/bloc/goods_receive_bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/presentation/bloc/reprint_label_bloc.dart';
import 'package:bs_mobile/src/features/goods_receive_weight_scale/repository/goods_receive_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGoodsReceiveRepository extends Mock
    implements GoodsReceiveRepository {}

void main() {
  late MockGoodsReceiveRepository repository;
  const station = WeightScaleStation(
    lineId: 'L01',
    lineName: 'Line 1',
    scaleId: 'S01',
    scaleName: 'Scale 1',
    printerId: 'P01',
    printerName: 'Printer 1',
  );
  const setup = GoodsReceiveSetup(
    station: station,
    skus: [ReceiveSku(id: '1', code: 'FG001', name: 'Chicken')],
    packagings: [PackagingOption(id: 'PK5', name: '5 kg', capacityKg: 5)],
  );

  setUp(() => repository = MockGoodsReceiveRepository());

  blocTest<GoodsReceiveBloc, GoodsReceiveState>(
    'loads mapped station, SKU and packaging setup',
    build: () {
      when(
        () => repository.fetchSetup(deviceId: any(named: 'deviceId')),
      ).thenAnswer((_) async => setup);
      return GoodsReceiveBloc(repository);
    },
    act: (bloc) => bloc.add(const GoodsReceiveLoadRequested('tablet-01')),
    expect: () => const [GoodsReceiveLoading(), GoodsReceiveReady(setup)],
  );

  blocTest<GoodsReceiveBloc, GoodsReceiveState>(
    'rejects an unstable scale reading',
    build: () {
      when(
        () => repository.readWeight(
          scaleId: station.scaleId,
          scaleIp: any(named: 'scaleIp'),
          scalePort: any(named: 'scalePort'),
        ),
      ).thenAnswer(
        (_) async => WeightReading(
          weightKg: 5,
          readAt: DateTime(2026, 9, 21),
          isStable: false,
        ),
      );
      return GoodsReceiveBloc(repository);
    },
    act: (bloc) => bloc.add(
      const GoodsReceiveWeightRequested(
        setup,
        scaleIp: '10.60.61.62',
        scalePort: 4660,
      ),
    ),
    expect: () => const [
      GoodsReceiveWeightLoading(setup),
      GoodsReceiveWeightFailure(setup, 'Weight is not stable'),
    ],
  );

  blocTest<GoodsReceiveBloc, GoodsReceiveState>(
    'accepts a stable zero reading so the display can reset',
    setUp: () {
      when(
        () => repository.readWeight(
          scaleId: 'S01',
          scaleIp: '10.60.61.62',
          scalePort: 4660,
        ),
      ).thenAnswer(
        (_) async => WeightReading(
          weightKg: 0,
          readAt: DateTime(2026, 10, 30),
          isStable: true,
        ),
      );
    },
    build: () => GoodsReceiveBloc(repository),
    act: (bloc) => bloc.add(
      const GoodsReceiveWeightRequested(
        setup,
        scaleIp: '10.60.61.62',
        scalePort: 4660,
      ),
    ),
    expect: () => [
      const GoodsReceiveWeightLoading(setup),
      GoodsReceiveWeightReady(
        setup,
        WeightReading(
          weightKg: 0,
          readAt: DateTime(2026, 10, 30),
          isStable: true,
        ),
      ),
    ],
  );

  blocTest<GoodsReceiveBloc, GoodsReceiveState>(
    'emits a retryable weight failure when the scale connection fails',
    build: () {
      when(
        () => repository.readWeight(
          scaleId: station.scaleId,
          scaleIp: any(named: 'scaleIp'),
          scalePort: any(named: 'scalePort'),
        ),
      ).thenThrow(Exception('Scale unavailable'));
      return GoodsReceiveBloc(repository);
    },
    act: (bloc) => bloc.add(
      const GoodsReceiveWeightRequested(
        setup,
        scaleIp: '10.60.61.62',
        scalePort: 4660,
      ),
    ),
    expect: () => const [
      GoodsReceiveWeightLoading(setup),
      GoodsReceiveWeightFailure(setup, 'Exception: Scale unavailable'),
    ],
  );

  blocTest<GoodsReceiveBloc, GoodsReceiveState>(
    'closes the latest order for the tablet scale mapping',
    build: () {
      when(
        () => repository.closeLatestOrder(scaleMappingId: station.scaleId),
      ).thenAnswer((_) async => 'Order closed successfully');
      return GoodsReceiveBloc(repository);
    },
    act: (bloc) => bloc.add(const GoodsReceiveCloseRequested(setup)),
    expect: () => const [
      GoodsReceiveClosing(setup),
      GoodsReceiveCloseSuccess(setup, 'Order closed successfully'),
    ],
    verify: (_) {
      verify(
        () => repository.closeLatestOrder(scaleMappingId: station.scaleId),
      ).called(1);
    },
  );

  blocTest<ReprintLabelBloc, ReprintLabelState>(
    'requires at least one label before reprint',
    build: () => ReprintLabelBloc(repository),
    act: (bloc) => bloc.add(
      const ReprintLabelsRequested(
        [],
        printerIp: '10.60.10.135',
        printerToken: 'mapping-token',
      ),
    ),
    expect: () => const [
      ReprintLabelFailure('Please select at least one label'),
    ],
    verify: (_) => verifyNever(
      () => repository.reprintLabels(
        any(),
        printerIp: any(named: 'printerIp'),
        printerToken: any(named: 'printerToken'),
      ),
    ),
  );
}
