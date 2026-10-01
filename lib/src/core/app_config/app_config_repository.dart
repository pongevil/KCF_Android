import 'package:bs_mobile/src/core/app_config/app_config_response.dart';
import 'package:bs_mobile/src/core/app_identity.dart';
import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart' show rootBundle;
import 'package:path_provider/path_provider.dart';

/// Fetches and caches app config. Does not mutate [AppConfigService] —
/// the BLoC / coordinator applies the result to the runtime singleton.
class AppConfigRepository {
  final ApiClient _client;

  /// Switch to `false` when the real app config API is ready.
  static const bool useMockConfig = true;

  AppConfigRepository(this._client);

  Future<AppConfigResponse> fetchAndCache() async {
    final remote = await _fetchRemote();
    await _writeToDisk(remote);
    printDebug(
      'App config cached: decimal_places=${remote.quantity.decimalPlaces}, '
      'max_integer_digits=${remote.quantity.maxIntegerDigits}',
    );
    return remote;
  }

  Future<AppConfigResponse?> readCache() async {
    return _readFromDisk();
  }

  Future<AppConfigResponse> _fetchRemote() async {
    if (useMockConfig) {
      return _loadMockAsset();
    }

    try {
      final response = await _client.post(
        'config',
        data: {
          'platform': AppIdentity.platform,
          'application_license': AppIdentity.applicationLicense,
        },
      );
      return AppConfigResponse.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } catch (e, s) {
      printDebug('App config API failed: $e');
      printDebug(s.toString());

      final cached = await _readFromDisk();
      if (cached != null) {
        return cached;
      }

      return _loadMockAsset();
    }
  }

  Future<AppConfigResponse> _loadMockAsset() async {
    const assetPath = 'lib/src/global/mockdata/app_config_mock.json';
    final jsonString = await rootBundle.loadString(assetPath);
    return AppConfigResponse.fromJson(
      jsonDecode(jsonString) as Map<String, dynamic>,
    );
  }

  Future<File> _configFile() async {
    final dir = await getApplicationDocumentsDirectory();
    final configDir = Directory('${dir.path}/app_config');
    if (!await configDir.exists()) {
      await configDir.create(recursive: true);
    }
    return File('${configDir.path}/config.json');
  }

  Future<void> _writeToDisk(AppConfigResponse response) async {
    final file = await _configFile();
    await file.writeAsString(jsonEncode(response.toJson()));
  }

  Future<AppConfigResponse?> _readFromDisk() async {
    final file = await _configFile();
    if (!await file.exists()) {
      return null;
    }

    try {
      final content = await file.readAsString();
      return AppConfigResponse.fromJson(
        jsonDecode(content) as Map<String, dynamic>,
      );
    } catch (e) {
      printDebug('Failed to read app config cache: $e');
      return null;
    }
  }
}
