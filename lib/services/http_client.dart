import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic errors;

  const ApiException(this.message, {this.statusCode, this.errors});

  @override
  String toString() => message;
}

class ApiHttpClient {
  final http.Client _client;
  String? token;

  ApiHttpClient({http.Client? client, this.token})
    : _client = client ?? http.Client();

  Future<Map<String, String>> _getHeaders() async {
    final activeToken = token ?? await AuthService.obtenerToken();
    return {
      'Accept': 'application/json',
      'Content-Type': 'application/json',
      if (activeToken != null && activeToken.trim().isNotEmpty)
        'Authorization': 'Bearer ${activeToken.trim()}',
    };
  }

  Future<dynamic> get(String path, {Map<String, String>? queryParameters}) async {
    final headers = await _getHeaders();
    return _send(() => _client.get(ApiConfig.uri(path, queryParameters), headers: headers));
  }

  Future<dynamic> post(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _send(
      () => _client.post(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> patch(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _send(
      () => _client.patch(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> put(String path, {Map<String, dynamic>? body}) async {
    final headers = await _getHeaders();
    return _send(
      () => _client.put(
        ApiConfig.uri(path),
        headers: headers,
        body: jsonEncode(body ?? <String, dynamic>{}),
      ),
    );
  }

  Future<dynamic> delete(String path) async {
    final headers = await _getHeaders();
    return _send(() => _client.delete(ApiConfig.uri(path), headers: headers));
  }

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(ApiConfig.requestTimeout);
      final decoded = _decode(response.body);
      if (response.statusCode < 200 ||
          response.statusCode >= 300 ||
          (decoded is Map && decoded['success'] == false)) {
        final message = decoded is Map && decoded['message'] is String
            ? decoded['message'] as String
            : 'La solicitud no pudo completarse (${response.statusCode}).';
        throw ApiException(
          message,
          statusCode: response.statusCode,
          errors: decoded is Map ? decoded['errors'] : null,
        );
      }
      return decoded is Map && decoded.containsKey('data')
          ? decoded['data']
          : decoded;
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException('El servidor tardó demasiado en responder.');
    } on FormatException {
      throw const ApiException('El servidor devolvió una respuesta inválida.');
    } on Exception catch (error) {
      throw ApiException('No se pudo conectar con el servidor: $error');
    }
  }

  dynamic _decode(String body) {
    if (body.trim().isEmpty) return null;
    return jsonDecode(body);
  }

  void dispose() => _client.close();
}
