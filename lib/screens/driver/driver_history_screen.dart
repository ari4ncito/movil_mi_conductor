import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';

// ============================================================
// PALETA DE COLORES — Misma paleta del proyecto (Cliente)
// ============================================================

class AppColors {
  static const Color petrol = Color(0xFF0F3D44);
  static const Color petrolDark = Color(0xFF0A2A30);
  static const Color petrolLight = Color(0xFF1B5A63);
  static const Color slate = Color(0xFF334A52);
  static const Color background = Color(0xFFF2F5F6);
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFDDE4E6);
  static const Color textPrimary = Color(0xFF1C2B2F);
  static const Color textSecondary = Color(0xFF6B7C80);
  static const Color accent = Color(0xFFE8862E);
}

class DriverHistoryScreen extends StatefulWidget {
  final String? conductorId;
  final SolicitudService? solicitudService;

  const DriverHistoryScreen({
    super.key,
    this.conductorId,
    this.solicitudService,
  });

  @override
  State<DriverHistoryScreen> createState() => _DriverHistoryScreenState();
}

class _DriverHistoryScreenState extends State<DriverHistoryScreen> {
  late final SolicitudService _service =
      widget.solicitudService ?? SolicitudService();
  List<Solicitud> _solicitudes = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSolicitudes();
  }

  Future<void> _loadSolicitudes() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      String? condId = widget.conductorId;
      if (condId == null) {
        final usuario = await AuthService.obtenerUsuario();
        final usuarioId = usuario?['_id'] ?? usuario?['id'];
        if (usuarioId != null) {
          final conductor = await ConductorService.obtenerPorUsuario(usuarioId.toString());
          condId = conductor['_id']?.toString() ?? conductor['id']?.toString();
        }
      }
      final all = await _service.listar(conductorId: condId);
      if (condId != null) {
        _solicitudes = all.where((s) => s.conductorId == condId).toList();
      } else {
        _solicitudes = all;
      }
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'No se pudo cargar el historial.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int get _completedCount => _solicitudes
      .where((item) => (item.estado ?? '').toLowerCase().contains('complet'))
      .length;

  String get _calificacionPromedio {
    final calificaciones = _solicitudes
        .map((s) => s.calificacionConductor)
        .where((c) => c != null && c > 0)
        .cast<int>()
        .toList();
    if (calificaciones.isEmpty) return '—';
    final promedio =
        calificaciones.reduce((a, b) => a + b) / calificaciones.length;
    return promedio.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              const Text(
                'Historial de Servicios',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 24),

              // Tarjetas de estadísticas: Viajes Realizados y Calificación Promedio
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.local_taxi,
                      value: _completedCount.toString(),
                      label: 'Viajes Realizados',
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      value: _calificacionPromedio,
                      label: 'Calificación Promedio',
                      color: Colors.amber,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Rides Header
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Viajes Recientes',
                    style: TextStyle(
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildStatusMessage(_error!, onRetry: _loadSolicitudes)
              else if (_solicitudes.isEmpty)
                _buildStatusMessage('Aún no tienes servicios registrados.')
              else
                ..._solicitudes.map(
                  (solicitud) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildRideCard(
                      context,
                      date: _formatDate(
                        solicitud.fechaSolicitud ?? solicitud.createdAt,
                      ),
                      pickup: solicitud.origen ?? 'Origen no disponible',
                      destination: solicitud.destino ?? 'Destino no disponible',
                      driver: solicitud.clienteNombre,
                      driverRating: (solicitud.calificacionConductor ?? 5).toDouble(),
                      status: solicitud.estado,
                      solicitud: solicitud,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusMessage(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton(onPressed: onRetry, child: const Text('Reintentar')),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'Fecha no disponible';
    final local = date.toLocal();
    return '${local.day.toString().padLeft(2, '0')}/'
        '${local.month.toString().padLeft(2, '0')}/'
        '${local.year} '
        '${local.hour.toString().padLeft(2, '0')}:'
        '${local.minute.toString().padLeft(2, '0')}';
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D44).withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF16262D),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _obtenerColorEstado(String? estado) {
    switch ((estado ?? '').toUpperCase()) {
      case 'COMPLETADO':
      case 'COMPLETADA':
      case 'FINALIZADO':
        return const Color(0xFF2E7D32);
      case 'EN_PROCESO':
        return const Color(0xFFE65100);
      case 'CANCELADO':
      case 'CANCELADA':
        return const Color(0xFFC62828);
      case 'PENDIENTE':
      default:
        return const Color(0xFF1565C0);
    }
  }

  Color _obtenerFondoEstado(String? estado) {
    switch ((estado ?? '').toUpperCase()) {
      case 'COMPLETADO':
      case 'COMPLETADA':
      case 'FINALIZADO':
        return const Color(0xFFE8F5E9);
      case 'EN_PROCESO':
        return const Color(0xFFFFF3E0);
      case 'CANCELADO':
      case 'CANCELADA':
        return const Color(0xFFFFEBEE);
      case 'PENDIENTE':
      default:
        return const Color(0xFFE3F2FD);
    }
  }

  (Color, Color, String) _getStatusTheme(String? status) {
    final s = (status ?? '').trim().toUpperCase();
    if (s.contains('COMPLET')) {
      return (const Color(0xFF2E7D32), const Color(0xFFE8F9F0), 'Completado');
    } else if (s.contains('CANCEL')) {
      return (const Color(0xFFC62828), const Color(0xFFFFEBEE), 'Cancelado');
    } else if (s.contains('PROCES') || s.contains('CURSO')) {
      return (const Color(0xFF0277BD), const Color(0xFFE1F5FE), 'En proceso');
    } else if (s.contains('PENDIENT')) {
      return (const Color(0xFFEF6C00), const Color(0xFFFFF3E0), 'Pendiente');
    } else if (status != null && status.trim().isNotEmpty) {
      return (const Color(0xFF546E7A), const Color(0xFFECEFF1), status);
    }
    return (const Color(0xFF546E7A), const Color(0xFFECEFF1), 'Sin estado');
  }

  void _showRideDetails(
    BuildContext context,
    String date,
    String pickup,
    String destination,
    String driver,
    double driverRating, {
    String? status,
    Solicitud? solicitud,
  }) {
    final sol = solicitud ??
        Solicitud(
          origen: pickup,
          destino: destination,
          estado: status,
        );

    final statusColor = _obtenerColorEstado(sol.estado);
    final statusBgColor = _obtenerFondoEstado(sol.estado);
    final estadoStr = (sol.estado ?? 'PENDIENTE').toUpperCase();
    final fechaStr = _formatDate(sol.fechaSolicitud ?? sol.createdAt);
    final fechaProgStr = sol.fechaProgramada != null
        ? _formatDate(sol.fechaProgramada)
        : null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Barra de agarre
            const SizedBox(height: 12),
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),

            // Encabezado
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.petrol.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      color: AppColors.petrol,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Detalle del Viaje',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          sol.codigo ?? 'Solicitud sin código',
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: statusColor.withOpacity(0.3)),
                    ),
                    child: Text(
                      estadoStr,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),
            const Divider(height: 1, color: AppColors.border),

            // Contenido desplazable
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Ruta
                    _buildDetailSectionTitle('RUTA DEL SERVICIO', Icons.alt_route_rounded),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              const Icon(Icons.radio_button_checked, size: 18, color: AppColors.petrolLight),
                              Container(width: 2, height: 32, color: AppColors.border),
                              const Icon(Icons.location_on, size: 20, color: AppColors.accent),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'PUNTO DE RECOGIDA (ORIGEN)',
                                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sol.origen ?? pickup,
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 16),
                                if (sol.destinoInicial != null &&
                                    sol.destinoInicial!.isNotEmpty &&
                                    sol.destinoInicial != sol.destino) ...[
                                  const Text(
                                    'DESTINO INICIAL (RUTA PROGRAMADA)',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sol.destinoInicial!,
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.grey.shade600, decoration: TextDecoration.lineThrough),
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      const Text(
                                        'NUEVO DESTINO (CAMBIO DE RUTA)',
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.accent),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                        decoration: BoxDecoration(color: AppColors.accent.withOpacity(0.12), borderRadius: BorderRadius.circular(4)),
                                        child: const Text('REGISTRADO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: AppColors.accent)),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sol.destino ?? destination,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  if (sol.cambioRuta != null && sol.cambioRuta?['motivo'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Motivo: ${sol.cambioRuta!['motivo']}',
                                      style: const TextStyle(fontSize: 11, fontStyle: FontStyle.italic, color: Color(0xFFC2410C)),
                                    ),
                                  ],
                                ] else ...[
                                  const Text(
                                    'PUNTO DE LLEGADA (DESTINO)',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    sol.destino ?? destination,
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Cliente / Pasajero
                    _buildDetailSectionTitle('CLIENTE / PASAJERO', Icons.person_pin_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.petrolLight, AppColors.petrolDark],
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.person, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  sol.clienteNombre.isNotEmpty ? sol.clienteNombre : driver,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  sol.correoCliente != null && sol.correoCliente!.isNotEmpty
                                      ? sol.correoCliente!
                                      : 'Pasajero asignado',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Información Adicional
                    _buildDetailSectionTitle('INFORMACIÓN ADICIONAL', Icons.info_outline_rounded),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _buildDetailRow(
                            'Tipo de servicio',
                            sol.tipoServicio ?? 'Estándar',
                            Icons.category_outlined,
                          ),
                          const Divider(height: 16, color: AppColors.border),
                          _buildDetailRow(
                            'Prioridad',
                            sol.prioridad ?? 'MEDIA',
                            Icons.flag_outlined,
                          ),
                          const Divider(height: 16, color: AppColors.border),
                          _buildDetailRow(
                            'Fecha de solicitud',
                            fechaStr,
                            Icons.calendar_today_outlined,
                          ),
                          if (fechaProgStr != null) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildDetailRow(
                              'Fecha programada',
                              fechaProgStr,
                              Icons.schedule_rounded,
                            ),
                          ],
                          if (sol.descripcion != null && sol.descripcion!.trim().isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildDetailRow(
                              'Notas / Descripción',
                              sol.descripcion!.trim(),
                              Icons.notes_rounded,
                            ),
                          ],
                          if (sol.motivoCancelacion != null && sol.motivoCancelacion!.trim().isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildDetailRow(
                              'Motivo de cancelación',
                              sol.motivoCancelacion!.trim(),
                              Icons.cancel_outlined,
                              valueColor: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (sol.calificacionConductor != null || (sol.comentarioCliente != null && sol.comentarioCliente!.isNotEmpty)) ...[
                      const SizedBox(height: 20),
                      _buildDetailSectionTitle('CALIFICACIÓN RECIBIDA DEL CLIENTE', Icons.star_rate_rounded),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (sol.calificacionConductor != null)
                              Row(
                                children: [
                                  for (int i = 0; i < 5; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: i < sol.calificacionConductor!
                                            ? AppColors.accent
                                            : Colors.grey[300],
                                        size: 20,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${sol.calificacionConductor}.0 estrellas',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.petrol,
                                    ),
                                  ),
                                ],
                              ),
                            if (sol.comentarioCliente != null && sol.comentarioCliente!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${sol.comentarioCliente}"',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    if (sol.comentarioConductor != null && sol.comentarioConductor!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSectionTitle('TU OBSERVACIÓN DEL SERVICIO', Icons.comment_rounded),
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(
                          '"${sol.comentarioConductor}"',
                          style: const TextStyle(
                            fontSize: 13,
                            fontStyle: FontStyle.italic,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Botón de cerrar
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petrol,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Cerrar',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.petrol),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w800,
            color: AppColors.petrol,
            letterSpacing: 0.8,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13.5,
                  color: valueColor ?? AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRideCard(
    BuildContext context, {
    required String date,
    required String pickup,
    required String destination,
    required String driver,
    required double driverRating,
    String? status,
    Solicitud? solicitud,
  }) {
    final (statusColor, statusBgColor, statusLabel) = _getStatusTheme(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showRideDetails(
          context,
          date,
          pickup,
          destination,
          driver,
          driverRating,
          status: status,
          solicitud: solicitud,
        ),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0F3D44).withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header de tarjeta con fecha y botón 'Ver detalles'
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: Color(0xFF64748B),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.petrol.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.petrol.withOpacity(0.12)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.visibility_rounded, size: 14, color: AppColors.petrol),
                        SizedBox(width: 5),
                        Text(
                          'Ver detalles',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.petrol,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Timeline de la ruta
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      const Icon(
                        Icons.radio_button_checked,
                        color: Color(0xFF10B981),
                        size: 16,
                      ),
                      Container(
                        width: 2,
                        height: 26,
                        color: const Color(0xFFCBD5E1),
                      ),
                      const Icon(
                        Icons.location_on_rounded,
                        color: Color(0xFFFF8A00),
                        size: 18,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pickup,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 14),
                        Text(
                          destination,
                          style: const TextStyle(
                            fontSize: 13.5,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1E293B),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Divider(height: 1, color: Color(0xFFF1F5F9)),
              const SizedBox(height: 14),
              // Pie de la tarjeta con pasajero y estado
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1B5A63), Color(0xFF0F3D44)],
                      ),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16262D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (solicitud?.calificacionConductor != null)
                          Row(
                            children: [
                              for (int i = 0; i < (solicitud!.calificacionConductor ?? 0); i++)
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '.0',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            solicitud?.correoCliente ?? 'Pasajero',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: Color(0xFF64748B),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: statusBgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: statusColor.withOpacity(0.25)),
                    ),
                    child: Text(
                      statusLabel,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}