import '../models/novedad.dart';
import 'http_client.dart';

class NovedadService {
  final ApiHttpClient client;

  NovedadService({ApiHttpClient? client}) : client = client ?? ApiHttpClient();

  Future<List<Novedad>> listar() async =>
      _list(await client.get('/api/novedades/'));

  Future<List<Novedad>> obtenerNovedades() => listar();

  Future<Novedad> obtenerPorId(String id) async =>
      _one(await client.get('/api/novedades/$id'));

  Future<Novedad> obtenerNovedadPorId(String id) => obtenerPorId(id);

  Future<List<Novedad>> listarPorSolicitud(String id) async =>
      _list(await client.get('/api/novedades/solicitud/$id'));

  Future<List<Novedad>> obtenerNovedadesPorSolicitud(String id) =>
      listarPorSolicitud(id);

  Future<List<Novedad>> listarPorConductor(String id) async =>
      _list(await client.get('/api/novedades/conductor/$id'));

  Future<List<Novedad>> obtenerNovedadesPorConductor(String id) =>
      listarPorConductor(id);

  Future<Novedad> crearNovedad(Novedad novedad) async {
    if (novedad.usuarioRegistroId == null ||
        novedad.usuarioRegistroId!.trim().isEmpty) {
      throw const ApiException(
        'No se puede crear la novedad: falta el ID del usuario que la registra.',
      );
    }
    return _one(await client.post('/api/novedades/', body: novedad.toJson()));
  }

  Future<Novedad> actualizarEstado(String id, String estado) async => _one(
    await client.patch('/api/novedades/$id/estado', body: {'estado': estado}),
  );

  Future<Novedad> cambiarEstadoNovedad(String id, String estado) =>
      actualizarEstado(id, estado);

  Future<Novedad> actualizar(String id, Novedad novedad) async =>
      _one(await client.put('/api/novedades/$id', body: novedad.toJson()));

  Future<Novedad> actualizarNovedad(String id, Novedad novedad) =>
      actualizar(id, novedad);

  Future<void> eliminar(String id) async {
    await client.delete('/api/novedades/$id');
  }

  Future<void> eliminarNovedad(String id) => eliminar(id);

  Novedad _one(dynamic data) {
    if (data is Map) return Novedad.fromJson(Map<String, dynamic>.from(data));
    throw const ApiException('El servidor devolvió datos inesperados.');
  }

  List<Novedad> _list(dynamic data) {
    final list = data is List
        ? data
        : data is Map
        ? (data['novedades'] ?? data['items'] ?? data['results'])
        : null;
    if (list is! List) return const [];
    return list
        .whereType<Map>()
        .map((item) => Novedad.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}
