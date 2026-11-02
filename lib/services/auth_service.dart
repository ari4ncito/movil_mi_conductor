import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';
import 'fcm_service.dart';

class AuthApiException implements Exception {
  final String message;
  final int? statusCode;
  final Map<String, String> fieldErrors;

  const AuthApiException(
    this.message, {
    this.statusCode,
    this.fieldErrors = const {},
  });

  @override
  String toString() => 'Exception: $message';
}

class AuthService {
  static http.Client? httpClientOverride;

  static Future<http.Response> _postJson(
    Uri uri, {
    required Map<String, dynamic> body,
    Map<String, String>? extraHeaders,
    Duration? timeout,
  }) {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (extraHeaders != null) ...extraHeaders,
    };
    final encoded = jsonEncode(body);
    final effectiveTimeout = timeout ?? ApiConfig.requestTimeout;

    if (httpClientOverride != null) {
      return httpClientOverride!
          .post(uri, headers: headers, body: encoded)
          .timeout(effectiveTimeout);
    }

    return http
        .post(uri, headers: headers, body: encoded)
        .timeout(effectiveTimeout);
  }

  static Future<http.Response> _getUri(
    Uri uri, {
    Map<String, String>? headers,
    Duration? timeout,
  }) {
    final effectiveTimeout = timeout ?? const Duration(seconds: 8);

    if (httpClientOverride != null) {
      return httpClientOverride!
          .get(uri, headers: headers)
          .timeout(effectiveTimeout);
    }

    return http.get(uri, headers: headers).timeout(effectiveTimeout);
  }

  static Map<String, String> _extractFieldErrors(dynamic rawErrors) {
    final result = <String, String>{};
    if (rawErrors is List) {
      for (final item in rawErrors) {
        if (item is Map) {
          final campo = item['campo']?.toString() ?? '';
          final mensaje = item['mensaje']?.toString() ?? '';
          if (campo.isNotEmpty &&
              mensaje.isNotEmpty &&
              !result.containsKey(campo)) {
            result[campo] = mensaje;
          }
        }
      }
    }
    return result;
  }

  static Map<String, dynamic> _tryDecodeBody(String body) {
    if (body.trim().isEmpty) return <String, dynamic>{};
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded;
      }
    } catch (_) {}
    return <String, dynamic>{};
  }

  // =========================
  // INICIAR SESIÓN
  // =========================

  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {
    http.Response response;
    try {
      response = await _postJson(
        Uri.parse('${ApiConfig.baseUrl}/auth/mobile-login'),
        body: {
          'correo': correo,
          'password': password,
        },
      );
    } on TimeoutException {
      throw const AuthApiException(
        'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const AuthApiException(
        'No fue posible conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
      );
    }

    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final resultado = data['data'];
      await guardarSesion(resultado);

      // Registrar dispositivo para notificaciones push
      try {
        await FcmService().registrarDispositivo();
      } catch (_) {}

      return resultado;
    }

    final fieldErrors = _extractFieldErrors(data['errors']);
    final fallbackMessage = (response.statusCode == 401)
        ? 'Correo o contraseña incorrectos.'
        : 'Error al iniciar sesión.';

    throw AuthApiException(
      data['message']?.toString() ?? fallbackMessage,
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  // =========================
  // REGISTRO
  // =========================

  static Future<Map<String, dynamic>> register({
    required String nombre,
    required String apellido,
    required String tipoDocumento,
    required String documento,
    required String correo,
    required String password,
    required String telefono,
    required String direccion,
  }) async {
    http.Response response;
    try {
      response = await _postJson(
        Uri.parse('${ApiConfig.baseUrl}/clientes'),
        body: {
          'nombre': nombre,
          'apellido': apellido,
          'tipoDocumento': tipoDocumento,
          'documento': documento,
          'correo': correo,
          'password': password,
          'telefono': telefono,
          'direccion': direccion,
        },
      );
    } on TimeoutException {
      throw const AuthApiException(
        'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const AuthApiException(
        'No fue posible conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
      );
    }

    final data = _tryDecodeBody(response.body);

    if ((response.statusCode == 200 || response.statusCode == 201) &&
        data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    }

    final fieldErrors = _extractFieldErrors(data['errors']);
    throw AuthApiException(
      data['message']?.toString() ?? 'Error al crear la cuenta.',
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  // =========================
  // COMPROBAR DISPONIBILIDAD CORREO
  // =========================

  static Future<Map<String, dynamic>> checkEmail(String correo) async {
    final uri = ApiConfig.uri(
      '/auth/check-email',
      {'correo': correo.trim().toLowerCase()},
    );
    final response = await _getUri(uri);
    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    }

    throw AuthApiException(
      data['message']?.toString() ?? 'Error al verificar correo.',
      statusCode: response.statusCode,
    );
  }

  // =========================
  // COMPROBAR DISPONIBILIDAD DOCUMENTO
  // =========================

  static Future<Map<String, dynamic>> checkDocument(
    String documento, [
    String? tipoDocumento,
  ]) async {
    final params = <String, String>{
      'documento': documento.trim(),
    };
    if (tipoDocumento != null && tipoDocumento.trim().isNotEmpty) {
      params['tipoDocumento'] = tipoDocumento.trim().toUpperCase();
    }

    final uri = ApiConfig.uri('/auth/check-document', params);
    final response = await _getUri(uri);
    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return (data['data'] as Map<String, dynamic>?) ?? {};
    }

    throw AuthApiException(
      data['message']?.toString() ?? 'Error al verificar documento.',
      statusCode: response.statusCode,
    );
  }

  // =========================
  // RECUPERAR CONTRASEÑA
  // =========================

  static Future<void> forgotPassword(String correo) async {
    http.Response response;
    try {
      response = await _postJson(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        body: {
          'correo': correo.trim().toLowerCase(),
          'origen': 'mobile',
        },
      );
    } on TimeoutException {
      throw const AuthApiException(
        'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const AuthApiException(
        'No fue posible conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
      );
    }

    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    final fieldErrors = _extractFieldErrors(data['errors']);
    throw AuthApiException(
      fieldErrors['correo'] ??
          data['message']?.toString() ??
          'No se pudo procesar la solicitud de recuperación.',
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  // =========================
  // RESTABLECER CONTRASEÑA
  // =========================

  static Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    http.Response response;
    try {
      response = await _postJson(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        body: {
          'token': token,
          'password': password,
        },
      );
    } on TimeoutException {
      throw const AuthApiException(
        'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const AuthApiException(
        'No fue posible conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
      );
    }

    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    final fieldErrors = _extractFieldErrors(data['errors']);
    throw AuthApiException(
      fieldErrors['password'] ??
          data['message']?.toString() ??
          'No se pudo restablecer la contraseña.',
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  // =========================
  // CAMBIAR CONTRASEÑA (AUTENTICADO)
  // =========================

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final token = await obtenerToken();
    if (token == null || token.trim().isEmpty) {
      throw const AuthApiException(
        'Debes iniciar sesión para cambiar tu contraseña.',
        statusCode: 401,
      );
    }

    http.Response response;
    try {
      response = await _postJson(
        Uri.parse('${ApiConfig.baseUrl}/auth/change-password'),
        extraHeaders: {
          'Authorization': 'Bearer $token',
        },
        body: {
          'currentPassword': currentPassword,
          'newPassword': newPassword,
          'confirmPassword': confirmPassword,
        },
      );
    } on TimeoutException {
      throw const AuthApiException(
        'La solicitud tardó demasiado. Verifica tu conexión e intenta nuevamente.',
      );
    } catch (_) {
      throw const AuthApiException(
        'No fue posible conectar con el servidor. Verifica tu conexión e intenta nuevamente.',
      );
    }

    final data = _tryDecodeBody(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    final fieldErrors = _extractFieldErrors(data['errors']);
    throw AuthApiException(
      data['message']?.toString() ?? 'No se pudo actualizar la contraseña.',
      statusCode: response.statusCode,
      fieldErrors: fieldErrors,
    );
  }

  // =========================
  // GUARDAR SESIÓN
  // =========================

  static Future<void> guardarSesion(
    Map<String, dynamic> datos,
  ) async {
    final prefs = await SharedPreferences.getInstance();

    if (datos['token'] != null) {
      await prefs.setString(
        'token',
        datos['token'].toString(),
      );
    }

    if (datos['usuario'] != null) {
      await prefs.setString(
        'usuario',
        jsonEncode(datos['usuario']),
      );
    }
  }

  // =========================
  // GUARDAR USUARIO
  // =========================

  static Future<void> guardarUsuario(
    Map<String, dynamic> usuario,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'usuario',
      jsonEncode(usuario),
    );
  }

  // =========================
  // OBTENER TOKEN
  // =========================

  static Future<String?> obtenerToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // =========================
  // OBTENER USUARIO
  // =========================

  static Future<Map<String, dynamic>?> obtenerUsuario() async {
    final prefs = await SharedPreferences.getInstance();
    final usuario = prefs.getString('usuario');

    if (usuario == null || usuario.isEmpty) {
      return null;
    }

    final datos = jsonDecode(usuario);
    if (datos is Map<String, dynamic>) {
      return datos;
    }

    return null;
  }

  // =========================
  // OBTENER ID DEL USUARIO
  // =========================

  static Future<String?> obtenerUsuarioId() async {
    final usuario = await obtenerUsuario();
    if (usuario == null) return null;
    final id = usuario['_id'] ?? usuario['id'];
    return id?.toString();
  }

  // =========================
  // COMPROBAR SESIÓN
  // =========================

  static Future<bool> tieneSesion() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final usuario = prefs.getString('usuario');

    return token != null &&
        token.isNotEmpty &&
        usuario != null &&
        usuario.isNotEmpty;
  }

  // =========================
  // CERRAR SESIÓN
  // =========================

  static Future<void> logout() async {
    // Desvincular token FCM del backend antes de limpiar SharedPreferences
    try {
      await FcmService().desvincularDispositivo();
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    await prefs.remove('usuario');
  }
}
