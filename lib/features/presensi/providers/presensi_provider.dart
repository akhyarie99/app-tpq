import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/kelas_model.dart';
import '../data/models/rekap_model.dart';
import '../data/models/santri_model.dart';
import '../data/presensi_repository.dart';

final presensiRepositoryProvider = Provider<PresensiRepository>((ref) => PresensiRepository());

final kelasListProvider = FutureProvider.autoDispose<List<KelasModel>>((ref) {
  return ref.read(presensiRepositoryProvider).kelasList();
});

class PresensiInputData {
  PresensiInputData({required this.students, required this.initialStatuses});

  final List<SantriModel> students;
  final Map<String, KehadiranStatus> initialStatuses;
}

final presensiInputDataProvider =
    FutureProvider.autoDispose.family<PresensiInputData, String>((ref, classId) async {
  final repo = ref.read(presensiRepositoryProvider);
  final students = await repo.santriList(classId);
  final initialStatuses = await repo.todayAttendance(classId);
  return PresensiInputData(students: students, initialStatuses: initialStatuses);
});

final rekapProvider = FutureProvider.autoDispose
    .family<List<RekapItem>, ({String classId, int month, int year})>((ref, params) {
  return ref.read(presensiRepositoryProvider).rekap(params.classId, month: params.month, year: params.year);
});
