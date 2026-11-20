import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class ClienteService {
  // =========================
  // OBTENER TODOS LOS CLIENTES
  // =========================
  static Future<List<dynamic>> getAll() async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/clientes'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      if (data['data'] != null && data['data']['rows'] != null) {
        return data['data']['rows'];
      }
      return data['data'] ?? [];
    }

    throw Exception(data['message'] ?? 'Error al obtener clientes.');
  }

  // =========================
  // OBTENER CLIENTE POR ID
  // =========================
  static Future<Map<String, dynamic>> getById(String id) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/clientes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }

    throw Exception(data['message'] ?? 'Error al obtener el cliente.');
  }

  // =========================
  // ACTUALIZAR CLIENTE
  // =========================
  static Future<Map<String, dynamic>> update(String id, Map<String, dynamic> clienteData) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/clientes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(clienteData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }

    throw Exception(data['message'] ?? 'Error al actualizar el cliente.');
  }

  // =========================
  // ACTUALIZAR FOTO DEL CLIENTE
  // =========================
  static Future<Map<String, dynamic>> actualizarFoto(String idOrUsuarioId, String fotoUrl) async {
    return await update(idOrUsuarioId, {'foto': fotoUrl});
  }

  // =========================
  // ELIMINAR CLIENTE
  // =========================
  static Future<void> delete(String id) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/clientes/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] == false) {
      throw Exception(data['message'] ?? 'Error al eliminar el cliente.');
    }
  }

  // =========================
  // OBTENER CLIENTE DEL USUARIO ACTUAL
  // =========================
  static Future<Map<String, dynamic>?> obtenerClienteActual() async {
    final usuario = await AuthService.obtenerUsuario();
    if (usuario == null) return null;

    final usuarioId = (usuario['_id'] ?? usuario['id'])?.toString();
    if (usuarioId == null || usuarioId.isEmpty) return null;

    final token = await AuthService.obtenerToken();
    if (token != null) {
      try {
        final response = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/clientes/usuario/$usuarioId'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        );
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['success'] == true && data['data'] is Map) {
            return Map<String, dynamic>.from(data['data'] as Map);
          }
        }
      } catch (_) {}
    }

    try {
      final clientes = await getAll();
      for (final c in clientes) {
        if (c is Map<String, dynamic>) {
          final u = c['usuario'];
          if (u is Map && (u['_id']?.toString() == usuarioId || u['id']?.toString() == usuarioId)) {
            return c;
          } else if (u?.toString() == usuarioId) {
            return c;
          }
        }
      }
    } catch (_) {}

    return null;
  }
}
