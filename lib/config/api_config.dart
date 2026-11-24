import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiConfig {
  const ApiConfig._();

  static String get _fallbackUrl {
    return 'https://backend-miconductor.onrender.com/api';
  }

  /// Override with `--dart-define=API_BASE_URL=https://...` per environment.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    return fromEnv.isEmpty ? _fallbackUrl : fromEnv;
  }

  static const Duration requestTimeout = Duration(seconds: 20);

  static Uri uri(String path, [Map<String, String>? queryParameters]) {
    final normalizedBase = baseUrl.endsWith('/')
        ? baseUrl.substring(0, baseUrl.length - 1)
        : baseUrl;
    var normalizedPath = path.startsWith('/') ? path : '/$path';
    if (normalizedBase.endsWith('/api') && normalizedPath.startsWith('/api/')) {
      normalizedPath = normalizedPath.substring(4);
    }
    return Uri.parse('$normalizedBase$normalizedPath').replace(
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
  }
}
