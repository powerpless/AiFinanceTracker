import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';
import 'api_exception.dart';
import 'auth_interceptor.dart';

class ApiClient {
  final Dio dio;

  ApiClient._(this.dio);

  factory ApiClient.create({
    required TokenStorage tokenStorage,
    required Future<void> Function() onUnauthorized,
  }) {
    final base = BaseOptions(
      baseUrl: ApiConfig.baseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 15),
      contentType: 'application/json',
      responseType: ResponseType.json,
    );

    final dio = Dio(base);
    final refreshDio = Dio(base);

    dio.interceptors.add(AuthInterceptor(
      tokenStorage: tokenStorage,
      refreshDio: refreshDio,
      onUnauthorized: onUnauthorized,
    ));

    dio.interceptors.add(InterceptorsWrapper(
      onError: (err, handler) {
        final res = err.response;
        if (res != null) {
          final apiErr = ApiException.fromResponse(res.statusCode, res.data);
          return handler.reject(DioException(
            requestOptions: err.requestOptions,
            response: res,
            type: err.type,
            error: apiErr,
          ));
        }
        handler.next(err);
      },
    ));

    return ApiClient._(dio);
  }
}
