import 'package:bs_mobile/src/features/device_settings/models/device_connection_settings.dart';
import 'package:bs_mobile/src/features/device_settings/repository/device_settings_repository.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockFlutterSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('load returns empty packingLine by default', () async {
    final settings = await DeviceSettingsRepository().load();

    expect(settings.packingLine, '');
  });

  test('save persists packingLine', () async {
    final repository = DeviceSettingsRepository();
    const expected = DeviceConnectionSettings(packingLine: 'Line 1');

    await repository.save(expected);
    final actual = await repository.load();

    expect(actual.packingLine, expected.packingLine);
  });

  test('savePrintApiToken and loadPrintApiToken work', () async {
    final secureStorage = MockFlutterSecureStorage();
    final repository = DeviceSettingsRepository(secureStorage: secureStorage);
    const token = 'test-token-123';
    when(
      () => secureStorage.write(
        key: 'device_settings.print_api.token',
        value: token,
      ),
    ).thenAnswer((_) async {});
    when(
      () => secureStorage.read(key: 'device_settings.print_api.token'),
    ).thenAnswer((_) async => token);

    await repository.savePrintApiToken(token);
    final loaded = await repository.loadPrintApiToken();

    expect(loaded, token);
    verify(
      () => secureStorage.write(
        key: 'device_settings.print_api.token',
        value: token,
      ),
    ).called(1);
  });
}
