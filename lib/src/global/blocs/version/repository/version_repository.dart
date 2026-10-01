import 'dart:io';

import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/global/models/api_base_response.dart';
import 'package:bs_mobile/src/shared/to_display_show.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path_provider/path_provider.dart' as path_provider;
import 'package:permission_handler/permission_handler.dart';

class VersionDownloadPermissions {
  final bool storageGranted;
  final bool installGranted;
  final bool manageExternalGranted;

  const VersionDownloadPermissions({
    required this.storageGranted,
    required this.installGranted,
    required this.manageExternalGranted,
  });

  bool get canDownload => storageGranted || manageExternalGranted;
}

class VersionRepository {
  final ApiClient _apiClient;

  VersionRepository(this._apiClient);

  /// Checks app version when a refresh token (session) exists.
  /// Returns [ApiBaseResponse] with messageCode `1` and text `Login` if unauthenticated.
  Future<ApiBaseResponse> fetchVersionStatus() async {
    final refreshToken = await AppStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return ApiBaseResponse(messageCode: 1, messageText: 'Login');
    }

    final packageInfo = await PackageInfo.fromPlatform();
    final result = await _apiClient.get(
      '/Mobile/AppVersion/CheckVersion?version=${packageInfo.version}',
    );
    return ApiBaseResponse.fromJson(result.data);
  }

  Future<VersionDownloadPermissions> requestDownloadPermissions() async {
    final storage = await Permission.storage.request();
    final install = await Permission.requestInstallPackages.request();
    final manageExternal = await Permission.manageExternalStorage.request();
    return VersionDownloadPermissions(
      storageGranted: storage.isGranted,
      installGranted: install.isGranted,
      manageExternalGranted: manageExternal.isGranted,
    );
  }

  Future<Directory?> resolveDownloadsDirectory() async {
    if (Platform.isAndroid) {
      final dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) await dir.create(recursive: true);
      return dir;
    }
    return path_provider.getDownloadsDirectory();
  }

  Future<String> buildDownloadUrl() async {
    final configHost = await AppStorage.getApi();
    return configHost.toString().endsWith('/')
        ? '${configHost}Mobile/Appversion/DownloadApp'
        : '$configHost/Mobile/Appversion/DownloadApp';
  }

  String buildApkFileName() {
    final versionDate = ToDisplayShow.toFileNameDate(DateTime.now());
    return 'AppUpdated$versionDate.apk';
  }

  Future<void> downloadApk({
    required String url,
    required String savePath,
    required void Function(int progress) onProgress,
  }) async {
    var lastShownProgress = -1;
    await _apiClient.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          final progress = ((received / total) * 100).toInt();
          if (progress >= lastShownProgress + 10 || progress == 100) {
            onProgress(progress);
            lastShownProgress = progress;
          }
        }
      },
      headers: {'Accept': 'application/vnd.android.package-archive'},
      receiveTimeout: const Duration(minutes: 10),
      sendTimeout: const Duration(minutes: 1),
    );
  }

  String extractDownloadErrorMessage(Object error) {
    if (error is AppException) {
      return error.message;
    }
    return error.toString().isEmpty ? 'Unknown error' : error.toString();
  }
}
