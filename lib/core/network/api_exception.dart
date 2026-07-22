import 'package:dio/dio.dart';

/// Menerjemahkan DioException dari backend Laravel (format {"message": "..."}
/// atau {"message": "...", "errors": {...}} untuk 422 validasi) jadi pesan
/// yang siap ditampilkan ke user.
class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  factory ApiException.fromDioException(DioException e) {
    final statusCode = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map && data['message'] is String) {
      return ApiException(data['message'] as String, statusCode: statusCode);
    }

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.connectionError) {
      return ApiException('Tidak dapat terhubung ke server. Periksa koneksi internet Anda.');
    }

    return ApiException('Terjadi kesalahan. Silakan coba lagi.', statusCode: statusCode);
  }

  @override
  String toString() => message;
}
