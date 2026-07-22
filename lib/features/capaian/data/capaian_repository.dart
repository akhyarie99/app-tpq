import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../presensi/data/models/santri_model.dart';
import 'models/grade_model.dart';
import 'models/hafalan_model.dart';

class CapaianRepository {
  CapaianRepository({Dio? dio}) : _dio = dio ?? DioClient.instance.dio;

  final Dio _dio;

  Future<List<SantriModel>> santriList(String classId) async {
    try {
      final response = await _dio.get('/capaian/kelas/$classId/santri');
      return (response.data['students'] as List)
          .map((e) => SantriModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<CapaianDetail> detail(String studentId) async {
    try {
      final response = await _dio.get('/capaian/santri/$studentId');
      return CapaianDetail.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<List<HafalanModel>> hafalan(String studentId) async {
    try {
      final response = await _dio.get('/capaian/santri/$studentId/hafalan');
      return (response.data['hafalan'] as List)
          .map((e) => HafalanModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> inputNilai({
    required String studentId,
    required String classId,
    required String subjectId,
    required String semesterId,
    required num score,
    String? description,
  }) async {
    try {
      await _dio.post('/capaian/santri/$studentId/nilai', data: {
        'class_id': classId,
        'subject_id': subjectId,
        'semester_id': semesterId,
        'score': score,
        if (description != null) 'description': description,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> updateHafalan({
    required String studentId,
    required int surahNumber,
    required String surahName,
    required int totalAyah,
    required int memorizedAyah,
    required String status,
  }) async {
    try {
      await _dio.post('/capaian/santri/$studentId/hafalan', data: {
        'surah_number': surahNumber,
        'surah_name': surahName,
        'total_ayah': totalAyah,
        'memorized_ayah': memorizedAyah,
        'status': status,
      });
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }
}
