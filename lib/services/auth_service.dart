import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class AuthService {

  // =========================
  // INICIAR SESIÓN
  // =========================

  static Future<Map<String, dynamic>> login(
    String correo,
    String password,
  ) async {

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/mobile-login',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {

      final resultado = data['data'];

      // Guardar sesión
      await guardarSesion(resultado);

      return resultado;
    }

    throw Exception(
      data['message'] ?? 'Error al iniciar sesión.',
    );
  }

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

    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/clientes',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'nombre': nombre,
        'apellido': apellido,
        'tipoDocumento': tipoDocumento,
        'documento': documento,
        'correo': correo,
        'password': password,
        'telefono': telefono,
        'direccion': direccion,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    }

    throw Exception(
      data['message'] ?? 'Error al crear la cuenta.',
    );
  }

  static Future<void> forgotPassword(String correo) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/forgot-password',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'correo': correo,
        'origen': 'mobile',
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      return;
    }

    throw Exception(
      data['message'] ?? 'No se pudo enviar el enlace.',
    );
  }

  static Future<void> resetPassword({
    required String token,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse(
        '${ApiConfig.baseUrl}/auth/reset-password',
      ),
      headers: {
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'token': token,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 &&
        data['success'] == true) {
      return;
    }

    throw Exception(
      data['message'] ??
          'No se pudo restablecer la contraseña.',
    );
  }


  // =========================
  // GUARDAR SESIÓN
  // =========================

  static Future<void> guardarSesion(
    Map<String, dynamic> datos,
  ) async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.setString(
      'token',
      datos['token'],
    );

    await prefs.setString(
      'usuario',
      jsonEncode(datos['usuario']),
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

    if (usuario == null) {
      return null;
    }

    return jsonDecode(usuario);
  }


  // =========================
  // COMPROBAR SESIÓN
  // =========================

  static Future<bool> tieneSesion() async {

    final prefs = await SharedPreferences.getInstance();

    final token = prefs.getString('token');

    return token != null && token.isNotEmpty;
  }

  // =========================
  // CERRAR SESIÓN
  // =========================

  static Future<void> logout() async {

    final prefs = await SharedPreferences.getInstance();

    await prefs.remove('token');
    await prefs.remove('usuario');
  }
}