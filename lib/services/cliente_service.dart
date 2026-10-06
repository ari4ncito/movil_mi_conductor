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
}
