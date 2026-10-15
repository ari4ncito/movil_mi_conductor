import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

import '../config/api_config.dart';
import 'auth_service.dart';
import 'http_client.dart';

class ServicioService {
  final ApiHttpClient client;

  ServicioService({ApiHttpClient? client})
      : client = client ?? ApiHttpClient();

  /// Obtener el servicio asociado a una solicitud
  Future<Map<String, dynamic>?> obtenerPorSolicitud(String solicitudId) async {
    try {
      final res = await client.get('/servicios/solicitud/$solicitudId');
      if (res is Map<String, dynamic>) {
        return res;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Obtener el servicio por su ID
  Future<Map<String, dynamic>?> obtenerPorId(String servicioId) async {
    final res = await client.get('/servicios/$servicioId');
    if (res is Map<String, dynamic>) {
      return res;
    }
    return null;
  }

  /// Subir evidencias / imágenes del vehículo a Cloudinary a través del backend
  Future<Map<String, dynamic>> subirImagenes({
    required String servicioId,
    required List<XFile> archivos,
  }) async {
    final token = await AuthService.obtenerToken();
    final uri = ApiConfig.uri('/servicios/$servicioId/imagenes');

    final request = http.MultipartRequest('POST', uri);

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    request.headers['Accept'] = 'application/json';

    for (final archivo in archivos) {
      final bytes = await archivo.readAsBytes();
      final nombre = archivo.name.isNotEmpty ? archivo.name : 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';
      request.files.add(
        http.MultipartFile.fromBytes(
          'imagenes',
          bytes,
          filename: nombre,
        ),
      );
    }

    final streamedResponse = await request.send().timeout(ApiConfig.requestTimeout);
    final response = await http.Response.fromStream(streamedResponse);
    final data = jsonDecode(response.body);

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (data is Map<String, dynamic> && data['data'] != null) {
        return data['data'] as Map<String, dynamic>;
      }
      return data as Map<String, dynamic>;
    }

    final msg = data is Map ? data['message'] : null;
    throw ApiException(
      msg?.toString() ?? 'Error al subir las imágenes del vehículo.',
      statusCode: response.statusCode,
    );
  }
}
