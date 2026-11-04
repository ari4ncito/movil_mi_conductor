import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';
import '../../services/auth_service.dart';

// ============================================================
// PALETA DE COLORES — Azul Petróleo (misma paleta del proyecto)
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

class ClientHistoryScreen extends StatefulWidget {
  final String? clienteId;
  final SolicitudService? solicitudService;

  const ClientHistoryScreen({super.key, this.clienteId, this.solicitudService});

  @override
  State<ClientHistoryScreen> createState() => _ClientHistoryScreenState();
}

class _ClientHistoryScreenState extends State<ClientHistoryScreen> {
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
      final usuario = await AuthService.obtenerUsuario();
      final userEmail = usuario?['correo']?.toString().toLowerCase().trim();
      final userId = usuario?['id']?.toString() ?? usuario?['_id']?.toString();

      final list = await _service.listar(
        clienteId: widget.clienteId,
        correoCliente: userEmail,
      );

      // Filtrar estrictamente para mostrar solo las solicitudes asociadas al usuario actual
      if (userEmail != null || userId != null) {
        _solicitudes = list.where((s) {
          if (userEmail != null && s.correoCliente != null) {
            if (s.correoCliente!.toLowerCase().trim() == userEmail) return true;
          }
          final cUser = s.clienteData?['usuario'];
          if (cUser != null) {
            final cUserId = (cUser is Map)
                ? (cUser['_id'] ?? cUser['id'])
                : cUser;
            if (cUserId?.toString() == userId) return true;
          }
          if (widget.clienteId != null && s.clienteId == widget.clienteId) {
            return true;
          }
          return false;
        }).toList();
      } else {
        _solicitudes = list;
      }
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'No se pudo cargar el historial.';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              const Text(
                'Historial de\nServicios',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petrolDark,
                  letterSpacing: 0.2,
                ),
              ),

              const SizedBox(height: 8),

              const Text(
                'Viajes realizados y pedidos anteriores',
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),

              const SizedBox(height: 24),

              // Tarjetas de estadísticas
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.check_circle_outline,
                      value: _completedCount.toString(),
                      label: 'Servicios Completados',
                      color: AppColors.petrol,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.directions_car,
                      value: _solicitudes.length.toString(),
                      label: 'Viajes',
                      color: AppColors.petrolLight,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      value: '5.0 ★',
                      label: 'Calificación Promedio',
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 28),

              // Lista de viajes
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),

                  const SizedBox(width: 8),

                  const Text(
                    'Viajes Recientes',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
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
                _buildStatusMessage('Aún no tienes solicitudes registradas.')
              else
                ..._solicitudes.map(
                  (solicitud) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildTripCard(
                      solicitud: solicitud,
                      date: _formatDate(
                        solicitud.fechaSolicitud ?? solicitud.createdAt,
                      ),
                      driver: solicitud.conductorNombre,
                      from: solicitud.origen ?? 'Origen no disponible',
                      to: solicitud.destino ?? 'Destino no disponible',
                      rating: solicitud.calificacionConductor ?? 0,
                      status: solicitud.estado,
                    ),
                  ),
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  int get _completedCount => _solicitudes
      .where((item) => (item.estado ?? '').toLowerCase().contains('complet'))
      .length;

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
        '${local.month.toString().padLeft(2, '0')}/${local.year} '
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard({
    required Solicitud solicitud,
    required String date,
    required String driver,
    required String from,
    required String to,
    required int rating,
    String? status,
  }) {
    final statusColor = _obtenerColorEstado(status);
    final statusBgColor = _obtenerFondoEstado(status);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarDetallesViaje(solicitud),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.cardBackground,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.petrolDark.withOpacity(0.06),
                blurRadius: 12,
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
                  Flexible(
                    child: Text(
                      date,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (status != null && status.trim().isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusBgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: statusColor.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10.5,
                          color: statusColor,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.petrolLight, AppColors.petrolDark],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.petrolDark.withOpacity(0.25),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.drive_eta,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver == 'Sin conductor asignado' || driver.isEmpty
                              ? 'Sin conductor asignado'
                              : 'Conductor: $driver',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),

                        const SizedBox(height: 4),

                        Row(
                          children: [
                            for (int i = 0; i < 5; i++)
                              Padding(
                                padding: const EdgeInsets.only(right: 2),
                                child: Icon(
                                  Icons.star,
                                  color: i < rating
                                      ? AppColors.accent
                                      : Colors.grey[300],
                                  size: 16,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Container(width: double.infinity, height: 1, color: AppColors.border),

              const SizedBox(height: 16),

              // Ruta
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Column(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.petrolLight,
                          shape: BoxShape.circle,
                        ),
                      ),

                      Container(width: 2, height: 24, color: AppColors.border),

                      Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          from,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          to,
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Botón Ver Detalle
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  InkWell(
                    onTap: () => _mostrarDetallesViaje(solicitud),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: AppColors.petrol.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.petrol.withOpacity(0.18),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.visibility_outlined,
                            size: 16,
                            color: AppColors.petrol,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Ver detalle',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.petrol,
                            ),
                          ),
                        ],
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

  void _mostrarDetallesViaje(Solicitud solicitud) {
    final statusColor = _obtenerColorEstado(solicitud.estado);
    final statusBgColor = _obtenerFondoEstado(solicitud.estado);
    final estadoStr = (solicitud.estado ?? 'PENDIENTE').toUpperCase();
    final fechaStr = _formatDate(solicitud.fechaSolicitud ?? solicitud.createdAt);
    final fechaProgStr = solicitud.fechaProgramada != null
        ? _formatDate(solicitud.fechaProgramada)
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
            // Handle bar
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
                          solicitud.codigo ?? 'Solicitud sin código',
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
                                  solicitud.origen ?? 'No especificado',
                                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                                ),
                                const SizedBox(height: 16),
                                if (solicitud.destinoInicial != null &&
                                    solicitud.destinoInicial!.isNotEmpty &&
                                    solicitud.destinoInicial != solicitud.destino) ...[
                                  const Text(
                                    'DESTINO INICIAL (RUTA PROGRAMADA)',
                                    style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    solicitud.destinoInicial!,
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
                                    solicitud.destino ?? 'No especificado',
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  ),
                                  if (solicitud.cambioRuta != null && solicitud.cambioRuta?['motivo'] != null) ...[
                                    const SizedBox(height: 4),
                                    Text(
                                      'Motivo: ${solicitud.cambioRuta!['motivo']}',
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
                                    solicitud.destino ?? 'No especificado',
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

                    // Conductor
                    _buildDetailSectionTitle('CONDUCTOR ASIGNADO', Icons.person_pin_rounded),
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
                            child: const Icon(Icons.drive_eta, color: Colors.white, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  solicitud.conductorNombre,
                                  style: const TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  solicitud.conductorAsignado != null
                                      ? 'Conductor profesional registrado'
                                      : 'Pendiente por asignación de conductor',
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

                    // Datos del servicio
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
                            solicitud.tipoServicio ?? 'Estándar',
                            Icons.category_outlined,
                          ),
                          const Divider(height: 16, color: AppColors.border),
                          _buildDetailRow(
                            'Prioridad',
                            solicitud.prioridad ?? 'MEDIA',
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
                          if (solicitud.descripcion != null && solicitud.descripcion!.trim().isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildDetailRow(
                              'Notas / Descripción',
                              solicitud.descripcion!.trim(),
                              Icons.notes_rounded,
                            ),
                          ],
                          if (solicitud.motivoCancelacion != null && solicitud.motivoCancelacion!.trim().isNotEmpty) ...[
                            const Divider(height: 16, color: AppColors.border),
                            _buildDetailRow(
                              'Motivo de cancelación',
                              solicitud.motivoCancelacion!.trim(),
                              Icons.cancel_outlined,
                              valueColor: Colors.redAccent,
                            ),
                          ],
                        ],
                      ),
                    ),

                    if (solicitud.calificacionConductor != null || (solicitud.comentarioCliente != null && solicitud.comentarioCliente!.isNotEmpty)) ...[
                      const SizedBox(height: 20),
                      _buildDetailSectionTitle('TU CALIFICACIÓN AL CONDUCTOR', Icons.star_rate_rounded),
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
                            if (solicitud.calificacionConductor != null)
                              Row(
                                children: [
                                  for (int i = 0; i < 5; i++)
                                    Padding(
                                      padding: const EdgeInsets.only(right: 2),
                                      child: Icon(
                                        Icons.star_rounded,
                                        color: i < solicitud.calificacionConductor!
                                            ? AppColors.accent
                                            : Colors.grey[300],
                                        size: 20,
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '${solicitud.calificacionConductor}.0 estrellas',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.petrol,
                                    ),
                                  ),
                                ],
                              ),
                            if (solicitud.comentarioCliente != null && solicitud.comentarioCliente!.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '"${solicitud.comentarioCliente}"',
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

                    if (solicitud.comentarioConductor != null && solicitud.comentarioConductor!.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _buildDetailSectionTitle('OBSERVACIÓN DEL CONDUCTOR', Icons.comment_rounded),
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
                          '"${solicitud.comentarioConductor}"',
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
}
