import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Servicio para la subida directa de imágenes a Cloudinary usando el preset no firmado (unsigned).
/// Basado en la configuración unificada del proyecto (Cloud Name: tsovzwez, Preset: reportes).
class CloudinaryService {
  static const String cloudName = 'tsovzwez';
  static const String uploadPreset = 'reportes';
  static final Uri uploadUri = Uri.parse(
    'https://api.cloudinary.com/v1_1/$cloudName/image/upload',
  );

  /// Sube un archivo [XFile] a Cloudinary.
  /// Retorna la URL segura (`secure_url`) de la imagen.
  static Future<String> subirImagen(
    XFile archivo, {
    String? folder,
  }) async {
    try {
      final request = http.MultipartRequest('POST', uploadUri);
      request.fields['upload_preset'] = uploadPreset;

      if (folder != null && folder.isNotEmpty) {
        request.fields['folder'] = folder;
      }

      final bytes = await archivo.readAsBytes();
      final nombre = archivo.name.isNotEmpty
          ? archivo.name
          : 'foto_${DateTime.now().millisecondsSinceEpoch}.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: nombre,
        ),
      );

      final streamedResponse = await request
          .send()
          .timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final secureUrl = data['secure_url'] ?? data['url'];
        if (secureUrl != null && secureUrl.toString().isNotEmpty) {
          debugPrint('Cloudinary upload exitoso: $secureUrl');
          return secureUrl.toString();
        }
        throw Exception('Cloudinary no devolvió una URL válida.');
      }

      final errorMsg = data is Map && data['error'] != null
          ? data['error']['message']
          : 'Error HTTP ${response.statusCode} al subir a Cloudinary';
      throw Exception(errorMsg);
    } catch (e) {
      debugPrint('Error en CloudinaryService.subirImagen: $e');
      rethrow;
    }
  }

  /// Sube una lista de archivos [XFile] en paralelo a Cloudinary.
  /// Retorna la lista de URLs seguras generadas.
  static Future<List<String>> subirMultiplesImagenes(
    List<XFile> archivos, {
    String? folder,
  }) async {
    if (archivos.isEmpty) return [];

    final futures = archivos.map(
      (archivo) => subirImagen(archivo, folder: folder),
    );

    return await Future.wait(futures);
  }
}

