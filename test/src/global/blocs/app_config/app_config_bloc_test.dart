import 'package:bs_mobile/src/core/app_config/app_config_repository.dart';
import 'package:bs_mobile/src/core/app_config/app_config_response.dart';
import 'package:bs_mobile/src/core/app_config/app_config_service.dart';
import 'package:bs_mobile/src/core/app_config/quantity_config.dart';
import 'package:bs_mobile/src/global/blocs/app_config/app_config_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockAppConfigRepository extends Mock implements AppConfigRepository {}

void main() {
  late _MockAppConfigRepository repository;

  setUp(() {
    repository = _MockAppConfigRepository();
    AppConfigService.instance.applyQuantity(QuantityConfig.defaults);
  });

  blocTest<AppConfigBloc, AppConfigState>(
    'applies quantity from fetchAndCache on LoadAppConfigEvent',
    build: () {
      when(() => repository.fetchAndCache()).thenAnswer(
        (_) async => const AppConfigResponse(
          quantity: QuantityConfig(decimalPlaces: 4, maxIntegerDigits: 8),
        ),
      );
      return AppConfigBloc(repository);
    },
    act: (bloc) => bloc.add(LoadAppConfigEvent()),
    expect: () => [isA<AppConfigLoading>(), isA<AppConfigLoaded>()],
    verify: (_) {
      expect(AppConfigService.instance.quantity.decimalPlaces, 4);
      verify(() => repository.fetchAndCache()).called(1);
    },
  );

  blocTest<AppConfigBloc, AppConfigState>(
    'applies quantity from cache on LoadAppConfigFromCacheEvent',
    build: () {
      when(() => repository.readCache()).thenAnswer(
        (_) async => const AppConfigResponse(
          quantity: QuantityConfig(decimalPlaces: 2, maxIntegerDigits: 6),
        ),
      );
      return AppConfigBloc(repository);
    },
    act: (bloc) => bloc.add(LoadAppConfigFromCacheEvent()),
    expect: () => [isA<AppConfigLoaded>()],
    verify: (_) {
      expect(AppConfigService.instance.quantity.decimalPlaces, 2);
      verify(() => repository.readCache()).called(1);
    },
  );
}
