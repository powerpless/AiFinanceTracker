import 'package:dio/dio.dart';

import 'recommendation_models.dart';

class RecommendationApi {
  final Dio _dio;

  RecommendationApi(this._dio);

  Future<List<Recommendation>> getActive() async {
    final response = await _dio.get<List<dynamic>>('/api/recommendations');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }

  Future<List<Recommendation>> refresh() async {
    final response =
        await _dio.post<List<dynamic>>('/api/recommendations/refresh');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Recommendation.fromJson)
        .toList();
  }

  Future<void> dismiss(String id) async {
    await _dio.post('/api/recommendations/$id/dismiss');
  }

  Future<bool> isMlServiceHealthy() async {
    try {
      final response =
          await _dio.get<Map<String, dynamic>>('/api/recommendations/health');
      return response.data?['mlService'] == 'up';
    } on DioException {
      return false;
    }
  }
}
