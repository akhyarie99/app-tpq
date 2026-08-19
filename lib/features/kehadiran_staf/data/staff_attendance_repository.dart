import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/staff_attendance_today.dart';
import '../services/location_service.dart';

class StaffAttendanceRepository {
  StaffAttendanceRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<StaffAttendanceToday?> today() async {
    try {
      final response = await _dio.get('/kehadiran-staf/hari-ini');
      return response.data['attendance'] != null
          ? StaffAttendanceToday.fromJson(response.data['attendance'] as Map<String, dynamic>)
          : null;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<StaffAttendanceToday>> history() async {
    try {
      final response = await _dio.get('/kehadiran-staf/riwayat');
      return (response.data['attendances'] as List)
          .map((e) => StaffAttendanceToday.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> clockIn(LocationReading reading, List<double> descriptor, String photoPath, bool livenessVerified) async {
    try {
      final response = await _dio.post('/kehadiran-staf/masuk', data: {
        'lat': reading.lat,
        'lng': reading.lng,
        'is_mock_location': reading.isMockLocation,
        'gps_accuracy': reading.accuracy,
        'device_info': reading.deviceInfo,
        'descriptor': descriptor,
        'photo': _photoToBase64(photoPath),
        'liveness_verified': livenessVerified,
      });
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> clockOut(LocationReading reading, List<double> descriptor, String photoPath, bool livenessVerified) async {
    try {
      final response = await _dio.post('/kehadiran-staf/keluar', data: {
        'lat': reading.lat,
        'lng': reading.lng,
        'is_mock_location': reading.isMockLocation,
        'gps_accuracy': reading.accuracy,
        'device_info': reading.deviceInfo,
        'descriptor': descriptor,
        'photo': _photoToBase64(photoPath),
        'liveness_verified': livenessVerified,
      });
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<bool> faceEnrollStatus() async {
    try {
      final response = await _dio.get('/wajah/status');
      return response.data['enrolled'] as bool;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> faceEnroll(List<double> descriptor, String photoPath) async {
    try {
      await _dio.post('/wajah/daftar', data: {
        'descriptor': descriptor,
        'photo': _photoToBase64(photoPath),
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  String _photoToBase64(String path) {
    final bytes = File(path).readAsBytesSync();
    return 'data:image/jpeg;base64,${base64Encode(bytes)}';
  }
}
