import 'package:bs_mobile/src/core/theme/app_color_palette.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Local storage service.
/// Tokens are stored in [FlutterSecureStorage]; other prefs use SharedPreferences.
class AppStorage {
  AppStorage._();

  static const _secure = FlutterSecureStorage();
  static const _keyToken = 'token';
  static const _keyRefreshToken = 'refreshToken';

  static Future<void> setNetwork(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('Network', value);
  }

  static Future<bool> getNetwork() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('Network') ?? false;
  }

  static Future<void> setToken(String value) async {
    await _secure.write(key: _keyToken, value: value);
  }

  static Future<String?> getToken() async {
    return _secure.read(key: _keyToken);
  }

  static Future<void> clearToken() async {
    await _secure.delete(key: _keyToken);
  }

  static Future<void> setRefreshToken(String value) async {
    await _secure.write(key: _keyRefreshToken, value: value);
  }

  static Future<String?> getRefreshToken() async {
    return _secure.read(key: _keyRefreshToken);
  }

  static Future<void> setLocationFromLogin(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locationFromLogin', value);
  }

  static Future<String?> getLocationFromLogin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('locationFromLogin');
  }

  static Future<void> setApi(String value) async {
    final prefs = await SharedPreferences.getInstance();
    final url = value.endsWith('/') ? value : '$value/';
    await prefs.setString('url', url);
  }

  static Future<String?> getApi() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('url');
  }

  static Future<void> setUsername(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', value);
  }

  static Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  static Future<void> setUserId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', value);
  }

  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_id');
  }

  static Future<void> setVersion(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('version', value);
  }

  static Future<String?> getVersion() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('version');
  }

  static const _keyDarkMode = 'dark_mode';
  static const _keyColorPalette = 'color_palette';

  static Future<void> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyDarkMode, value);
  }

  static Future<bool> getDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyDarkMode) ?? false;
  }

  static Future<void> setColorPalette(AppColorPalette palette) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyColorPalette, palette.storageKey);
  }

  static Future<AppColorPalette> getColorPalette() async {
    final prefs = await SharedPreferences.getInstance();
    return AppColorPaletteX.fromStorageKey(prefs.getString(_keyColorPalette));
  }

  static Future<String> getLocaleId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale_id') ?? 'th';
  }

  static Future<void> setLocaleId(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_id', value);
  }

  static Future<void> clearCacheData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove('username'),
      prefs.remove('user_id'),
      prefs.remove('locationFromLogin'),
      _secure.delete(key: _keyToken),
      _secure.delete(key: _keyRefreshToken),
    ]);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await _secure.deleteAll();
  }

  static Future<String?> getLocaleVersion(String localeId) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('locale_version_$localeId');
  }

  static Future<void> setLocaleVersion(String localeId, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('locale_version_$localeId', value);
  }

  static Future<void> clearLocaleVersion(String localeId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('locale_version_$localeId');
  }

  static const _keyFcmToken = 'fcm_token';

  static Future<void> setFcmToken(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyFcmToken, value);
  }

  static Future<String?> getFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyFcmToken);
  }

  static Future<void> clearFcmToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyFcmToken);
  }
}
