import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';

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

              // Stats Grid
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                childAspectRatio: 1.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildStatCard(
                    icon: Icons.attach_money,
                    value: '—',
                    label: 'Ganancias',
                    color: Colors.green,
                  ),
                  _buildStatCard(
                    icon: Icons.local_taxi,
                    value: _completedCount.toString(),
                    label: 'Viajes Realizados',
                    color: Colors.blue,
                  ),
                  _buildStatCard(
                    icon: Icons.route,
                    value: '—',
                    label: 'Distancia Recorrida',
                    color: Colors.orange,
                  ),
                  _buildStatCard(
                    icon: Icons.star,
                    value: '—',
                    label: 'Calificación Promedio',
                    color: Colors.amber,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Recent Rides Header
              const Text(
                'Viajes Recientes',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
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
                      driverRating: 5.0,
                      status: solicitud.estado,
                    ),
                  ),
                ),
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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 20,
                ),
              ),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
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
  }) {
    final (statusColor, statusBgColor, statusLabel) = _getStatusTheme(status);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
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
            const SizedBox(height: 24),
            const Text(
              'Detalles del Viaje',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              date,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Column(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                      ),
                    ),
                    Container(
                      width: 2,
                      height: 40,
                      color: Colors.grey[300],
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF8A00),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Origen',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        pickup,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Destino',
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      Text(
                        destination,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            const Text(
              'Pasajero',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Color(0xFFF5F7FA),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person, color: Colors.black54),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            driverRating.toString(),
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF12566B),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Cerrar Detalles', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SafeArea(child: SizedBox(height: 16)),
          ],
        ),
      ),
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
  }) {
    final (statusColor, statusBgColor, statusLabel) = _getStatusTheme(status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
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
              Expanded(
                child: Text(
                  date,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () => _showRideDetails(
                  context,
                  date,
                  pickup,
                  destination,
                  driver,
                  driverRating,
                  status: status,
                ),
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F5F7),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF12566B)),
                      SizedBox(width: 4),
                      Text(
                        'Ver detalles',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF12566B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Column(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(width: 2, height: 30, color: Colors.grey[300]),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A00),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pickup,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      destination,
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, width: double.infinity, color: Colors.grey[200]),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF5F7FA),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            driver,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 15),
                              const SizedBox(width: 4),
                              Text(
                                driverRating.toString(),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
