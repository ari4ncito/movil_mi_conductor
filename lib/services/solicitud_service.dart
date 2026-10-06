import '../models/solicitud.dart';
import 'http_client.dart';

class SolicitudService {
  final ApiHttpClient client;

  SolicitudService({ApiHttpClient? client})
    : client = client ?? ApiHttpClient();

  Future<List<Solicitud>> listar({
    String? clienteId,
    String? conductorId,
    String? estado,
  }) async {
    final query = <String, String>{
      if (_validId(clienteId)) 'cliente': clienteId!,
      if (_validId(conductorId)) 'conductor': conductorId!,
      if (estado != null && estado.trim().isNotEmpty) 'estado': estado,
    };
    return _list(await client.get('/api/solicitudes/', queryParameters: query));
  }

  Future<Solicitud> obtenerPorId(String id) async {
    _requireId(id);
    return Solicitud.fromJson(_map(await client.get('/api/solicitudes/$id')));
  }

  Future<Solicitud> crearSolicitud(Solicitud solicitud) async {
    return Solicitud.fromJson(
      _map(await client.post('/api/solicitudes/', body: solicitud.toJson())),
    );
  }

  Future<List<Solicitud>> obtenerSolicitudes({
    String? clienteId,
    String? conductorId,
    String? estado,
  }) => listar(
    clienteId: clienteId,
    conductorId: conductorId,
    estado: estado,
  );

  Future<Solicitud> obtenerSolicitudPorId(String id) => obtenerPorId(id);

  Future<Solicitud> asignarConductor(String id, String conductorId) async {
    _requireId(id);
    _requireId(conductorId);
    return Solicitud.fromJson(
      _map(
        await client.patch(
          '/api/solicitudes/$id/asignar-conductor',
          body: {'conductor': conductorId},
        ),
      ),
    );
  }

  Future<Solicitud> cancelar(String id, {String? motivo}) async {
    _requireId(id);
    return Solicitud.fromJson(
      _map(
        await client.patch(
          '/api/solicitudes/$id/cancelar',
          body: {
            if (motivo != null && motivo.trim().isNotEmpty) 'motivo': motivo,
          },
        ),
      ),
    );
  }

  Future<Solicitud> cancelarSolicitud(String id, {String? motivo}) =>
      cancelar(id, motivo: motivo);

  Future<Solicitud> completar(String id) async {
    _requireId(id);
    return Solicitud.fromJson(
      _map(await client.patch('/api/solicitudes/$id/completar')),
    );
  }

  Future<Solicitud> completarSolicitud(String id) => completar(id);

  Future<Solicitud> actualizar(String id, Solicitud solicitud) async {
    _requireId(id);
    return Solicitud.fromJson(
      _map(await client.put('/api/solicitudes/$id', body: solicitud.toJson())),
    );
  }

  Future<Solicitud> actualizarSolicitud(String id, Solicitud solicitud) =>
      actualizar(id, solicitud);

  List<Solicitud> _list(dynamic data) {
    final list = data is List
        ? data
        : data is Map
        ? (data['solicitudes'] ?? data['items'] ?? data['results'])
        : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((item) => Solicitud.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }

  Map<String, dynamic> _map(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const ApiException('El servidor devolvió datos inesperados.');
  }

  static bool _validId(String? id) => id != null && id.trim().isNotEmpty;

  static void _requireId(String id) {
    if (!_validId(id)) throw const ApiException('Se requiere un ID válido.');
  }
}
