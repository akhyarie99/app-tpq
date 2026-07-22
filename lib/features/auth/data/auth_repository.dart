import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'models/user_model.dart';

class AuthRepository {
  AuthRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<UserModel> login({required String phone, required String password, String? fcmToken}) async {
    try {
      final response = await _dio.post('/login', data: {
        'phone': phone,
        'password': password,
        if (fcmToken != null) 'fcm_token': fcmToken,
      });

      final token = response.data['token'] as String;
      await SecureStorage.instance.saveToken(token);

      final user = UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
      await SecureStorage.instance.saveUserBasics(name: user.name, role: user.role);

      return user;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<UserModel> fetchProfile() async {
    try {
      final response = await _dio.get('/profile');
      return UserModel.fromJson(response.data['user'] as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> logout() async {
    try {
      await _dio.post('/logout');
    } on DioException {
      // Tetap hapus token lokal walau request logout gagal (mis. sudah offline).
    } finally {
      await SecureStorage.instance.clear();
    }
  }

  Future<String> getWebviewToken() async {
    try {
      final response = await _dio.get('/webview-token');
      return response.data['token'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
