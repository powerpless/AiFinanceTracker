class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, String>? validationErrors;

  ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.validationErrors,
  });

  factory ApiException.fromResponse(int? statusCode, dynamic data) {
    if (data is Map<String, dynamic>) {
      final errorField = data['error'];
      final messageField = data['message'];
      final detailsField = data['details'];

      String code = 'UNKNOWN';
      String? message;

      if (errorField is String) {
        code = errorField;
        message = errorField;
      }
      if (messageField is String && messageField.isNotEmpty) {
        message = messageField;
      }

      Map<String, String>? validationMap;
      final validation = data['validationErrors'] ?? detailsField;
      if (validation is Map) {
        validationMap = validation.map(
          (k, v) => MapEntry(k.toString(), v.toString()),
        );
        message ??= validationMap.entries
            .map((e) => '${e.key}: ${e.value}')
            .join('; ');
      }

      return ApiException(
        code: code,
        message: message ?? 'Request failed (status $statusCode)',
        statusCode: statusCode,
        validationErrors: validationMap,
      );
    }
    return ApiException(
      code: 'UNKNOWN',
      message: 'Unexpected error (status $statusCode)',
      statusCode: statusCode,
    );
  }

  @override
  String toString() => 'ApiException($code, status=$statusCode): $message';
}
