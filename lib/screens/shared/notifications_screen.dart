import 'package:flutter/material.dart';

import '../../models/notificacion.dart';
import '../../services/http_client.dart';
import '../../services/notificacion_service.dart';

class NotificationsScreen extends StatefulWidget {
  final NotificacionService? notificacionService;

  const NotificationsScreen({super.key, this.notificacionService});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NotificacionService _service =
      widget.notificacionService ?? NotificacionService();

  List<Notificacion> _notificaciones = const [];
  bool _isLoading = true;
  String? _error;
  bool _soloNoLeidas = false;

  @override
  void initState() {
    super.initState();
    _cargarNotificaciones();
  }

  Future<void> _cargarNotificaciones() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await _service.listar(
        page: 1,
        limit: 50,
        leida: _soloNoLeidas ? false : null,
      );
      if (mounted) {
        setState(() {
          _notificaciones = items;
          _isLoading = false;
        });
      }
    } on ApiException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'No se pudieron cargar las notificaciones.';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _marcarComoLeida(Notificacion notificacion) async {
    if (notificacion.leida || notificacion.id == null) return;

    try {
      await _service.marcarComoLeida(notificacion.id!);
      setState(() {
        _notificaciones = _notificaciones.map((n) {
          if (n.id == notificacion.id) {
            return n.copyWith(leida: true, fechaLectura: DateTime.now());
          }
          return n;
        }).toList();
      });
    } catch (_) {
      // Ignorar fallo silencioso de red al marcar leída
    }
  }

  Future<void> _marcarTodasComoLeidas() async {
    try {
      await _service.marcarTodasComoLeidas();
      setState(() {
        _notificaciones = _notificaciones
            .map((n) => n.copyWith(leida: true, fechaLectura: DateTime.now()))
            .toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Todas las notificaciones fueron marcadas como leídas'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No se pudieron marcar todas como leídas'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  int get _cantidadNoLeidas =>
      _notificaciones.where((n) => !n.leida).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_rounded,
            color: Color(0xFF19535F),
            size: 20,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Notificaciones',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Color(0xFF19535F),
          ),
        ),
        actions: [
          if (_cantidadNoLeidas > 0)
            TextButton.icon(
              onPressed: _marcarTodasComoLeidas,
              icon: const Icon(Icons.done_all_rounded, size: 18, color: Color(0xFFFF8A00)),
              label: const Text(
                'Marcar leídas',
                style: TextStyle(
                  color: Color(0xFFFF8A00),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filtros rápidos
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: Colors.white,
              child: Row(
                children: [
                  ChoiceChip(
                    label: const Text('Todas'),
                    selected: !_soloNoLeidas,
                    selectedColor: const Color(0xFF19535F),
                    labelStyle: TextStyle(
                      color: !_soloNoLeidas ? Colors.white : const Color(0xFF19535F),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (!_soloNoLeidas) return;
                      setState(() => _soloNoLeidas = false);
                      _cargarNotificaciones();
                    },
                  ),
                  const SizedBox(width: 8),
                  ChoiceChip(
                    label: Text(
                      _cantidadNoLeidas > 0
                          ? 'No leídas ($_cantidadNoLeidas)'
                          : 'No leídas',
                    ),
                    selected: _soloNoLeidas,
                    selectedColor: const Color(0xFF19535F),
                    labelStyle: TextStyle(
                      color: _soloNoLeidas ? Colors.white : const Color(0xFF19535F),
                      fontWeight: FontWeight.w600,
                    ),
                    onSelected: (val) {
                      if (_soloNoLeidas) return;
                      setState(() => _soloNoLeidas = true);
                      _cargarNotificaciones();
                    },
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFE5E7EB)),

            // Lista de Notificaciones
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFFF8A00),
                onRefresh: _cargarNotificaciones,
                child: _buildBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(color: Color(0xFFFF8A00)),
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline_rounded, size: 52, color: Colors.redAccent),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black87),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF19535F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _cargarNotificaciones,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_notificaciones.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 64),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF19535F).withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_off_outlined,
                  size: 40,
                  color: Color(0xFF19535F),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                _soloNoLeidas
                    ? 'No tienes notificaciones pendientes por leer.'
                    : 'Aún no tienes notificaciones.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF19535F),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Aquí recibirás actualizaciones sobre tus servicios y solicitudes en tiempo real.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: _notificaciones.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final notificacion = _notificaciones[index];
        return _buildNotificationCard(notificacion);
      },
    );
  }

  Widget _buildNotificationCard(Notificacion notificacion) {
    final meta = _obtenerMetaTipo(notificacion.tipo);
    final esNoLeida = !notificacion.leida;

    return InkWell(
      onTap: () {
        _marcarComoLeida(notificacion);
        _mostrarDetalleModal(notificacion, meta);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: esNoLeida ? const Color(0xFFF0F7F9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: esNoLeida
                ? const Color(0xFF19535F).withOpacity(0.3)
                : const Color(0xFFE5E7EB),
            width: esNoLeida ? 1.5 : 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icono con indicador
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: meta.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(meta.icon, color: meta.color, size: 24),
                ),
                if (esNoLeida)
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8A00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 14),

            // Contenido
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notificacion.titulo,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: esNoLeida ? FontWeight.w800 : FontWeight.w600,
                            color: const Color(0xFF16262D),
                          ),
                        ),
                      ),
                      Text(
                        _formatearFecha(notificacion.createdAt ?? notificacion.updatedAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    notificacion.mensaje,
                    style: TextStyle(
                      fontSize: 13.5,
                      color: esNoLeida ? const Color(0xFF333333) : Colors.grey[600],
                      height: 1.35,
                    ),
                  ),
                  if (notificacion.solicitudId != null ||
                      notificacion.servicioId != null ||
                      notificacion.novedadId != null) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.touch_app_rounded, size: 14, color: meta.color),
                        const SizedBox(width: 4),
                        Text(
                          'Toca para ver detalles',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: meta.color,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarDetalleModal(Notificacion notificacion, _TipoMeta meta) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: meta.color.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(meta.icon, color: meta.color, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notificacion.titulo,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF16262D),
                          ),
                        ),
                        Text(
                          _formatearFecha(notificacion.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                notificacion.mensaje,
                style: const TextStyle(fontSize: 14.5, height: 1.4, color: Colors.black87),
              ),
              if (notificacion.solicitudId != null) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F7F8),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'ID de Solicitud: ${notificacion.solicitudId}',
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: Color(0xFF19535F)),
                  ),
                ),
              ],
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF19535F),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cerrar', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  _TipoMeta _obtenerMetaTipo(String tipo) {
    switch (tipo.toUpperCase()) {
      case 'SOLICITUD_CREADA':
        return _TipoMeta(
          icon: Icons.add_task_rounded,
          color: const Color(0xFF2E7D32),
        );
      case 'SERVICIO_ASIGNADO':
        return _TipoMeta(
          icon: Icons.assignment_ind_rounded,
          color: const Color(0xFF1565C0),
        );
      case 'CONDUCTOR_EN_CAMINO':
        return _TipoMeta(
          icon: Icons.directions_car_filled_rounded,
          color: const Color(0xFFFF8A00),
        );
      case 'SERVICIO_COMPLETADO':
        return _TipoMeta(
          icon: Icons.check_circle_rounded,
          color: const Color(0xFF2E7D32),
        );
      case 'SOLICITUD_CANCELADA':
        return _TipoMeta(
          icon: Icons.cancel_rounded,
          color: const Color(0xFFC62828),
        );
      case 'NOVEDAD_REPORTADA':
        return _TipoMeta(
          icon: Icons.warning_amber_rounded,
          color: const Color(0xFFE65100),
        );
      default:
        return _TipoMeta(
          icon: Icons.notifications_rounded,
          color: const Color(0xFF19535F),
        );
    }
  }

  String _formatearFecha(DateTime? date) {
    if (date == null) return '';
    final local = date.toLocal();
    final ahora = DateTime.now();
    final diferencia = ahora.difference(local);

    if (diferencia.inMinutes < 1) return 'Hace un momento';
    if (diferencia.inMinutes < 60) return 'Hace ${diferencia.inMinutes}m';
    if (diferencia.inHours < 24) return 'Hace ${diferencia.inHours}h';
    if (diferencia.inDays == 1) return 'Ayer';
    if (diferencia.inDays < 7) return 'Hace ${diferencia.inDays}d';

    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/${local.year}';
  }
}

class _TipoMeta {
  final IconData icon;
  final Color color;

  _TipoMeta({required this.icon, required this.color});
}
