import 'package:flutter/material.dart';
import '../../models/solicitud.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';

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
      _solicitudes = await _service.listar(clienteId: widget.clienteId);
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
                      icon: Icons.route,
                      value: '—',
                      label: 'Distancia Recorrida',
                      color: AppColors.slate,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.star,
                      value: '—',
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
                      date: _formatDate(
                        solicitud.fechaSolicitud ?? solicitud.createdAt,
                      ),
                      driver: solicitud.conductorId ?? 'Sin conductor asignado',
                      from: solicitud.origen ?? 'Origen no disponible',
                      to: solicitud.destino ?? 'Destino no disponible',
                      rating: 0,
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
            color: AppColors.petrolDark.withValues(alpha: 0.06),
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
              color: color.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.25), width: 1),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
        ],
      ),
    );
  }

  Widget _buildTripCard({
    required String date,
    required String driver,
    required String from,
    required String to,
    required int rating,
    String? status,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withValues(alpha: 0.06),
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
                Text(
                  status,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.accent,
                    fontWeight: FontWeight.w700,
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
                      color: AppColors.petrolDark.withValues(alpha: 0.25),
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
                      'Conductor: $driver',
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
        ],
      ),
    );
  }
}
