import 'package:http/http.dart' as http;

class ApiConfig {
  const ApiConfig._();

  /// Cliente HTTP compartido para reutilizar conexiones Keep-Alive (evita handshakes repetidos).
  static final http.Client httpClient = http.Client();

  static const String productionUrl =
      'https://backend-miconductor.onrender.com/api';

  static String get _fallbackUrl => productionUrl;

  /// Override with `--dart-define=API_BASE_URL=https://...` per environment.
  static String get baseUrl {
    const fromEnv = String.fromEnvironment('API_BASE_URL');
    final raw = fromEnv.isEmpty ? _fallbackUrl : fromEnv.trim();
    return raw.endsWith('/') ? raw.substring(0, raw.length - 1) : raw;
  }

  static const Duration requestTimeout = Duration(seconds: 35);

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
