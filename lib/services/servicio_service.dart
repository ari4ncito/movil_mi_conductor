import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import 'cloudinary_service.dart';
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

  /// Subir evidencias / imágenes del vehículo directamente a Cloudinary
  /// y asociarlas al servicio en el backend en MongoDB.
  Future<Map<String, dynamic>> subirImagenes({
    required String servicioId,
    required List<XFile> archivos,
    String? tipo,
  }) async {
    if (archivos.isEmpty) {
      return {'imagenes': <String>[]};
    }

    // 1. Subida directa a Cloudinary (mediante preset unsigned 'reportes')
    final urls = await CloudinaryService.subirMultiplesImagenes(
      archivos,
      folder: 'servicios/evidencias',
    );

    // 2. Asociar las URLs seguras de Cloudinary al servicio en el backend
    Map<String, dynamic> resultado = {
      'imagenes': urls,
      'fotos': urls,
    };

    if (servicioId.isNotEmpty) {
      try {
        final payload = {
          'imagenes': urls,
          if (tipo != null && tipo.isNotEmpty) 'tipo': tipo,
        };
        final res = await client.post(
          '/servicios/$servicioId/imagenes',
          body: payload,
        );
        if (res is Map<String, dynamic>) {
          resultado = res;
        }
      } catch (backendError) {
        debugPrint(
          'Aviso: Imágenes subidas a Cloudinary exitosamente, '
          'pero hubo una advertencia al registrarlas en backend: $backendError',
        );
      }
    }

    return resultado;
  }
}
