import 'package:dio/dio.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../presensi/data/models/santri_model.dart';
import 'models/daily_progress_model.dart';
import 'models/grade_model.dart';
import 'models/hafalan_model.dart';
import 'models/santri_lookup_model.dart';

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

  Future<List<SantriLookupModel>> searchStudents(String query) async {
    try {
      final response = await _dio.get('/capaian/cari', queryParameters: {'q': query});
      return (response.data['students'] as List)
          .map((e) => SantriLookupModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<SantriLookupModel> findStudent(String studentId) async {
    try {
      final response = await _dio.get('/capaian/santri/$studentId/temukan');
      return SantriLookupModel.fromJson(response.data as Map<String, dynamic>);
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

  Future<List<DailyProgressModel>> dailyProgress(String studentId) async {
    try {
      final response = await _dio.get('/capaian/santri/$studentId/harian');
      return (response.data['daily_progress'] as List)
          .map((e) => DailyProgressModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw ApiException.fromDioException(e);
    }
  }

  Future<void> inputDailyProgress({
    required String studentId,
    required String classId,
    required String date,
    required String method,
    required String keterangan,
    int? jilid,
    int? halaman,
    String? surah,
    int? ayatAwal,
    int? ayatAkhir,
    String? catatan,
  }) async {
    try {
      await _dio.post('/capaian/santri/$studentId/harian', data: {
        'class_id': classId,
        'date': date,
        'method': method,
        'keterangan': keterangan,
        if (jilid != null) 'jilid': jilid,
        if (halaman != null) 'halaman': halaman,
        if (surah != null) 'surah': surah,
        if (ayatAwal != null) 'ayat_awal': ayatAwal,
        if (ayatAkhir != null) 'ayat_akhir': ayatAkhir,
        if (catatan != null && catatan.isNotEmpty) 'catatan': catatan,
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
