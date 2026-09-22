import 'package:flutter/material.dart';
import '../../models/novedad.dart';
import '../../services/http_client.dart';
import '../../services/novedad_service.dart';

class NotificationsScreen extends StatefulWidget {
  final NovedadService? novedadService;

  const NotificationsScreen({super.key, this.novedadService});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late final NovedadService _service =
      widget.novedadService ?? NovedadService();
  List<Novedad> _novedades = const [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadNovedades();
  }

  Future<void> _loadNovedades() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      _novedades = await _service.listar();
    } on ApiException catch (error) {
      _error = error.message;
    } catch (_) {
      _error = 'No se pudieron cargar las notificaciones.';
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
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Color(0xFFFF8A00),
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'AYUDA',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF8A00),
                      letterSpacing: 0.8,
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.person_outline,
                      color: Colors.black,
                      size: 24,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Notificaciones title
              const Text(
                'Notificaciones',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),

              // Mark all read
              GestureDetector(
                onTap: () {},
                child: const Row(
                  children: [
                    Icon(
                      Icons.done_all_outlined,
                      color: Color(0xFFFF8A00),
                      size: 20,
                    ),
                    SizedBox(width: 8),
                    Text(
                      'MARCAR TODO COMO LEÍDO',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFFF8A00),
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_error != null)
                _buildStatusMessage(_error!, onRetry: _loadNovedades)
              else if (_novedades.isEmpty)
                _buildStatusMessage('No tienes notificaciones nuevas.')
              else ...[
                const Text(
                  'NOVEDADES',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Colors.grey,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ..._novedades.map(
                  (novedad) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildNotificationCard(novedad),
                  ),
                ),
              ],

              const SizedBox(height: 40),
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

  Widget _buildNotificationCard(Novedad novedad) {
    final type = (novedad.tipo ?? '').toLowerCase();
    final isSystem = type.contains('sistema') || type.contains('término');
    return _NotificationCard(
      icon: isSystem
          ? Icons.info_outline_rounded
          : Icons.notifications_outlined,
      iconColor: isSystem ? Colors.grey : const Color(0xFFFF8A00),
      title: novedad.tipo ?? 'Novedad',
      time: _formatDate(novedad.createdAt ?? novedad.updatedAt),
      description: novedad.descripcion ?? 'Novedad sin descripción.',
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
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String time;
  final String description;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.time,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.black,
                        ),
                      ),
                    ),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
