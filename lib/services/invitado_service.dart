import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class InvitadoService {
  /// Consulta pública de persona por número de documento para autocompletar el formulario.
  /// No requiere token de autenticación.
  static Future<Map<String, dynamic>> consultarPorDocumento(
    String documento, {
    String? tipoDocumento,
  }) async {
    final docNormalizado = documento.trim();
    if (docNormalizado.isEmpty) {
      return {'existe': false, 'datos': null};
    }

    try {
      final queryParams = <String, String>{};
      if (tipoDocumento != null && tipoDocumento.trim().isNotEmpty) {
        queryParams['tipoDocumento'] = tipoDocumento.trim().toUpperCase();
      }

      final uri = ApiConfig.uri(
        '/usuarios/consulta-documento/$docNormalizado',
        queryParams.isNotEmpty ? queryParams : null,
      );

      final response = await http
          .get(
            uri,
            headers: {'Content-Type': 'application/json'},
          )
          .timeout(ApiConfig.requestTimeout);

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(data['data']);
        }
      }

      // Si no fue exitoso o no se encontró
      return {'existe': false, 'datos': null};
    } catch (e) {
      debugPrint('Error en InvitadoService.consultarPorDocumento: $e');
      // No bloquear al usuario si falla la conexión
      return {'existe': false, 'datos': null, 'error': e.toString()};
    }
  }

  /// Crea una solicitud como invitado sin token de autenticación.
  static Future<Map<String, dynamic>> crearSolicitud(
    Map<String, dynamic> datos,
  ) async {
    final uri = ApiConfig.uri('/invitado/solicitud');

    try {
      final response = await http
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(datos),
          )
          .timeout(const Duration(seconds: 30));

      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (data is Map<String, dynamic>) {
          return data['data'] is Map<String, dynamic>
              ? Map<String, dynamic>.from(data['data'])
              : data;
        }
      }

      final errorMsg = (data is Map && data['message'] != null)
          ? data['message']
          : 'Error ${response.statusCode} al registrar la solicitud.';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('Error en InvitadoService.crearSolicitud: $e');
      rethrow;
    }
  }

  /// Consulta el estado de una solicitud de invitado por su código (ej: INV-...).
  static Future<Map<String, dynamic>> consultarSolicitudPorCodigo(
    String codigo,
  ) async {
    final cod = codigo.trim().toUpperCase();
    final uri = ApiConfig.uri('/invitado/solicitud/$cod');

    final response = await http
        .get(
          uri,
          headers: {'Content-Type': 'application/json'},
        )
        .timeout(ApiConfig.requestTimeout);

    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data']);
      }
    }

    final errorMsg = (data is Map && data['message'] != null)
        ? data['message']
        : 'Solicitud no encontrada.';
    throw Exception(errorMsg);
  }
}

