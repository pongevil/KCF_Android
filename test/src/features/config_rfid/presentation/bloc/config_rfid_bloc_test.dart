import 'package:bs_mobile/src/features/config_rfid/presentation/bloc/config_rfid_bloc.dart';
import 'package:bs_mobile/src/features/config_rfid/service/rfid_device_service.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRfidDeviceService extends Mock implements RfidDeviceService {}

void main() {
  late _MockRfidDeviceService service;

  setUp(() {
    service = _MockRfidDeviceService();
  });

  group('ConfigRfidBloc', () {
    blocTest<ConfigRfidBloc, ConfigRfidState>(
      'loads current power',
      build: () {
        when(() => service.getPower()).thenAnswer((_) async => 20);
        return ConfigRfidBloc(service);
      },
      act: (bloc) => bloc.add(const ConfigRfidPowerLoadRequested()),
      expect: () => [
        isA<ConfigRfidState>().having((s) => s.isLoading, 'loading', true),
        isA<ConfigRfidState>()
            .having((s) => s.isLoading, 'loading', false)
            .having((s) => s.currentPower, 'power', 20),
      ],
    );

    blocTest<ConfigRfidBloc, ConfigRfidState>(
      'sets power and updates state',
      build: () {
        when(() => service.setPower(15)).thenAnswer((_) async => true);
        return ConfigRfidBloc(service);
      },
      seed: () => const ConfigRfidState(isLoading: false, currentPower: 10),
      act: (bloc) => bloc.add(const ConfigRfidPowerSetRequested(15)),
      expect: () => [
        isA<ConfigRfidState>().having((s) => s.isSetting, 'setting', true),
        isA<ConfigRfidState>()
            .having((s) => s.isSetting, 'setting', false)
            .having((s) => s.currentPower, 'power', 15)
            .having((s) => s.statusIsError, 'error', false),
      ],
    );
  });
}
