import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';
import '../screens/auth/login_screen.dart';
import 'auth_service.dart';
import 'fcm_service.dart';

class ClienteService {
  static bool _isForcingLogout = false;

  /// Si el backend responde 401 (cliente eliminado o desactivado), cierra la sesión activa
  /// y redirige inmediatamente a LoginScreen.
  static Future<void> forzarCierreSesionSiInactivo({String? mensaje}) async {
    if (_isForcingLogout) return;
    final tieneSesion = await AuthService.tieneSesion();
    if (!tieneSesion) return;

    _isForcingLogout = true;
    try {
      await AuthService.logout();

      final nav = FcmService.navigatorKey.currentState;
      if (nav != null) {
        nav.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }

      final messenger = FcmService.scaffoldMessengerKey.currentState;
      if (messenger != null) {
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            content: Text(
              mensaje ??
                  'Tu sesión fue cerrada porque tu cuenta de cliente fue desactivada o eliminada.',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } finally {
      Future.delayed(const Duration(seconds: 2), () {
        _isForcingLogout = false;
      });
    }
  }

  /// Verifica en el servidor si la cuenta del cliente sigue existiendo y activa.
  /// Devuelve `true` si está activa o `false` si fue eliminada/desactivada (y cierra la sesión).
  static Future<bool> verificarEstadoCuentaActiva() async {
    final tieneSesion = await AuthService.tieneSesion();
    if (!tieneSesion) return false;

    final usuario = await AuthService.obtenerUsuario();
    if (usuario == null) return false;

    final rol = (usuario['rol'] ?? '').toString().toUpperCase();
    if (rol != 'CLIENTE' && rol != 'CLIENTES') {
      return true;
    }

    final usuarioId = (usuario['_id'] ?? usuario['id'])?.toString();
    final token = await AuthService.obtenerToken();
    if (usuarioId == null || usuarioId.isEmpty || token == null || token.isEmpty) {
      return false;
    }

    try {
      final response = await http
          .get(
            Uri.parse('${ApiConfig.baseUrl}/clientes/usuario/$usuarioId'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          )
          .timeout(const Duration(seconds: 6));

      if (response.statusCode == 401 || response.statusCode == 404) {
        await forzarCierreSesionSiInactivo();
        return false;
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final cliente = (data is Map && data['data'] is Map)
            ? Map<String, dynamic>.from(data['data'] as Map)
            : null;

        if (cliente == null) {
          await forzarCierreSesionSiInactivo();
          return false;
        }

        final clienteActivo = cliente['estado'] != false;
        final u = cliente['usuario'];
        final usuarioActivo = (u is Map) ? (u['estado'] != false) : true;

        if (!clienteActivo || !usuarioActivo) {
          await forzarCierreSesionSiInactivo();
          return false;
        }
      }
      return true;
    } catch (_) {
      // Ignorar errores de red temporales sin cerrar sesión
      return true;
    }
  }
  // =========================
  // OBTENER TODOS LOS CLIENTES
  // =========================
  static Future<List<dynamic>> getAll() async {
    final token = await AuthService.obtenerToken();
    if (token == null) throw Exception('No hay sesión activa.');

    final response = await ApiConfig.httpClient
        .get(
          Uri.parse('${ApiConfig.baseUrl}/clientes'),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          },
        )
        .timeout(ApiConfig.requestTimeout);

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
    // 1. Consulta directa optimizada por ID de usuario (1 documento) con verificación de cuenta activa
    final token = await AuthService.obtenerToken();
    if (token != null && token.isNotEmpty) {
      try {
        final response = await ApiConfig.httpClient
            .get(
              Uri.parse('${ApiConfig.baseUrl}/clientes/usuario/$usuarioId'),
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              },
            )
            .timeout(ApiConfig.requestTimeout);

        if (response.statusCode == 401 || response.statusCode == 404) {
          await forzarCierreSesionSiInactivo();
          return null;
        }

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is Map && data['success'] == true && data['data'] is Map) {
            final cliente = Map<String, dynamic>.from(data['data'] as Map);
            final clienteActivo = cliente['estado'] != false;
            final u = cliente['usuario'];
            final usuarioActivo = (u is Map) ? (u['estado'] != false) : true;
            if (!clienteActivo || !usuarioActivo) {
              await forzarCierreSesionSiInactivo();
              return null;
            }
            return cliente;
          }
        }
      } catch (_) {}
    }

    // 2. Respaldo si el endpoint directo no estuviera disponible
    try {
      final clientes = await getAll();
      for (final c in clientes) {
        if (c is Map<String, dynamic>) {
          final u = c['usuario'];
          if (u is Map &&
              (u['_id']?.toString() == usuarioId ||
                  u['id']?.toString() == usuarioId)) {
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
