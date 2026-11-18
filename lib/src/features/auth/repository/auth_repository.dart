import 'package:bs_mobile/src/core/app_identity.dart';
import 'package:bs_mobile/src/core/network/api_client.dart';
import 'package:bs_mobile/src/core/network/api_endpoints.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:bs_mobile/src/features/auth/models/auth_model.dart';

/// Handles auth API calls. Token refresh on 401 is owned by [AuthInterceptor].
class AuthRepository {
  final ApiClient _client;
  AuthRepository(this._client);

  Future<AuthLoginResponse> login(AuthLoginRequest request) async {
    try {
      final response = await _client.post(
        ApiEndpoints.securityLogin,
        data: request.toJson(),
        useAuth: false,
      );
      final model = AuthLoginResponse.fromJson(response.data);
      if (model.messageCode == '0') {
        if (model.data.accessToken.isNotEmpty) {
          await AppStorage.setToken(model.data.accessToken);
          await AppStorage.setRefreshToken(model.data.refreshToken);
          var decodedToken = _client.decodeJwt(model.data.accessToken);

          await AppStorage.setUsername(
            '${decodedToken['FirstName']} ${decodedToken['LastName']}',
          );
          await AppStorage.setUserId(decodedToken['UserId'] ?? '');
          await AppStorage.setLocaleId(decodedToken['LocaleId'] ?? '');
        } else {
          // Production WM3 keeps the session server-side and returns no JWT.
          await AppStorage.setToken('legacy-session');
          await AppStorage.setUsername(request.username);
          await AppStorage.setUserId(request.username);
          await AppStorage.setLocaleId('1033');
        }
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
      final userId = await AppStorage.getUserId() ?? '';
      try {
        await _client.post(
          ApiEndpoints.mobileSessionLogout,
          data: {'user_id': userId, 'app_id': AppIdentity.applicationId},
          useAuth: false,
        );
      } catch (_) {
        // Keep compatibility while older WM3_API_Mobile deployments are
        // being upgraded. The security logout is still attempted below.
      }
      final res = await _client.post(
        ApiEndpoints.securityLogout,
        data: {
          'refresh_token': await AppStorage.getRefreshToken(),
          'username': userId,
          'user_id': userId,
          'app_id': AppIdentity.applicationId,
          'platform': AppIdentity.platform,
        },
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
