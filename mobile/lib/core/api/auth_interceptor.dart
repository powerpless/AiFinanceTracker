import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

typedef OnUnauthorized = Future<void> Function();

class AuthInterceptor extends Interceptor {
  final TokenStorage tokenStorage;
  final Dio refreshDio;
  final OnUnauthorized onUnauthorized;

  bool _isRefreshing = false;

  AuthInterceptor({
    required this.tokenStorage,
    required this.refreshDio,
    required this.onUnauthorized,
  });

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final skipAuth = options.extra['skipAuth'] == true;
    if (!skipAuth) {
      final token = await tokenStorage.readAccessToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final response = err.response;
    final request = err.requestOptions;
    final isUnauthorized = response?.statusCode == 401;
    final isRefreshCall = request.path.contains('/api/auth/refresh');
    final alreadyRetried = request.extra['retried'] == true;

    if (!isUnauthorized || isRefreshCall || alreadyRetried || _isRefreshing) {
      return handler.next(err);
    }

    final refreshToken = await tokenStorage.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await onUnauthorized();
      return handler.next(err);
    }

    _isRefreshing = true;
    try {
      final refreshResponse = await refreshDio.post<Map<String, dynamic>>(
        '/api/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = refreshResponse.data;
      if (data == null) {
        await onUnauthorized();
        return handler.next(err);
      }
      final newAccess = data['accessToken'] as String;
      final newRefresh = data['refreshToken'] as String;
      await tokenStorage.saveTokens(
        accessToken: newAccess,
        refreshToken: newRefresh,
      );

      request.headers['Authorization'] = 'Bearer $newAccess';
      request.extra['retried'] = true;
      final retryResponse = await refreshDio.fetch(request);
      return handler.resolve(retryResponse);
    } on DioException catch (_) {
      await onUnauthorized();
      return handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
