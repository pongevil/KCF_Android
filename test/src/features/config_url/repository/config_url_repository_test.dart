import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ConfigUrlRepository repository;

  const testUrl = 'https://api.example.com/';

  setUpAll(() {
    registerFallbackValue(RequestOptions(path: '/'));
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockApiClient();
    repository = ConfigUrlRepository(client);
  });

  group('ConfigUrlRepository.testConnection', () {
    test('returns true and saves API url when status is 200', () async {
      when(() => client.get('${testUrl}test', useAuth: false)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '${testUrl}test'),
          statusCode: 200,
        ),
      );

      final result = await repository.testConnection(testUrl);

      expect(result, isTrue);
      expect(await AppStorage.getApi(), testUrl);
      verify(() => client.get('${testUrl}test', useAuth: false)).called(1);
    });

    test(
      'returns false and does not save url when status is not 200',
      () async {
        when(() => client.get('${testUrl}test', useAuth: false)).thenAnswer(
          (_) async => Response(
            requestOptions: RequestOptions(path: '${testUrl}test'),
            statusCode: 500,
          ),
        );

        final result = await repository.testConnection(testUrl);

        expect(result, isFalse);
        expect(await AppStorage.getApi(), isNull);
      },
    );

    test('returns false when AppException is thrown', () async {
      when(
        () => client.get('${testUrl}test', useAuth: false),
      ).thenThrow(const AppException('timeout', statusCode: null));

      final result = await repository.testConnection(testUrl);

      expect(result, isFalse);
      expect(await AppStorage.getApi(), isNull);
    });

    test('returns false when unexpected error is thrown', () async {
      when(
        () => client.get('${testUrl}test', useAuth: false),
      ).thenThrow(Exception('unexpected'));

      final result = await repository.testConnection(testUrl);

      expect(result, isFalse);
      expect(await AppStorage.getApi(), isNull);
    });

    test('normalizes API url without trailing slash before saving', () async {
      const urlWithoutSlash = 'https://api.example.com';

      when(
        () => client.get('${urlWithoutSlash}test', useAuth: false),
      ).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: '${urlWithoutSlash}test'),
          statusCode: 200,
        ),
      );

      final result = await repository.testConnection(urlWithoutSlash);

      expect(result, isTrue);
      expect(await AppStorage.getApi(), '$urlWithoutSlash/');
    });
  });
}
