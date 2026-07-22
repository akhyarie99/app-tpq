import 'package:dio/dio.dart';

import '../constants/app_config.dart';
import '../storage/secure_storage.dart';

/// Callback dipanggil ketika server membalas 401 (token expired/dicabut) —
/// AuthProvider mendaftar di sini agar bisa memaksa logout + redirect ke Login.
typedef UnauthorizedHandler = void Function();

class DioClient {
  DioClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.instance.readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
        onError: (error, handler) {
          if (error.response?.statusCode == 401) {
            onUnauthorized?.call();
          }
          handler.next(error);
        },
      ),
    );
  }

  static final DioClient instance = DioClient._internal();

  late final Dio _dio;

  UnauthorizedHandler? onUnauthorized;

  Dio get dio => _dio;
}
