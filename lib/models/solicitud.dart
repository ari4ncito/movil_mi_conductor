class Solicitud {
  final String? id;
  final String? codigo;
  final String? cliente;
  final String? correoCliente;
  final String? conductorAsignado;
  final String? vehiculo;
  final String? tipoServicio;
  final String? descripcion;
  final String? origen;
  final String? destino;
  final DateTime? fechaProgramada;
  final String? prioridad;
  final String? estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? motivoCancelacion;
  final Map<String, dynamic>? conductorData;
  final Map<String, dynamic>? vehiculoData;

  const Solicitud({
    this.id,
    this.codigo,
    this.cliente,
    this.correoCliente,
    this.conductorAsignado,
    this.vehiculo,
    this.tipoServicio,
    this.descripcion,
    this.origen,
    this.destino,
    this.fechaProgramada,
    this.prioridad,
    this.estado,
    this.createdAt,
    this.updatedAt,
    this.motivoCancelacion,
    this.conductorData,
    this.vehiculoData,
  });

  String? get clienteId => cliente;
  String? get conductorId => conductorAsignado;
  String? get vehiculoId => vehiculo;
  DateTime? get fechaSolicitud => createdAt;
  num? get precio => null;

  factory Solicitud.fromJson(Map<String, dynamic> json) => Solicitud(
    id: _string(json['_id'] ?? json['id']),
    codigo: _string(json['codigo']),
    cliente: _relationId(json['cliente']),
    correoCliente: _string(json['correoCliente']),
    conductorAsignado: _relationId(
      json['conductorAsignado'] ?? json['conductor'],
    ),
    vehiculo: _relationId(json['vehiculo']),
    tipoServicio: _string(json['tipoServicio']),
    descripcion: _string(json['descripcion']),
    origen: _string(json['origen']),
    destino: _string(json['destino']),
    fechaProgramada: _date(json['fechaProgramada']),
    prioridad: _string(json['prioridad']),
    estado: _string(json['estado']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
    motivoCancelacion: _string(json['motivoCancelacion']),
    conductorData: json['conductorAsignado'] is Map ? Map<String, dynamic>.from(json['conductorAsignado']) : 
                   json['conductor'] is Map ? Map<String, dynamic>.from(json['conductor']) : null,
    vehiculoData: json['vehiculo'] is Map ? Map<String, dynamic>.from(json['vehiculo']) : null,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (codigo != null) 'codigo': codigo,
    if (cliente != null) 'cliente': cliente,
    if (correoCliente != null) 'correoCliente': correoCliente,
    if (conductorAsignado != null) 'conductorAsignado': conductorAsignado,
    if (vehiculo != null) 'vehiculo': vehiculo,
    if (tipoServicio != null) 'tipoServicio': tipoServicio,
    if (descripcion != null) 'descripcion': descripcion,
    if (origen != null) 'origen': origen,
    if (destino != null) 'destino': destino,
    if (fechaProgramada != null)
      'fechaProgramada': fechaProgramada!.toIso8601String(),
    if (prioridad != null) 'prioridad': prioridad,
    if (estado != null) 'estado': estado,
    if (motivoCancelacion != null) 'motivoCancelacion': motivoCancelacion,
  };

  static String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return '$value';
    if (value is Map) return _string(value['_id'] ?? value['id']);
    return null;
  }

  static String? _relationId(dynamic value) => _string(value);

  static DateTime? _date(dynamic value) {
    if (value is Map) return _date(value['\$date'] ?? value['date']);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
