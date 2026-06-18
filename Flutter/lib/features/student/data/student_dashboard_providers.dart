import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/data/auth_providers.dart';
import 'student_dashboard_api.dart';
import 'student_dashboard_models.dart';

final studentDashboardApiProvider = Provider<StudentDashboardApi>((ref) {
  return StudentDashboardApi(ref.watch(apiClientProvider));
});

final studentDashboardProvider = FutureProvider.autoDispose<StudentDashboardData>((ref) async {
  return ref.watch(studentDashboardApiProvider).loadDashboard();
});
