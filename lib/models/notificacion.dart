class Notificacion {
  final String? id;
  final String? destinatario;
  final String titulo;
  final String mensaje;
  final String tipo;
  final String? solicitudId;
  final String? servicioId;
  final String? novedadId;
  final bool leida;
  final DateTime? fechaLectura;
  final Map<String, dynamic> datosExtra;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const Notificacion({
    this.id,
    this.destinatario,
    required this.titulo,
    required this.mensaje,
    this.tipo = 'SISTEMA',
    this.solicitudId,
    this.servicioId,
    this.novedadId,
    this.leida = false,
    this.fechaLectura,
    this.datosExtra = const {},
    this.createdAt,
    this.updatedAt,
  });

  factory Notificacion.fromJson(Map<String, dynamic> json) {
    return Notificacion(
      id: _string(json['_id'] ?? json['id']),
      destinatario: _relationId(json['destinatario']),
      titulo: _string(json['titulo']) ?? 'Notificación',
      mensaje: _string(json['mensaje']) ?? '',
      tipo: _string(json['tipo'])?.toUpperCase() ?? 'SISTEMA',
      solicitudId: _relationId(json['solicitud']),
      servicioId: _relationId(json['servicio']),
      novedadId: _relationId(json['novedad']),
      leida: json['leida'] == true,
      fechaLectura: _date(json['fechaLectura']),
      datosExtra: json['datosExtra'] is Map
          ? Map<String, dynamic>.from(json['datosExtra'])
          : const {},
      createdAt: _date(json['createdAt']),
      updatedAt: _date(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (destinatario != null) 'destinatario': destinatario,
    'titulo': titulo,
    'mensaje': mensaje,
    'tipo': tipo,
    if (solicitudId != null) 'solicitud': solicitudId,
    if (servicioId != null) 'servicio': servicioId,
    if (novedadId != null) 'novedad': novedadId,
    'leida': leida,
    if (fechaLectura != null) 'fechaLectura': fechaLectura!.toIso8601String(),
    'datosExtra': datosExtra,
    if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
  };

  Notificacion copyWith({
    String? id,
    String? destinatario,
    String? titulo,
    String? mensaje,
    String? tipo,
    String? solicitudId,
    String? servicioId,
    String? novedadId,
    bool? leida,
    DateTime? fechaLectura,
    Map<String, dynamic>? datosExtra,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Notificacion(
      id: id ?? this.id,
      destinatario: destinatario ?? this.destinatario,
      titulo: titulo ?? this.titulo,
      mensaje: mensaje ?? this.mensaje,
      tipo: tipo ?? this.tipo,
      solicitudId: solicitudId ?? this.solicitudId,
      servicioId: servicioId ?? this.servicioId,
      novedadId: novedadId ?? this.novedadId,
      leida: leida ?? this.leida,
      fechaLectura: fechaLectura ?? this.fechaLectura,
      datosExtra: datosExtra ?? this.datosExtra,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static String? _string(dynamic value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return '$value';
    if (value is Map) return _string(value['_id'] ?? value['id']);
    return null;
  }

  static String? _relationId(dynamic value) => _string(value);

  static DateTime? _date(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is Map) return _date(value['\$date'] ?? value['date']);
    if (value is num) return DateTime.fromMillisecondsSinceEpoch(value.toInt());
    return DateTime.tryParse(value.toString());
  }
}

