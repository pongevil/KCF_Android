import 'package:bs_mobile/src/features/device_settings/models/device_connection_settings.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DeviceSettingsRepository {
  DeviceSettingsRepository({
    FlutterSecureStorage? secureStorage,
    String? defaultPrintApiToken,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage(),
       _defaultPrintApiToken =
           defaultPrintApiToken ??
           const String.fromEnvironment('PRINT_API_TOKEN');

  static const _printApiTokenKey = 'device_settings.print_api.token';
  static const _packingLineKey = 'device_settings.packing_line';

  final FlutterSecureStorage _secureStorage;
  final String _defaultPrintApiToken;

  Future<String> loadPrintApiToken() async {
    final storedToken = await _secureStorage.read(key: _printApiTokenKey);
    if (storedToken != null && storedToken.trim().isNotEmpty) {
      return storedToken;
    }
    final defaultToken = _defaultPrintApiToken.trim();
    if (defaultToken.isNotEmpty) {
      await _secureStorage.write(key: _printApiTokenKey, value: defaultToken);
    }
    return defaultToken;
  }

  Future<void> savePrintApiToken(String token) async {
    final normalized = token.trim();
    if (normalized.isEmpty) {
      await _secureStorage.delete(key: _printApiTokenKey);
      return;
    }
    await _secureStorage.write(key: _printApiTokenKey, value: normalized);
  }

  Future<DeviceConnectionSettings> load() async {
    final preferences = await SharedPreferences.getInstance();
    return DeviceConnectionSettings(
      packingLine: preferences.getString(_packingLineKey) ?? '',
    );
  }

  Future<void> save(DeviceConnectionSettings settings) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(_packingLineKey, settings.packingLine.trim());
  }
}
