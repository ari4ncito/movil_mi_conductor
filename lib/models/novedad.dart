class Novedad {
  final String? id;
  final String? titulo;
  final String? descripcion;
  final String? tipo;
  final String? severidad;
  final String? solicitud;
  final String? conductor;
  final String? usuarioRegistro;
  final String? estadoNovedad;
  final DateTime? fechaCierre;
  final String? observaciones;
  final String? evidenciaUrl;
  final String? estado;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Novedad({
    this.id,
    this.titulo,
    this.descripcion,
    this.tipo,
    this.severidad,
    String? solicitud,
    String? conductor,
    String? usuarioRegistro,
    String? solicitudId,
    String? conductorId,
    String? usuarioRegistroId,
    this.estadoNovedad,
    this.fechaCierre,
    this.observaciones,
    this.evidenciaUrl,
    this.estado,
    this.createdAt,
    this.updatedAt,
  }) : solicitud = solicitud ?? solicitudId,
       conductor = conductor ?? conductorId,
       usuarioRegistro = usuarioRegistro ?? usuarioRegistroId;

  String? get solicitudId => solicitud;
  String? get conductorId => conductor;
  String? get usuarioRegistroId => usuarioRegistro;

  factory Novedad.fromJson(Map<String, dynamic> json) => Novedad(
    id: _string(json['_id'] ?? json['id']),
    titulo: _string(json['titulo']),
    descripcion: _string(json['descripcion']),
    tipo: _string(json['tipo']),
    severidad: _string(json['severidad']),
    solicitud: _relationId(json['solicitud']),
    conductor: _relationId(json['conductor']),
    usuarioRegistro: _relationId(json['usuarioRegistro']),
    estadoNovedad: _string(json['estadoNovedad']),
    fechaCierre: _date(json['fechaCierre']),
    observaciones: _string(json['observaciones']),
    evidenciaUrl: _string(json['evidenciaUrl']),
    estado: _string(json['estado']),
    createdAt: _date(json['createdAt']),
    updatedAt: _date(json['updatedAt']),
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    if (titulo != null) 'titulo': titulo,
    if (descripcion != null) 'descripcion': descripcion,
    if (tipo != null) 'tipo': tipo,
    if (severidad != null) 'severidad': severidad,
    if (solicitud != null) 'solicitud': solicitud,
    if (conductor != null) 'conductor': conductor,
    if (usuarioRegistro != null) 'usuarioRegistro': usuarioRegistro,
    if (estadoNovedad != null) 'estadoNovedad': estadoNovedad,
    if (fechaCierre != null) 'fechaCierre': fechaCierre!.toIso8601String(),
    if (observaciones != null) 'observaciones': observaciones,
    if (evidenciaUrl != null) 'evidenciaUrl': evidenciaUrl,
    if (estado != null) 'estado': estado,
  };

  static String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return '$value';
    if (value is Map) {
      return _string(value['_id'] ?? value['id'] ?? value['nombre']);
    }
    return null;
  }

  static String? _relationId(dynamic value) => _string(value);

  static DateTime? _date(dynamic value) {
    if (value is Map) return _date(value['\$date'] ?? value['date']);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return value == null ? null : DateTime.tryParse(value.toString());
  }
}
