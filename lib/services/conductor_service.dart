import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import 'auth_service.dart';

class ConductorService {
  // =========================
  // OBTENER CONDUCTOR
  // =========================

  static Future<Map<String, dynamic>> obtenerPorUsuario(
    String usuarioId,
  ) async {
    final token = await AuthService.obtenerToken();

    final response = await http.get(
      Uri.parse(
        '${ApiConfig.baseUrl}/conductores/usuario/$usuarioId',
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final resultado = data['data'];

      if (resultado is Map<String, dynamic>) {
        return resultado;
      }
    }

    throw Exception(
      data['message'] ?? 'No se encontró el conductor.',
    );
  }

  // =========================
  // ACTUALIZAR DISPONIBILIDAD
  // =========================

  static Future<Map<String, dynamic>> actualizarDisponibilidad(
    String conductorId,
    bool disponible,
  ) async {
    final token = await AuthService.obtenerToken();

    final response = await http.patch(
      Uri.parse(
        '${ApiConfig.baseUrl}/conductores/$conductorId/disponibilidad',
      ),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty)
          'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'disponible': disponible,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final resultado = data['data'];

      if (resultado is Map<String, dynamic>) {
        return resultado;
      }
    }

    throw Exception(
      data['message'] ?? 'No se pudo actualizar la disponibilidad.',
    );
  }
}