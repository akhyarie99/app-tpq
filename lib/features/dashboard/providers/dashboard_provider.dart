import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/dashboard_repository.dart';
import '../data/models/dashboard_model.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) => DashboardRepository());

final dashboardProvider = FutureProvider.autoDispose<DashboardData>((ref) {
  return ref.read(dashboardRepositoryProvider).fetch();
});
