import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';

/// Tests gateway reachability and persists the API base URL on success only.
class ConfigUrlRepository {
  ConfigUrlRepository(this._client);

  final ApiClient _client;

  Future<bool> testConnection(String url) async {
    try {
      final response = await _client.get('${url}test', useAuth: false);
      if (response.statusCode == 200) {
        await AppStorage.setApi(url);
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
