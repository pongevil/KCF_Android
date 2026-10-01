import 'dart:convert';
import 'dart:io';

import 'package:bs_mobile/src/core/helpers/debug_log_colors.dart';
import 'package:bs_mobile/src/core/network/api_error_mapper.dart';
import 'package:bs_mobile/src/core/network/api_error_notifier.dart';
import 'package:bs_mobile/src/core/network/app_exception.dart';
import 'package:bs_mobile/src/core/network/device_info_provider.dart';
import 'package:bs_mobile/src/core/network/interceptors/auth_interceptor.dart';
import 'package:bs_mobile/src/core/network/session_expired_handler.dart';
import 'package:bs_mobile/src/global/local/app_storage.dart';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';

/// HTTP client กลางของแอพ — ใช้ผ่าน Repository เท่านั้น (ห้าม import Dio ใน feature)
///
/// - Base URL จาก [AppStorage.getApi] (gateway)
/// - เมื่อ [isRunLocalhost] เป็น `true` API ทั่วไปไปที่ [_localhostBaseUrl]
///   แต่ path ใน [_gatewayOnlyPathSegments] ยังใช้ gateway เสมอ
/// - Auth header (Bearer JWT) อัตโนมัติเมื่อ [useAuth] เป็น `true`
/// - GET รองรับ [queryParameters] ที่ encode ด้วย [Uri.encodeComponent]
///
/// ดูตัวอย่างเพิ่มเติม: `docs/API_CLIENT.md`
class ApiClient {
  /// When true, non-gateway APIs use [_localhostBaseUrl]; paths in
  /// [_gatewayOnlyPathSegments] still use [AppStorage.getApi].
  /// Toggle via `--dart-define=USE_LOCAL_API=true`.
  static const bool isRunLocalhost = bool.fromEnvironment(
    'USE_LOCAL_API',
    defaultValue: true,
  );

  /// Android emulator → host machine. Real device / iOS: use LAN IP instead.
  static const String _localhostBaseUrl = 'http://10.0.2.2:5087/';

  /// Paths that always use gateway (never localhost), even when [isRunLocalhost].
  static const Set<String> _gatewayOnlyPathSegments = {
    'login',
    'logout',
    'refreshToken',
    'refresh',
    'menu',
    'CheckVersion',
  };

  final Dio _dio = Dio();
  final ApiErrorMapper _errorMapper;
  final ApiErrorNotifier? _errorNotifier;
  final DeviceInfoProvider _deviceInfoProvider;
  final SessionExpiredHandler? _sessionExpiredHandler;

  Future<void>? _configureFuture;
  bool _interceptorsConfigured = false;
  bool _httpClientConfigured = false;
  String _currentBaseUrl = '';

  ApiClient({
    ApiErrorMapper? errorMapper,
    ApiErrorNotifier? errorNotifier,
    DeviceInfoProvider? deviceInfoProvider,
    SessionExpiredHandler? sessionExpiredHandler,
  }) : _errorMapper = errorMapper ?? const ApiErrorMapper(),
       _errorNotifier = errorNotifier,
       _deviceInfoProvider = deviceInfoProvider ?? const DeviceInfoProvider(),
       _sessionExpiredHandler = sessionExpiredHandler {
    _configureFuture = _configureDio();
  }

