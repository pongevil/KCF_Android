import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/core/app_identity.dart';
import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/core/localization/locale_resources_response.dart';
import 'package:bs_mobile/src/core/localization/locale_strings_response.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Fetches and caches locale strings (JSON on disk).
/// Does not mutate [LocaleService] — the BLoC applies results at runtime.
class LocaleRepository {
  final ApiClient _client;

  /// Switch to `false` when the real localization API is ready.
  static const bool useMockLocale = false;

  LocaleRepository(this._client);

  Future<String> resolveLocaleId() async {
    final localeId = await AppStorage.getLocaleId();
    return localeId.isEmpty ? 'th' : localeId;
  }

  /// Fetches from API and overwrites disk cache. Caller must apply to
  /// [LocaleService].
  Future<LocaleStringsResponse> fetchAndCache() async {
    final localeId = await resolveLocaleId();
    final remote = await _fetchRemote(localeId);
    await _writeToDisk(localeId, remote);
    printDebug('Locale cached: $localeId (${remote.messages.length} keys)');
    return remote;
  }

  Future<LocaleStringsResponse?> readCache() async {
    final localeId = await resolveLocaleId();
    return _readFromDisk(localeId);
  }

  /// Fallback messages used when a key is missing from the active locale.
  Future<Map<String, String>> loadFallbackMessages() async {
    final fallback = await _loadMockAsset('th');
    return fallback.messages;
  }

  Future<LocaleStringsResponse> _fetchRemote(String localeId) async {
    if (useMockLocale) {
      return _loadMockAsset(localeId);
    }

    try {
      final response = await _client.post(
        'resource',
        data: {
          'platform': AppIdentity.platform,
          'application_license': AppIdentity.applicationLicense,
        },
      );

      return _parseResourcesResponse(
        Map<String, dynamic>.from(response.data as Map),
        localeId,
      );
    } catch (e, s) {
      printDebug('Locale API failed: $e');
      printDebug(s.toString());

      final cached = await _readFromDisk(localeId);
      if (cached != null) {
        return cached;
      }

      return _loadMockAsset(localeId);
    }
  }

  Future<LocaleStringsResponse> _loadMockAsset(String localeId) async {
    const assetPath = 'lib/src/global/mockdata/locale_resources_mock.json';
    final jsonString = await rootBundle.loadString(assetPath);
    return _parseResourcesResponse(
      jsonDecode(jsonString) as Map<String, dynamic>,
      localeId,
    );
  }

  LocaleStringsResponse _parseResourcesResponse(
    Map<String, dynamic> json,
    String localeId,
  ) {
    return LocaleResourcesResponse.fromJson(json).toLocaleStrings(localeId);
  }

  Future<File> _localeFile(String localeId) async {
    final dir = await getApplicationDocumentsDirectory();
    final i18nDir = Directory('${dir.path}/i18n');
    if (!await i18nDir.exists()) {
      await i18nDir.create(recursive: true);
    }
    return File('${i18nDir.path}/$localeId.json');
  }

  Future<void> _writeToDisk(
    String localeId,
    LocaleStringsResponse response,
  ) async {
    final file = await _localeFile(localeId);
    await file.writeAsString(response.toJsonString());
  }

  Future<LocaleStringsResponse?> _readFromDisk(String localeId) async {
    final file = await _localeFile(localeId);
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      return LocaleStringsResponse.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } catch (e) {
      printDebug('Failed to read locale cache: $e');
      return null;
    }
  }
}
