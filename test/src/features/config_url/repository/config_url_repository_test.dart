import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/features/config_url/repository/config_url_repository.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockApiClient extends Mock implements ApiClient {}

void main() {
  late MockApiClient client;
  late ConfigUrlRepository repository;

  const testHost = '10.10.60.45';
  const testPort = 98;
  const testBaseUrl = 'http://10.10.60.45:98/';
  const testConnectionUrl =
      'http://10.10.60.45:98/WM3_API_Mobile/api/ServerConnection/TestConnection';

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    client = MockApiClient();
    repository = ConfigUrlRepository(client);
  });

  group('ConfigUrlRepository', () {
    test('loads 10.10.60.45 and port 98 when no config is stored', () async {
      final config = await repository.loadConfiguration();

      expect(config.host, ConfigUrlRepository.defaultHost);
      expect(config.port, ConfigUrlRepository.defaultPort);
      expect(config.baseUrl, 'http://10.10.60.45:98');
    });

    test('loads a previously saved host and port', () async {
      await AppStorage.setApi('http://192.168.1.20:8080');

      final config = await repository.loadConfiguration();

      expect(config.host, '192.168.1.20');
      expect(config.port, 8080);
    });

    test('tests WM3_API_Mobile and saves root server URL on success', () async {
      when(() => client.get(testConnectionUrl, useAuth: false)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: testConnectionUrl),
          statusCode: 200,
        ),
      );

      final result = await repository.testConnection(testHost, testPort);

      expect(result, isTrue);
      expect(await AppStorage.getApi(), testBaseUrl);
      verify(() => client.get(testConnectionUrl, useAuth: false)).called(1);
    });

    test('does not save URL when status is not reachable', () async {
      when(() => client.get(testConnectionUrl, useAuth: false)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: testConnectionUrl),
          statusCode: 500,
        ),
      );

      final result = await repository.testConnection(testHost, testPort);

      expect(result, isFalse);
      expect(await AppStorage.getApi(), isNull);
    });

    test('accepts an authentication response as reachable', () async {
      when(() => client.get(testConnectionUrl, useAuth: false)).thenAnswer(
        (_) async => Response(
          requestOptions: RequestOptions(path: testConnectionUrl),
          statusCode: 403,
        ),
      );

      final result = await repository.testConnection(testHost, testPort);

      expect(result, isTrue);
      expect(await AppStorage.getApi(), testBaseUrl);
    });

    test('returns false when AppException is thrown', () async {
      when(
        () => client.get(testConnectionUrl, useAuth: false),
      ).thenThrow(const AppException('timeout', statusCode: null));

      final result = await repository.testConnection(testHost, testPort);

      expect(result, isFalse);
      expect(await AppStorage.getApi(), isNull);
    });

    test('rejects ports outside the valid range', () async {
      expect(await repository.testConnection(testHost, 70000), isFalse);
      expect(await AppStorage.getApi(), isNull);
      verifyNever(() => client.get(any(), useAuth: false));
    });

    test('normalizes port 80 without an explicit port suffix', () {
      expect(
        ConfigUrlRepository.normalizeServerHost(testHost, port: 80),
        'http://10.10.60.45',
      );
    });
  });
}
