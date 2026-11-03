import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class VehiculoService {
  // =========================
  // OBTENER TODOS LOS VEHICULOS
  // =========================
  static Future<List<dynamic>> getAll() async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos'),
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

    throw Exception(data['message'] ?? 'Error al obtener vehículos.');
  }

  // =========================
  // OBTENER VEHICULOS POR CLIENTE
  // =========================
  static Future<List<dynamic>> obtenerPorCliente(String clienteId) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos/cliente/$clienteId'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? [];
    }

    throw Exception(data['message'] ?? 'Error al obtener los vehículos del cliente.');
  }

  // =========================
  // CREAR VEHICULO
  // =========================
  static Future<Map<String, dynamic>> crear(Map<String, dynamic> vehiculoData) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.post(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehiculoData),
    );

    final data = jsonDecode(response.body);

    if ((response.statusCode == 201 || response.statusCode == 200) && data['success'] == true) {
      return data['data'];
    }

    String errorMsg = data['message']?.toString() ?? 'Error al crear el vehículo.';
    if (data['errors'] != null) {
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        errorMsg = (data['errors'] as List).join('\n');
      } else if (data['errors'] is Map) {
        errorMsg = (data['errors'] as Map).values.join('\n');
      }
    }

    throw Exception(errorMsg);
  }

  // =========================
  // ACTUALIZAR VEHICULO
  // =========================
  static Future<Map<String, dynamic>> update(String id, Map<String, dynamic> vehiculoData) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.put(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(vehiculoData),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'];
    }

    String errorMsg = data['message']?.toString() ?? 'Error al actualizar el vehículo.';
    if (data['errors'] != null) {
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        errorMsg = (data['errors'] as List).join('\n');
      } else if (data['errors'] is Map) {
        errorMsg = (data['errors'] as Map).values.join('\n');
      }
    }

    throw Exception(errorMsg);
  }

  // =========================
  // ELIMINAR VEHICULO
  // =========================
  static Future<void> delete(String id) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.delete(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode != 200 || data['success'] == false) {
      throw Exception(data['message'] ?? 'Error al eliminar el vehículo.');
    }
  }

  // =========================
  // VERIFICAR DISPONIBILIDAD DE PLACA
  // =========================
  static Future<Map<String, dynamic>> verificarPlaca(String placa) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final placaClean = placa.trim().toUpperCase();
    final response = await http.get(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos/verificar-placa/$placaClean'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? data;
    }

    throw Exception(data['message'] ?? 'Error al verificar la placa.');
  }

  // =========================
  // CAMBIAR ESTADO DEL VEHÍCULO
  // =========================
  static Future<Map<String, dynamic>> cambiarEstado(
    String id, {
    required String estadoVehiculo,
    String? motivo,
  }) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await http.patch(
      Uri.parse('${ApiConfig.baseUrl}/vehiculos/$id/estado'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({
        'estadoVehiculo': estadoVehiculo,
        if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo.trim(),
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return data['data'] ?? {};
    }

    String errorMsg = data['message']?.toString() ?? 'Error al cambiar estado del vehículo.';
    if (data['errors'] != null) {
      if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
        errorMsg = (data['errors'] as List).join('\n');
      } else if (data['errors'] is Map) {
        errorMsg = (data['errors'] as Map).values.join('\n');
      }
    }
    throw Exception(errorMsg);
  }
}
