import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';

/// Tests server connectivity using the raw IP/host entered by the user and
/// persists the API gateway base URL on success only.
class ConfigUrlRepository {
  ConfigUrlRepository(this._client);

  final ApiClient _client;

  static const defaultHost = '10.10.60.45';
  static const defaultPort = 98;
  static const mobileApplicationPath = 'WM3_API_Mobile';

  static String normalizeServerHost(String value, {int? port}) {
    final raw = value.trim();
    if (raw.isEmpty) return '';

    final hasScheme = raw.startsWith('http://') || raw.startsWith('https://');
    final sanitized = hasScheme ? raw : 'http://$raw';

    final uri = Uri.tryParse(sanitized);
    if (uri == null || uri.host.isEmpty) {
      return '';
    }

    final scheme = uri.scheme.isEmpty ? 'http' : uri.scheme;
    final host = uri.host;
    final effectivePort = port ?? (uri.hasPort ? uri.port : null);
    if (effectivePort != null && (effectivePort < 1 || effectivePort > 65535)) {
      return '';
    }
    final base = effectivePort == null || effectivePort == 80
        ? '$scheme://$host'
        : '$scheme://$host:$effectivePort';
    return base;
  }

  static Uri buildTestConnectionUri(String host, int port) {
    final baseUrl = normalizeServerHost(host, port: port);
    if (baseUrl.isEmpty) {
      throw ArgumentError('A valid server host and port are required');
    }
    return Uri.parse(
      '$baseUrl/$mobileApplicationPath/api/ServerConnection/TestConnection',
    );
  }

  Future<ServerConnectionConfig> loadConfiguration() async {
    final storedUrl = await AppStorage.getApi();
    final uri = storedUrl == null ? null : Uri.tryParse(storedUrl);
    if (uri == null || uri.host.isEmpty) {
      return const ServerConnectionConfig(host: defaultHost, port: defaultPort);
    }
    return ServerConnectionConfig(
      host: uri.host,
      port: uri.hasPort ? uri.port : 80,
    );
  }

  Future<bool> testConnection(String host, int port) async {
    try {
      final normalizedUrl = normalizeServerHost(host, port: port);
      if (normalizedUrl.isEmpty) {
        return false;
      }

      final testUrl = buildTestConnectionUri(host, port).toString();
      final response = await _client.get(testUrl, useAuth: false);
      final statusCode = response.statusCode ?? 0;
      final isReachable =
          (statusCode >= 200 && statusCode < 300) ||
          statusCode == 401 ||
          statusCode == 403;
      if (isReachable) {
        await AppStorage.setApi(normalizedUrl);
        return true;
      }
      return false;
    } on AppException {
      return false;
    } catch (_) {
      return false;
    }
  }
}

class ServerConnectionConfig {
  const ServerConnectionConfig({required this.host, required this.port});

  final String host;
  final int port;

  String get baseUrl =>
      ConfigUrlRepository.normalizeServerHost(host, port: port);
}
