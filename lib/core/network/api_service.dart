import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sales_medical_app_mobile/core/network/api_http_exception.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_gate.dart';
import 'package:sales_medical_app_mobile/core/network/force_update_info.dart';
import 'package:sales_medical_app_mobile/core/utils/app_version.dart';

class ApiService {
  /// Single API host for auth, master data, and ERP routes.
  static const String baseUrl = 'https://dktapi1.cloudiax.com';

  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(minutes: 3),
        receiveTimeout: const Duration(minutes: 3),
        headers: {'Content-Type': 'application/json', 'Accept': '*/*'},
        responseType: ResponseType.json,
      ),
    );

    _initializeDio();
  }

  late final Dio _dio;
  static const String _tokenKey = 'auth_token';
  static const String _appVersionHeader = 'X-App-Version';

  /// Fired once when the backend returns 401 on an authenticated request, so
  /// the app can silently log the user out and route back to login.
  VoidCallback? _onUnauthorized;
  bool _isHandling401 = false;
  bool _isHandling426 = false;

  void setOnUnauthorized(VoidCallback? callback) {
    _onUnauthorized = callback;
  }

  /// Re-arm 401 handling (call after the user logs in again).
  void resetUnauthorizedHandling() {
    _isHandling401 = false;
  }

  static bool _isAuthPath(RequestOptions options) {
    final path = options.uri.path.toLowerCase();
    return path.contains('/api/auth/login') ||
        path.contains('/api/auth/logout');
  }

  /// GET `/api/auth/client-version` must not send `X-App-Version`.
  static bool _isClientVersionPath(RequestOptions options) {
    final path = options.uri.path.toLowerCase();
    return path.contains('/api/auth/client-version');
  }

  static bool _isClientVersionError(DioException error) {
    final status = error.response?.statusCode ?? 0;
    if (status == 426) return true;
    final data = error.response?.data;
    if (data is Map) {
      final code = data['error']?.toString() ?? '';
      return code.startsWith('CLIENT_VERSION_');
    }
    return false;
  }

  void _handleUnauthorized(RequestOptions options) {
    if (_isAuthPath(options) || _isHandling401) return;
    _isHandling401 = true;
    _onUnauthorized?.call();
  }

  Future<void> _handleClientVersionOutdated(DioException error) async {
    if (_isHandling426) return;
    _isHandling426 = true;
    try {
      await clearToken();
    } catch (_) {}
    final info = ForceUpdateInfo.fromResponseData(
      error.response?.data,
      fallbackMessage: _errorMessageFromResponseData(error.response?.data),
    );
    ForceUpdateGate.show(info);
  }

  void _initializeDio() {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          if (_isClientVersionPath(options)) {
            options.headers.remove(_appVersionHeader);
          } else {
            options.headers[_appVersionHeader] =
                await AppVersion.getApiVersion();
          }
          final token = await _getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) async {
          if (_isClientVersionError(error)) {
            await _handleClientVersionOutdated(error);
          } else if (error.response?.statusCode == 401) {
            _handleUnauthorized(error.requestOptions);
          }
          return handler.next(error);
        },
      ),
    );

    // Add CORS handling interceptor for web
    if (kIsWeb) {
      _dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            // Add CORS headers for web requests
            options.headers['Access-Control-Allow-Origin'] = '*';
            options.headers['Access-Control-Allow-Methods'] =
                'GET, POST, PUT, DELETE, OPTIONS';
            options.headers['Access-Control-Allow-Headers'] =
                'Origin, Content-Type, Accept, Authorization, X-Requested-With, X-App-Version';

            // For web, ensure we're using the right content type
            options.headers['Content-Type'] = 'application/json';
            return handler.next(options);
          },
        ),
      );
    }

    // Add logging in debug mode (errors: ApiService logs structured lines in _logError).
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          requestHeader: true,
          responseHeader: false,
          error: false,
          logPrint: (object) {
            if (kDebugMode) {
              debugPrint('$object');
            }
          },
        ),
      );
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  /// GET `/api/Auth/client-version` — no auth; interceptor omits `X-App-Version`.
  Future<Map<String, dynamic>?> getClientVersionPolicy() async {
    try {
      final response = await _dio.get<dynamic>('/api/Auth/client-version');
      if (response.statusCode != 200) return null;
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      if (data is Map) return Map<String, dynamic>.from(data);
      return null;
    } catch (_) {
      // Soft-fail: do not block login if the policy endpoint is unreachable.
      return null;
    }
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.post<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _logError('POST $path', e);
      throw _handleError(e);
    }
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.get<T>(
        path,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _logError('GET $path', e);
      throw _handleError(e);
    }
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.put<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _logError('PUT $path', e);
      throw _handleError(e);
    }
  }

  Future<Response<T>> patch<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.patch<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _logError('PATCH $path', e);
      throw _handleError(e);
    }
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    try {
      final response = await _dio.delete<T>(
        path,
        data: data,
        queryParameters: queryParameters,
        options: options,
      );
      return response;
    } on DioException catch (e) {
      _logError('DELETE $path', e);
      throw _handleError(e);
    }
  }

  /// Logs failed requests to the debug console (single structured block per failure).
  void _logError(String method, DioException e) {
    if (!kDebugMode) return;

    final uri = e.requestOptions.uri;
    debugPrint('┌─ ApiService $method failed');
    debugPrint('│ type: ${e.type}');
    debugPrint('│ message: ${e.message}');
    debugPrint('│ uri: $uri');
    if (e.requestOptions.queryParameters.isNotEmpty) {
      debugPrint('│ query: ${e.requestOptions.queryParameters}');
    }
    final res = e.response;
    if (res != null) {
      final status = res.statusCode ?? 0;
      final parsed = _errorMessageFromResponseData(res.data);
      debugPrint('│ status: $status');
      debugPrint('│ response: ${res.data}');
      debugPrint('│ throws: ApiHttpException($status, "$parsed")');
    } else {
      debugPrint('│ throws: ${e.type} (no response body)');
    }
    if (e.type != DioExceptionType.badResponse) {
      final lines = e.stackTrace.toString().split('\n').take(5).join('\n│ ');
      debugPrint('│ stack (trimmed):\n│ $lines');
    }
    debugPrint('└─');
  }

  String _errorMessageFromResponseData(dynamic responseData) {
    if (responseData is Map<String, dynamic>) {
      // Prefer `message` when present: ASP.NET problem details often put the
      // real explanation there while `error` is only a short code (e.g. BadRequest).
      final detail = responseData['message'];
      if (detail is String && detail.trim().isNotEmpty) {
        return detail.trim();
      }
      final err = responseData['error'];
      if (err is String && err.trim().isNotEmpty) {
        return err.trim();
      }
      final m =
          responseData['ErrorMessage'] ??
          responseData['errorMessage'] ??
          'An error occurred';
      return m is String ? m : m.toString();
    }
    if (responseData is Map) {
      return _errorMessageFromResponseData(Map<String, dynamic>.from(responseData));
    }
    if (responseData is String) {
      final text = responseData.trim();
      if (text.isNotEmpty) return text;
    }
    return 'An error occurred';
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final status = error.response!.statusCode ?? 0;
      final parsed = _errorMessageFromResponseData(error.response!.data);

      if (_isClientVersionError(error)) {
        return ApiHttpException(
          statusCode: status == 0 ? 426 : status,
          message: parsed,
          isClientVersionOutdated: true,
        );
      }

      if (status == 401 && !_isAuthPath(error.requestOptions)) {
        return ApiHttpException(
          statusCode: status,
          message: '',
          isUnauthorized: true,
        );
      }

      return ApiHttpException(
        statusCode: status,
        message: _userFacingHttpMessage(status: status, parsed: parsed),
      );
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return Exception(
        'Connection timed out. Check your internet connection and try again.',
      );
    }
    if (error.type == DioExceptionType.connectionError) {
      return Exception(
        'No internet connection. Please check your network and try again.',
      );
    }
    if (error.type == DioExceptionType.cancel) {
      return Exception('Request was cancelled.');
    }
    return Exception(
      'Network error. Please check your connection and try again.',
    );
  }

  /// Maps HTTP status + server body to copy safe to show in the app UI.
  static String _userFacingHttpMessage({
    required int status,
    required String parsed,
  }) {
    final hasParsed =
        parsed.trim().isNotEmpty && parsed.trim() != 'An error occurred';

    if (status >= 500 && status < 600) {
      return hasParsed
          ? parsed.trim()
          : 'Server error. Please try again later.';
    }
    if (status == 408) {
      return 'Request timed out. Please try again.';
    }
    if (status == 429) {
      return 'Too many requests. Please wait and try again.';
    }
    if (status == 401) {
      return hasParsed ? parsed.trim() : 'Invalid username or password.';
    }
    if (hasParsed) return parsed.trim();
    if (status == 404) return 'The requested resource was not found.';
    if (status == 403) {
      return 'You do not have permission to perform this action.';
    }
    return 'Something went wrong. Please try again.';
  }
}
