import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../constants/api_constants.dart';
import 'api_interceptors.dart';

class DioClient {
  DioClient._();

  static Dio? _instance;

  static Dio get instance {
    _instance ??= _createDio();
    return _instance!;
  }

  static Dio _createDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl.isNotEmpty ? ApiConstants.baseUrl : "http://10.66.71.97:8000/api",
        connectTimeout:
            const Duration(milliseconds: ApiConstants.connectTimeoutMs),
        receiveTimeout:
            const Duration(milliseconds: ApiConstants.receiveTimeoutMs),
        sendTimeout:
            const Duration(milliseconds: ApiConstants.sendTimeoutMs),
        headers: {
          'Content-Type': ApiConstants.contentType,
          'Accept': 'application/json',
        },
        responseType: ResponseType.json,
      ),
    );

    // Auth interceptor (adds JWT, handles 401)
    dio.interceptors.add(AuthInterceptor(
      dio: dio,
      storage: const FlutterSecureStorage(),
    ));

    // Logging interceptor (debug builds only)
    if (kDebugMode) {
      dio.interceptors.add(LoggingInterceptor());
    }

    // Retry interceptor
    dio.interceptors.add(RetryInterceptor(dio: dio));

    return dio;
  }

  /// Convenience: reset instance (e.g., after logout)
  static void reset() {
    _instance?.close(force: true);
    _instance = null;
  }
}
