import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';
import 'data/dashboard_api.dart';
import 'data/dashboard_models.dart';

final dashboardApiProvider =
    Provider<DashboardApi>((ref) => DashboardApi(ref.watch(dioProvider)));

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  final api = ref.watch(dashboardApiProvider);
  return api.getSummary();
});
