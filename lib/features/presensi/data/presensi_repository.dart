import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import 'models/kelas_model.dart';
import 'models/rekap_model.dart';
import 'models/santri_model.dart';

class PresensiRepository {
  PresensiRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<KelasModel>> kelasList() async {
    try {
      final response = await _dio.get('/presensi/kelas');
      return (response.data['classes'] as List)
          .map((e) => KelasModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<SantriModel>> santriList(String classId) async {
    try {
      final response = await _dio.get('/presensi/kelas/$classId/santri');
      return (response.data['students'] as List)
          .map((e) => SantriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  /// Map studentId -> status kehadiran yang sudah tersimpan hari ini (jika ada).
  Future<Map<String, KehadiranStatus>> todayAttendance(String classId) async {
    try {
      final response = await _dio.get('/presensi/kelas/$classId/today');
      final list = response.data['attendances'] as List;
      return {
        for (final item in list)
          (item['student_id'] as String): KehadiranStatusX.fromValue(item['status'] as String),
      };
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<String> submit({
    required String classId,
    required String date,
    required double latitude,
    required double longitude,
    required double accuracy,
    required Map<String, KehadiranStatus> attendances,
  }) async {
    try {
      final response = await _dio.post('/presensi/kelas/$classId/submit', data: {
        'date': date,
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'attendances': attendances.entries
            .map((e) => {'student_id': e.key, 'status': e.value.value})
            .toList(),
      });
      return response.data['message'] as String;
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<RekapItem>> rekap(String classId, {required int month, required int year}) async {
    try {
      final response = await _dio.get('/presensi/rekap/$classId', queryParameters: {
        'month': month,
        'year': year,
      });
      return (response.data['recap'] as List).map((e) => RekapItem.fromJson(e as Map<String, dynamic>)).toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
