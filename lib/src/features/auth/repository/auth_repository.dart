import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/features/auth/models/auth_model.dart';

/// Handles auth API calls. Token refresh on 401 is owned by [AuthInterceptor].
class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<AuthLoginResponse> login(AuthLoginRequest request) async {
    try {
      final response = await _client.post(
        'login',
        data: request.toJson(),
        useAuth: false,
      );
      final model = AuthLoginResponse.fromJson(response.data);
      printDebug("Login response: ${response.data}");

      if (model.data.accessToken.isNotEmpty) {
        await AppStorage.setToken(model.data.accessToken);
        await AppStorage.setRefreshToken(model.data.refreshToken);
        var decodedToken = _client.decodeJwt(model.data.accessToken);

        await AppStorage.setUsername(
          decodedToken['FirstName'] + ' ' + decodedToken['LastName'],
        );
        await AppStorage.setUserId(decodedToken['UserId'] ?? '');
        await AppStorage.setLocaleId(decodedToken['LocaleId'] ?? '');
      }

      return model;
    } catch (e) {
      return AuthLoginResponse(
        messageCode: 'ERROR',
        messageText: e.toString(),
        data: Data(accessToken: '', refreshToken: ''),
      );
    }
  }

  Future<AuthLoginResponse> logout() async {
    try {
      final res = await _client.post(
        'logout',
        data: {'refresh_token': await AppStorage.getRefreshToken()},
      );
      AuthLoginResponse model = AuthLoginResponse.fromJson(res.data);
      if (model.messageCode == '0') {
        await AppStorage.clearCacheData();
      }
      return model;
    } catch (_) {
      return AuthLoginResponse(
        messageCode: 'ERROR',
        messageText: 'Logout failed',
        data: Data(accessToken: '', refreshToken: ''),
      );
    }
  }
}
