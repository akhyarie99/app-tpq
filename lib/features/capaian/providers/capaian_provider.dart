import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../presensi/data/models/santri_model.dart';
import '../data/capaian_repository.dart';
import '../data/models/grade_model.dart';
import '../data/models/hafalan_model.dart';

final capaianRepositoryProvider = Provider<CapaianRepository>((ref) => CapaianRepository());

final capaianSantriListProvider =
    FutureProvider.autoDispose.family<List<SantriModel>, String>((ref, classId) {
  return ref.read(capaianRepositoryProvider).santriList(classId);
});

final capaianDetailProvider =
    FutureProvider.autoDispose.family<CapaianDetail, String>((ref, studentId) {
  return ref.read(capaianRepositoryProvider).detail(studentId);
});

final hafalanProvider = FutureProvider.autoDispose.family<List<HafalanModel>, String>((ref, studentId) {
  return ref.read(capaianRepositoryProvider).hafalan(studentId);
});
