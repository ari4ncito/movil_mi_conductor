import '../models/notificacion.dart';
import 'http_client.dart';

class NotificacionService {
  final ApiHttpClient client;

  NotificacionService({ApiHttpClient? client})
      : client = client ?? ApiHttpClient();

  /// Registra el token FCM del dispositivo en el backend.
  Future<Map<String, dynamic>> registrarDispositivo({
    required String token,
    String plataforma = 'FLUTTER_ANDROID',
  }) async {
    final response = await client.post(
      '/notificaciones/dispositivos',
      body: {
        'token': token.trim(),
        'plataforma': plataforma.trim().toUpperCase(),
      },
    );
    if (response is Map<String, dynamic>) {
      return response;
    }
    return {'registrado': true};
  }

  /// Desvincula el token FCM del usuario en el backend al cerrar sesión.
  Future<void> desvincularDispositivo({required String token}) async {
    if (token.trim().isEmpty) return;
    try {
      await client.delete(
        '/notificaciones/dispositivos',
        body: {'token': token.trim()},
      );
    } catch (_) {
      // Si el servidor falla o no hay conexión, permitimos continuar sin bloquear
    }
  }

  /// Obtiene la lista paginada de notificaciones del usuario.
  Future<List<Notificacion>> listar({
    int page = 1,
    int limit = 30,
    bool? leida,
  }) async {
    final query = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      if (leida != null) 'leida': leida ? 'true' : 'false',
    };

    final response = await client.get(
      '/notificaciones/',
      queryParameters: query,
    );

    return _parseList(response);
  }

  /// Obtiene la cantidad de notificaciones no leídas.
  Future<int> obtenerContadorNoLeidas() async {
    try {
      final response = await client.get('/notificaciones/no-leidas');
      if (response is Map) {
        final count = response['noLeidas'] ?? response['total'] ?? response['count'];
        if (count is num) return count.toInt();
      }
    } catch (_) {}
    return 0;
  }

  /// Marca una notificación como leída por su ID.
  Future<Notificacion> marcarComoLeida(String id) async {
    final response = await client.patch('/notificaciones/$id/leida');
    if (response is Map<String, dynamic>) {
      return Notificacion.fromJson(response);
    }
    throw const ApiException('Respuesta inesperada al marcar como leída.');
  }

  /// Marca todas las notificaciones del usuario como leídas.
  Future<void> marcarTodasComoLeidas() async {
    await client.patch('/notificaciones/leidas');
  }

  List<Notificacion> _parseList(dynamic data) {
    if (data == null) return const [];
    List? items;
    if (data is List) {
      items = data;
    } else if (data is Map) {
      items = data['data'] ?? data['items'] ?? data['notificaciones'];
    }

    if (items is! List) return const [];
    return items
        .whereType<Map>()
        .map((item) => Notificacion.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

