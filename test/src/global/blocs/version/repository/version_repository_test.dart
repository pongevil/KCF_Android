import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/global/blocs/version/repository/version_repository.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('builds the APK download URL from the configured server', () async {
    await AppStorage.setApi('http://172.16.250.102');
    final repository = VersionRepository(ApiClient());

    final url = await repository.buildDownloadUrl();

    expect(
      url,
      'http://172.16.250.102/WM3_API_Mobile/api/AppVersion/downloadApp',
    );
  });

  test(
    'does not duplicate a trailing slash in the configured server',
    () async {
      await AppStorage.setApi('http://server.example/');
      final repository = VersionRepository(ApiClient());

      final url = await repository.buildDownloadUrl();

      expect(
        url,
        'http://server.example/WM3_API_Mobile/api/AppVersion/downloadApp',
      );
    },
  );
}
