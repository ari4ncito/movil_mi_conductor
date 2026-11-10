import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class UsuarioService {
  // =========================
  // CONSULTAR POR DOCUMENTO (PÚBLICO)
  // =========================
  static Future<Map<String, dynamic>> consultarPorDocumento(
    String documento, {
    String? tipoDocumento,
  }) async {
    final doc = documento.trim();
    if (doc.isEmpty) return {'existe': false, 'datos': null};

    final query = <String, String>{};
    if (tipoDocumento != null && tipoDocumento.trim().isNotEmpty) {
      query['tipoDocumento'] = tipoDocumento.trim().toUpperCase();
    }

    final uri = ApiConfig.uri('/usuarios/consulta-documento/$doc', query.isNotEmpty ? query : null);
    final response = await http.get(
      uri,
      headers: {'Content-Type': 'application/json'},
    ).timeout(ApiConfig.requestTimeout);

    final data = jsonDecode(response.body);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic> && data['data'] is Map<String, dynamic>) {
        return Map<String, dynamic>.from(data['data']);
      }
    }
    return {'existe': false, 'datos': null};
  }

  // =========================
  // OBTENER USUARIO POR ID
  // =========================
  static Future<Map<String, dynamic>> obtenerPorId(String id) async {
    final token = await AuthService.obtenerToken();

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final user = data['data'];
      if (user is Map<String, dynamic>) {
        return user;
      }
    }

    throw Exception(data['message'] ?? 'Error al obtener usuario.');
  }

  // =========================
  // ACTUALIZAR USUARIO
  // =========================
  static Future<Map<String, dynamic>> actualizar(
    String id,
    Map<String, dynamic> datos,
  ) async {
    final token = await AuthService.obtenerToken();

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/usuarios/$id'),
      headers: {
        'Content-Type': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(datos),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final updatedUser = data['data'];

      if (updatedUser is Map<String, dynamic>) {
        // Actualizar sesión local en SharedPreferences
        final currentUser = await AuthService.obtenerUsuario();
        final Map<String, dynamic> merged = Map<String, dynamic>.from(currentUser ?? {});
        merged.addAll(updatedUser);

        // Normalizar id y rol
        merged['id'] = updatedUser['_id'] ?? updatedUser['id'] ?? merged['id'];
        merged['_id'] = merged['id'];
        if (updatedUser['rol'] is Map) {
          merged['rol'] = updatedUser['rol']['nombre'] ?? merged['rol'];
        }

        await AuthService.guardarUsuario(merged);
        return merged;
      }

      return data['data'] ?? {};
    }

    throw Exception(data['message'] ?? 'Error al actualizar el usuario.');
  }
}
