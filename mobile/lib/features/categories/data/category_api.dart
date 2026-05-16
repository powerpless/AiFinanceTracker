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

  Future<Category> create(String name, CategoryType type) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/categories',
      data: {'name': name, 'type': _wireType(type)},
    );
    return Category.fromJson(response.data!);
  }

  Future<Category> update(String id, String name, CategoryType type) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/categories/$id',
      data: {'name': name, 'type': _wireType(type)},
    );
    return Category.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/categories/$id');
  }

  String _wireType(CategoryType type) =>
      type == CategoryType.income ? 'INCOME' : 'EXPENSE';
}