  Future<void> _configureDio() async {
    final baseUrl = await _readGatewayBaseUrl();
    _currentBaseUrl = baseUrl;

    _dio
      ..options.baseUrl = baseUrl
      ..options.connectTimeout = const Duration(seconds: 50)
      ..options.receiveTimeout = const Duration(seconds: 30)
      ..options.responseType = ResponseType.json;

    if (!_interceptorsConfigured) {
      if (_sessionExpiredHandler != null) {
        _dio.interceptors.add(
          AuthInterceptor(
            dio: _dio,
            deviceInfoProvider: _deviceInfoProvider,
            sessionExpiredHandler: _sessionExpiredHandler,
          ),
        );
      }
      _dio.interceptors.add(
        LogInterceptor(
          request: true,
          requestHeader: true,
          requestBody: true,
          responseHeader: true,
          responseBody: true,
        ),
      );
      _interceptorsConfigured = true;
    }

    if (!_httpClientConfigured) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final client = HttpClient(
            context: SecurityContext(withTrustedRoots: false),
          );
          client.badCertificateCallback = (cert, host, port) => true;
          return client;
        },
      );
      _httpClientConfigured = true;
    }
  }

  Future<void> _ensureConfigured() async {
    _configureFuture ??= _configureDio();
    await _configureFuture;

    final latestBaseUrl = await _readGatewayBaseUrl();
    if (latestBaseUrl != _currentBaseUrl) {
      _currentBaseUrl = latestBaseUrl;
      _dio.options.baseUrl = latestBaseUrl;
    }
  }

  /// Gateway base URL จาก [AppStorage.getApi] (ลงท้ายด้วย `/`)
  static Future<String> readGatewayBaseUrl() async {
    final baseUrl = await AppStorage.getApi() ?? '';
    if (baseUrl.isEmpty) return '';
    return baseUrl.endsWith('/') ? baseUrl : '$baseUrl/';
  }

  Future<String> _readGatewayBaseUrl() => readGatewayBaseUrl();

  /// `true` ถ้า [path] เป็น endpoint ฝั่ง gateway (login/menu/…)
  static bool isGatewayOnlyPath(String path) {
    final pathOnly = path.split('?').first;
    final segments = pathOnly.split('/').where((segment) => segment.isNotEmpty);
    return segments.any(_gatewayOnlyPathSegments.contains);
  }

  Future<String> _baseUrlForPath(String path) async {
    if (isRunLocalhost && !isGatewayOnlyPath(path)) {
      return _localhostBaseUrl;
    }
    return _readGatewayBaseUrl();
  }

  /// Absolute URL ของ request — gateway vs localhost ตาม path + [isRunLocalhost]
  Future<String> _resolveRequestUrl(String path) async {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }
    final baseUrl = await _baseUrlForPath(path);
    final relative = path.startsWith('/') ? path.substring(1) : path;
    return '$baseUrl$relative';
  }

  Map<String, dynamic> decodeJwt(String token) =>
      AuthInterceptor.decodeJwt(token);

  Future<String> getHost() async {
    final url = await AppStorage.getApi() ?? '';
    return url.endsWith('/') ? url : '$url/';
  }

  Future<Options> _buildOptions({bool useAuth = true, int? timeoutSec}) async {
    final headers = <String, dynamic>{
      HttpHeaders.contentTypeHeader: 'application/json; charset=UTF-8',
      HttpHeaders.acceptHeader: '*/*',
      'X-Client-IP': await _deviceInfoProvider.getLocalIpAddress(),
      'X-Client-Device': await _deviceInfoProvider.getModelDevice(),
      'X-Client-Locale': await AppStorage.getLocaleId(),
      'X-Client-userId': await AppStorage.getUserId(),
      'X-Client-Platform': 'MOBILE',
      'X-Client-userName': await AppStorage.getUsername(),
    };

    if (useAuth) {
      final token = await AppStorage.getToken();
      if (token != null && token.isNotEmpty) {
        headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
      }
    }

    return Options(
      headers: headers,
      sendTimeout: Duration(seconds: timeoutSec ?? 50),
      receiveTimeout: Duration(seconds: timeoutSec ?? 30),
    );
  }

  void _maybeShowError(String msg, {required bool showAlert}) {
    if (showAlert && msg != 'Unauthorized') {
      _errorNotifier?.showError(msg);
    }
  }

  /// สร้าง query string โดย encode key/value ด้วย [Uri.encodeComponent]
  ///
  /// ค่า `null` จะถูกข้าม ค่าอื่นแปลงเป็น string ก่อน encode
  static String encodeQueryString(Map<String, dynamic> queryParameters) {
    return queryParameters.entries
        .where((entry) => entry.value != null)
        .map(
          (entry) =>
              '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value.toString())}',
        )
        .join('&');
  }

  String _appendQueryParameters(
    String path,
    Map<String, dynamic>? queryParameters,
  ) {
    if (queryParameters == null || queryParameters.isEmpty) return path;

    final query = encodeQueryString(queryParameters);
    if (query.isEmpty) return path;

    final separator = path.contains('?') ? '&' : '?';
    return '$path$separator$query';
  }

  /// ส่ง HTTP GET ไปยัง [path] (relative ต่อ base URL)
  ///
  /// [queryParameters] — map ของ query string; key/value จะถูก encode ด้วย
  /// [Uri.encodeComponent] ก่อนต่อท้าย path (ไม่ต้องใส่ `?` ใน path เอง)
  ///
  /// ```dart
  /// // แทน: get('menu?platform=MOBILE')
  /// await apiClient.get(
  ///   'menu',
  ///   queryParameters: {'platform': 'MOBILE', 'page': 1},
  /// );
  ///
  /// // ค่าที่มีอักขระพิเศษจะถูก encode อัตโนมัติ
  /// await apiClient.get(
  ///   'search',
  ///   queryParameters: {'q': 'กรุงเทพ & ปริมณฑล'},
  /// );
  /// ```
  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool useAuth = true,
    bool showAlert = true,
    int? timeoutSec,
  }) async {
    try {
      await _ensureConfigured();
      final requestPath = _appendQueryParameters(path, queryParameters);
      final url = await _resolveRequestUrl(requestPath);
      DebugLogColors.request(
        'GET $url${isRunLocalhost && !isGatewayOnlyPath(path) ? ' [local]' : ' [gateway]'}',
      );
      final opts = await _buildOptions(
        useAuth: useAuth,
        timeoutSec: timeoutSec,
      );
      final response = await _dio.get(url, options: opts);

      if (response.statusCode == 200) {
        await AppStorage.setNetwork(true);
        return response;
      }
      throw AppException(
        _errorMapper.fromStatusCode(response.statusCode, response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (e, s) {
      print('Debuged DioException in GET $path: $e');
      print('Stack trace: $s');
      DebugLogColors.error(e.toString());
      final msg = await _errorMapper.fromDioException(e);
      _maybeShowError(msg, showAlert: showAlert);
      throw AppException(msg, statusCode: e.response?.statusCode);
    }
  }

  Future<Response> post(
    String path, {
    Object? data,
    bool useAuth = true,
    bool showAlert = true,
    int? timeoutSec,
  }) async {
    try {
      await _ensureConfigured();
      final url = await _resolveRequestUrl(path);
      DebugLogColors.request(
        'POST $url ${json.encode(data)}${isRunLocalhost && !isGatewayOnlyPath(path) ? ' [local]' : ' [gateway]'}',
      );
      final opts = await _buildOptions(
        useAuth: useAuth,
        timeoutSec: timeoutSec,
      );
      DebugLogColors.request('options: ${opts.headers}');
      final response = await _dio.post(url, data: data, options: opts);
      DebugLogColors.response(
        'Response for POST $path: ${json.encode(response.data)}',
      );
      if (response.statusCode == 200) {
        await AppStorage.setNetwork(true);
        return response;
      }
      if (showAlert && response.data != null) {
        _errorNotifier?.showError(
          response.data['message']?.toString() ?? 'Error',
        );
      }
      throw AppException(
        _errorMapper.fromStatusCode(response.statusCode, response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      DebugLogColors.error(e.toString());
      final msg = await _errorMapper.fromDioException(e);
      if (showAlert) _errorNotifier?.showError(msg);
      throw AppException(msg, statusCode: e.response?.statusCode);
    }
  }

  Future<Response> put(
    String path, {
    Map<String, dynamic>? data,
    bool useAuth = true,
  }) async {
    await _ensureConfigured();
    final url = await _resolveRequestUrl(path);
    final opts = await _buildOptions(useAuth: useAuth);
    return _dio.put(url, data: data, options: opts);
  }

  Future<Response> delete(
    String path, {
    Map<String, dynamic>? data,
    bool useAuth = true,
  }) async {
    try {
      await _ensureConfigured();
      final url = await _resolveRequestUrl(path);
      final opts = await _buildOptions(useAuth: useAuth);
      final response = await _dio.delete(url, data: data, options: opts);
      if (response.statusCode == 200) return response;
      throw AppException(
        _errorMapper.fromStatusCode(response.statusCode, response.data),
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      final msg = await _errorMapper.fromDioException(e);
      throw AppException(msg, statusCode: e.response?.statusCode);
    }
  }

  Future<void> download(
    String path,
    String savePath, {
    bool useAuth = true,
    Map<String, dynamic>? headers,
    ProgressCallback? onReceiveProgress,
    Duration? sendTimeout,
    Duration? receiveTimeout,
  }) async {
    await _ensureConfigured();
    final url = await _resolveRequestUrl(path);
    final opts = await _buildOptions(useAuth: useAuth);
    opts
      ..headers = {...?opts.headers, ...?headers}
      ..sendTimeout = sendTimeout ?? const Duration(seconds: 50)
      ..receiveTimeout = receiveTimeout ?? const Duration(seconds: 30);

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: onReceiveProgress,
      options: opts,
    );
  }

  Future<String> getLocalIpAddress() => _deviceInfoProvider.getLocalIpAddress();

  Future<String> getModelDevice() => _deviceInfoProvider.getModelDevice();
}
