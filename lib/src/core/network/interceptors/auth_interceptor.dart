import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/core/network/device_info_provider.dart';
import 'package:bs_mobile/src/core/network/session_expired_handler.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:dio/dio.dart';

class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required Dio dio,
    required DeviceInfoProvider deviceInfoProvider,
    required SessionExpiredHandler sessionExpiredHandler,
  }) : _dio = dio,
       _deviceInfoProvider = deviceInfoProvider,
       _sessionExpiredHandler = sessionExpiredHandler;

  final Dio _dio;
  final DeviceInfoProvider _deviceInfoProvider;
  final SessionExpiredHandler _sessionExpiredHandler;

  static bool _isRefreshing = false;

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final isUnauthorized = err.response?.statusCode == 401;
    final skippedRefresh = request.extra['skipAuthRefresh'] == true;
    final isRetried = request.extra['isRetried'] == true;
    final shouldTryRefresh = isUnauthorized && !skippedRefresh && !isRetried;

    if (!shouldTryRefresh) {
      return handler.next(err);
    }

    final refreshed = await _refreshAccessToken();
    if (!refreshed) {
      await _sessionExpiredHandler.handle();
      return handler.reject(err);
    }

    final latestToken = await AppStorage.getToken();
    if (latestToken == null || latestToken.isEmpty) {
      return handler.next(err);
    }

    request.headers[HttpHeaders.authorizationHeader] = 'Bearer $latestToken';
    request.extra['isRetried'] = true;

    try {
      final response = await _dio.fetch(request);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }

  Future<bool> _refreshAccessToken() async {
    if (_isRefreshing) return false;

    final refreshToken = await AppStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;

    _isRefreshing = true;
    try {
      // Always hit gateway — never localhost, even when USE_LOCAL_API=true
      final gatewayBase = await AppStorage.getApi() ?? '';
      final normalized = gatewayBase.isEmpty
          ? ''
          : (gatewayBase.endsWith('/') ? gatewayBase : '$gatewayBase/');
      final refreshUrl = '${normalized}refresh';
      final response = await _dio.post(
        refreshUrl,
        data: {'refresh_token': refreshToken},
        options: Options(
          headers: {
            HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
            HttpHeaders.acceptHeader: '*/*',
            'X-Client-IP': await _deviceInfoProvider.getLocalIpAddress(),
            'X-Client-Device': await _deviceInfoProvider.getModelDevice(),
          },
          extra: {'skipAuthRefresh': true},
        ),
      );

      if (response.statusCode != 200 || response.data is! Map) return false;

      final data = Map<String, dynamic>.from(response.data as Map);
      final payload = data['data'];
      if (payload is! Map) return false;

      final tokenData = Map<String, dynamic>.from(payload);
      final newAccessToken = tokenData['access_token']?.toString() ?? '';
      final newRefreshToken = tokenData['refresh_token']?.toString() ?? '';

      if (newAccessToken.isEmpty) return false;

      await AppStorage.setToken(newAccessToken);
      if (newRefreshToken.isNotEmpty) {
        await AppStorage.setRefreshToken(newRefreshToken);
      }
      return true;
    } catch (_) {
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  static Map<String, dynamic> decodeJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return {};
      final payload = base64Url.normalize(parts[1]);
      final decoded = utf8.decode(base64Url.decode(payload));
      return jsonDecode(decoded) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
