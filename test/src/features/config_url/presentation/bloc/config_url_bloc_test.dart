import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bs_mobile/src/features/config_url/presentation/bloc/config_url_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockConfigUrlRepository extends Mock implements ConfigUrlRepository {}

void main() {
  late MockConfigUrlRepository repository;

  const testHost = '10.10.60.45';
  const testPort = 98;

  setUp(() {
    repository = MockConfigUrlRepository();
  });

  group('ConfigUrlBloc', () {
    blocTest<ConfigUrlBloc, ConfigUrlState>(
      'emits [Loading, Success] when connection succeeds',
      build: () {
        when(
          () => repository.testConnection(any(), any()),
        ).thenAnswer((_) async => true);
        return ConfigUrlBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const ConnectionTestRequested(testHost, testPort)),
      expect: () => const [ConfigUrlLoading(), ConfigUrlSuccess()],
      verify: (_) {
        verify(() => repository.testConnection(testHost, testPort)).called(1);
      },
    );

    blocTest<ConfigUrlBloc, ConfigUrlState>(
      'emits [Loading, Failure] when connection fails',
      build: () {
        when(
          () => repository.testConnection(any(), any()),
        ).thenAnswer((_) async => false);
        return ConfigUrlBloc(repository);
      },
      act: (bloc) =>
          bloc.add(const ConnectionTestRequested(testHost, testPort)),
      expect: () => const [ConfigUrlLoading(), ConfigUrlFailure()],
    );
  });
}
