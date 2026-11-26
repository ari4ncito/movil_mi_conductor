import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import 'auth_service.dart';

class VehiculoService {
  // El backend responde errores de validación como [{campo, mensaje}]; se muestran solo los mensajes.
  static String? _mensajesDeError(dynamic errors) {
    final mensajes = <String>[];
    if (errors is List) {
      for (final item in errors) {
        final msg = item is Map ? item['mensaje']?.toString() : item?.toString();
        if (msg != null && msg.isNotEmpty) mensajes.add(msg);
      }
    } else if (errors is Map) {
      mensajes.addAll(errors.values.map((v) => v.toString()).where((v) => v.isNotEmpty));
    }
    return mensajes.isEmpty ? null : mensajes.join('\n');
  }

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
    errorMsg = _mensajesDeError(data['errors']) ?? errorMsg;

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
    errorMsg = _mensajesDeError(data['errors']) ?? errorMsg;

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
  /// [excluirId]: id del vehículo en edición, para que no se detecte a sí mismo como duplicado.
  static Future<Map<String, dynamic>> verificarPlaca(String placa, {String? excluirId}) async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final placaClean = placa.replaceAll(RegExp(r'[\s-]'), '').toUpperCase();
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/vehiculos/verificar-placa/${Uri.encodeComponent(placaClean)}',
    ).replace(
      queryParameters: (excluirId != null && excluirId.isNotEmpty) ? {'excluirId': excluirId} : null,
    );
    final response = await http.get(
      uri,
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
    errorMsg = _mensajesDeError(data['errors']) ?? errorMsg;
    throw Exception(errorMsg);
  }
}
