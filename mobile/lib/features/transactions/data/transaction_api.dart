import 'package:dio/dio.dart';

import 'transaction_models.dart';

class TransactionApi {
  final Dio _dio;

  TransactionApi(this._dio);

  Future<List<TransactionItem>> getAll() async {
    final response = await _dio.get<List<dynamic>>('/api/transactions');
    return (response.data ?? [])
        .whereType<Map<String, dynamic>>()
        .map(TransactionItem.fromJson)
        .toList();
  }

  Future<TransactionItem> create(TransactionCreateRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/transactions',
      data: request.toJson(),
    );
    return TransactionItem.fromJson(response.data!);
  }

  Future<void> delete(String id) async {
    await _dio.delete('/api/transactions/$id');
  }
}
