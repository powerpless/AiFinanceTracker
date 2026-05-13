import 'package:dio/dio.dart';

import 'category_models.dart';

class CategoryApi {
  final Dio _dio;

  CategoryApi(this._dio);

  Future<List<Category>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/api/categories');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(Category.fromJson)
        .toList();
  }
}
