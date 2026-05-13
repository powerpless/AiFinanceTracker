import 'package:dio/dio.dart';

import 'auth_models.dart';

class AuthApi {
  final Dio _dio;

  AuthApi(this._dio);

  Future<AuthTokens> login(LoginRequest request) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/auth/login',
      data: request.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );
    return AuthTokens.fromJson(response.data!);
  }

  Future<void> register(RegisterRequest request) async {
    await _dio.post<Map<String, dynamic>>(
      '/api/auth/register',
      data: request.toJson(),
      options: Options(extra: {'skipAuth': true}),
    );
  }

  Future<void> logout() async {
    await _dio.post<Map<String, dynamic>>('/api/auth/logout');
  }
}
