import 'package:dio/dio.dart';

import 'dashboard_models.dart';

class DashboardApi {
  final Dio _dio;

  DashboardApi(this._dio);

  Future<DashboardSummary> getSummary() async {
    final response =
        await _dio.get<Map<String, dynamic>>('/api/dashboard/summary');
    return DashboardSummary.fromJson(response.data!);
  }
}
