import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import '../storage/token_storage.dart';

// ─────────────────────────────────────────────────────────────
// AUTH INTERCEPTOR
// Injects JWT into every request; refreshes / clears on 401
// ─────────────────────────────────────────────────────────────
class AuthInterceptor extends Interceptor {
  final Dio dio;
  final FlutterSecureStorage storage;
  bool _isRefreshing = false;

  AuthInterceptor({required this.dio, required this.storage});

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final token = await TokenStorage.getToken();
    if (token != null && token.isNotEmpty) {
      options.headers[ApiConstants.authHeader] =
          '${ApiConstants.tokenPrefix} $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    if (err.response?.statusCode == 401 && !_isRefreshing) {
      _isRefreshing = true;
      try {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // Retry original request with new token
          final token = await TokenStorage.getToken();
          final opts = err.requestOptions;
          opts.headers[ApiConstants.authHeader] =
              '${ApiConstants.tokenPrefix} $token';
          final response = await dio.fetch(opts);
          handler.resolve(response);
          return;
        }
      } catch (_) {
        // Refresh failed — clear credentials
      } finally {
        _isRefreshing = false;
      }

      // Clear credentials and signal logout
      await TokenStorage.clearAll();
      handler.next(err);
      return;
    }
    handler.next(err);
  }

  Future<bool> _tryRefreshToken() async {
    return false;
  }
}

// ─────────────────────────────────────────────────────────────
// LOGGING INTERCEPTOR
// Logs method, URL, status, and errors in debug mode
// ─────────────────────────────────────────────────────────────
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    debugPrint('[DIO] ➡️  ${options.method} ${options.uri}');
    if (options.data != null) {
      debugPrint('[DIO] 📦 Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    debugPrint(
      '[DIO] ✅ ${response.statusCode} ${response.requestOptions.uri}',
    );
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    debugPrint(
      '[DIO] ❌ ${err.response?.statusCode} '
      '${err.requestOptions.uri} — ${err.message}',
    );
    if (err.response?.data != null) {
      debugPrint('[DIO] 🔴 Error body: ${err.response?.data}');
    }
    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────
// RETRY INTERCEPTOR
// Retries idempotent requests once on network failure
// ─────────────────────────────────────────────────────────────
class RetryInterceptor extends Interceptor {
  final Dio dio;
  static const _maxRetries = 1;
  static const _retryKey = 'retry_count';

  RetryInterceptor({required this.dio});

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final retryCount = (options.extra[_retryKey] as int?) ?? 0;

    final isNetworkError = err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.connectionError;

    final isIdempotent = ['GET', 'HEAD', 'PUT', 'DELETE']
        .contains(options.method.toUpperCase());

    if (isNetworkError && isIdempotent && retryCount < _maxRetries) {
      options.extra[_retryKey] = retryCount + 1;
      await Future.delayed(const Duration(milliseconds: 500));
      try {
        final response = await dio.fetch(options);
        handler.resolve(response);
        return;
      } catch (e) {
        // Fall through to original error
      }
    }

    handler.next(err);
  }
}

// ─────────────────────────────────────────────────────────────
// API EXCEPTION
// Structured error model returned from all API calls
// ─────────────────────────────────────────────────────────────
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;

  const ApiException({
    required this.message,
    this.statusCode,
    this.data,
  });

  factory ApiException.fromDioError(DioException e) {
    final statusCode = e.response?.statusCode;
    final responseData = e.response?.data;

    String message;
    if (responseData is Map<String, dynamic>) {
      message = responseData['message'] as String? ??
          responseData['error'] as String? ??
          'An error occurred';
    } else {
      switch (e.type) {
        case DioExceptionType.connectionTimeout:
        case DioExceptionType.sendTimeout:
        case DioExceptionType.receiveTimeout:
          message = 'Connection timed out. Please check your network.';
          break;
        case DioExceptionType.connectionError:
          message = 'No internet connection.';
          break;
        default:
          message = e.message ?? 'An unexpected error occurred';
      }
    }

    return ApiException(
      message: message,
      statusCode: statusCode,
      data: responseData,
    );
  }

  bool get isUnauthorized => statusCode == 401;
  bool get isForbidden => statusCode == 403;
  bool get isNotFound => statusCode == 404;
  bool get isServerError =>
      statusCode != null && statusCode! >= 500;

  @override
  String toString() =>
      'ApiException(status: $statusCode, message: $message)';
}
