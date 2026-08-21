import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/staff_attendance_today.dart';
import '../data/staff_attendance_repository.dart';

final staffAttendanceRepositoryProvider = Provider<StaffAttendanceRepository>((ref) => StaffAttendanceRepository());

final staffAttendanceTodayProvider = FutureProvider.autoDispose<StaffAttendanceToday?>((ref) {
  return ref.read(staffAttendanceRepositoryProvider).today();
});

final staffAttendanceHistoryProvider = FutureProvider.autoDispose<List<StaffAttendanceToday>>((ref) {
  return ref.read(staffAttendanceRepositoryProvider).history();
});

final faceEnrollStatusProvider = FutureProvider.autoDispose<bool>((ref) {
  return ref.read(staffAttendanceRepositoryProvider).faceEnrollStatus();
});
