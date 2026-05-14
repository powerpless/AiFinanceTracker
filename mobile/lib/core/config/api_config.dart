import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  ApiConfig._();

  static String get baseUrl {
    const override = String.fromEnvironment('API_BASE');
    if (override.isNotEmpty) return override;
    if (kIsWeb) return 'http://localhost:8080';
    if (Platform.isAndroid) return 'http://localhost:8080';
    return 'http://localhost:8080';
  }
}
