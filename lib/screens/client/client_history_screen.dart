import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';
import '../../services/auth_service.dart';
import '../../services/cliente_service.dart';
import 'services/client_driver_tracking_screen.dart';
import 'services/searching_driver_screen.dart';

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

      // Intentar obtener el registro cliente actual para resolver el ID de la entidad Cliente
      String? clienteId = widget.clienteId;
      if (clienteId == null || clienteId.isEmpty) {
        try {
          final clienteData = await ClienteService.obtenerClienteActual();
          if (clienteData != null) {
            clienteId = (clienteData['_id'] ?? clienteData['id'])?.toString();
          }
        } catch (_) {}
      }

      // Consultar solicitudes pasando filtros flexibles
      List<Solicitud> list = [];
      try {
        list = await _service.listar(
          clienteId: clienteId,
          correoCliente: userEmail,
        );
      } catch (_) {
        // Reintentar sin clienteId por si el backend filtra estrictamente por correo
        list = await _service.listar(
          correoCliente: userEmail,
        );
      }

      // Si aún no trae nada pero tenemos el ID de cliente, probar buscando por cliente
      if (list.isEmpty && clienteId != null && clienteId.isNotEmpty) {
        try {
          final byCliente = await _service.listar(clienteId: clienteId);
          if (byCliente.isNotEmpty) {
            list = byCliente;
          }
        } catch (_) {}
      }

      // Filtrar para mostrar las solicitudes que pertenezcan a este cliente
      if (userEmail != null || userId != null || clienteId != null) {
        _solicitudes = list.where((s) {
          // Coincidencia por correo
          if (userEmail != null && s.correoCliente != null) {
            if (s.correoCliente!.toLowerCase().trim() == userEmail) return true;
          }
          // Coincidencia por ID de entidad Cliente
          if (clienteId != null && s.clienteId != null) {
            if (s.clienteId == clienteId) return true;
          }
          if (s.clienteData != null) {
            final cId = s.clienteData?['_id'] ?? s.clienteData?['id'];
            if (cId != null && clienteId != null && cId.toString() == clienteId) {
              return true;
            }
            final cUser = s.clienteData?['usuario'];
            if (cUser != null) {
              final cUserId = (cUser is Map)
                  ? (cUser['_id'] ?? cUser['id'])
                  : cUser;
              if (cUserId?.toString() == userId) return true;
            }
          }
          return false;
        }).toList();

        // Si el filtro estricto resultó vacío pero el backend ya nos devolvió una lista con nuestros parámetros,
        // no descartar las solicitudes recibidas
        if (_solicitudes.isEmpty && list.isNotEmpty) {
          _solicitudes = list;
        }
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
        child: RefreshIndicator(
          onRefresh: _loadSolicitudes,
          color: AppColors.petrol,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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

                const SizedBox(height: 22),

                // Tarjeta de estadística estéticamente diseñada
                _buildStatBanner(
                  icon: Icons.directions_car_rounded,
                  count: _completedCount.toString(),
                  title: 'Viajes Realizados',
                  subtitle: 'Servicios completados exitosamente',
                ),

                const SizedBox(height: 28),

                // Encabezado de la lista
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 40),
                      child: CircularProgressIndicator(color: AppColors.petrol),
                    ),
                  )
                else if (_error != null)
                  _buildStatusMessage(_error!, onRetry: _loadSolicitudes)
                else if (_solicitudes.isEmpty)
                  _buildEmptyState()
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

                const SizedBox(height: 28),
              ],
            ),
          ),
        ),
      ),
    );
  }

  int get _completedCount => _solicitudes
      .where((item) => (item.estado ?? '').toLowerCase().contains('complet'))
      .length;

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 36),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F3D44).withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.petrol.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.directions_car_filled_outlined,
              color: AppColors.petrol,
              size: 28,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Sin viajes registrados aún',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Cuando solicites un conductor, podrás consultar aquí el resumen y detalle de todos tus traslados.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusMessage(String message, {VoidCallback? onRetry}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textSecondary),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Reintentar'),
                style: TextButton.styleFrom(foregroundColor: AppColors.petrol),
              ),
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

  Widget _buildStatBanner({
    required IconData icon,
    required String count,
    required String title,
    required String subtitle,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
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
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF0F3D44).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: Color(0xFF0F3D44),
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF16262D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xFF0F3D44),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              count,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
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
    final estadoStr = (status ?? 'PENDIENTE').replaceAll('_', ' ').toUpperCase();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _mostrarDetallesViaje(solicitud),
        borderRadius: BorderRadius.circular(20),
        child: Container(
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
                          from,
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
                          to,
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
              // Pie de la tarjeta con conductor y estado
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
                    child: const Icon(Icons.drive_eta_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.isNotEmpty ? driver : 'Sin conductor asignado',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF16262D),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (rating > 0)
                          Row(
                            children: [
                              for (int i = 0; i < rating; i++)
                                const Icon(Icons.star_rounded, color: Colors.amber, size: 13),
                              const SizedBox(width: 4),
                              Text(
                                '$rating.0',
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF64748B),
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Conductor Mi Conductor',
                            style: TextStyle(
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
                      estadoStr,
                      style: TextStyle(
                        fontSize: 11,
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
    final estadoStr = (solicitud.estado ?? 'PENDIENTE').replaceAll('_', ' ').toUpperCase();
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

            // Botones de acción (Reanudar viaje si no ha concluido / Cerrar)
            Builder(
              builder: (buttonContext) {
                final est = (solicitud.estado ?? '').toUpperCase();
                final esActiva = est != 'COMPLETADO' &&
                    est != 'COMPLETADA' &&
                    est != 'FINALIZADO' &&
                    est != 'CANCELADO' &&
                    est != 'CANCELADA';

                return Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (esActiva) ...[
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(ctx);
                              if (est == 'PENDIENTE') {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SearchingDriverScreen(solicitud: solicitud),
                                  ),
                                );
                              } else {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ClientDriverTrackingScreen(solicitud: solicitud),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.navigation_rounded, color: Colors.white, size: 20),
                            label: const Text(
                              'Ir a la Solicitud / Viaje en Curso',
                              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 15),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.petrol,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                    ],
                  ),
                );
              },
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
