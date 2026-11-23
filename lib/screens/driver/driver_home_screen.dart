import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';
import '../../services/solicitud_service.dart';
import '../../models/solicitud.dart';
import 'services_driver/driver_arrived_screen.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = true;
  bool _isUpdatingAvailability = false;

  bool _isAvailable = false;

  // ignore: unused_field
  String? _conductorId;
  // ignore: unused_field
  Map<String, dynamic>? _conductor;

  String? _error;
  
  Timer? _pollingTimer;
  Solicitud? _solicitudAsignada;
  final SolicitudService _solicitudService = SolicitudService();

  @override
  void initState() {
    super.initState();
    _cargarConductor();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _refrescarSolicitud() async {
    if (!mounted || _conductorId == null) return;
    try {
      final solicitudes = await _solicitudService.listar();
      final activa = solicitudes.where((s) {
        final estadoUpper = (s.estado ?? '').trim().toUpperCase();
        final isTerminated = [
          'COMPLETADO',
          'COMPLETADA',
          'FINALIZADO',
          'FINALIZADA',
          'CANCELADO',
          'CANCELADA',
        ].contains(estadoUpper);
        final matchesConductor = s.conductorId == _conductorId;
        return !isTerminated && matchesConductor;
      }).toList();

      if (mounted) {
        setState(() {
          _solicitudAsignada = activa.isNotEmpty ? activa.first : null;
        });
      }
    } catch (e) {
      debugPrint('Error al refrescar solicitud: $e');
    }
  }

  void _startPolling() {
    _pollingTimer?.cancel();
    _refrescarSolicitud();
    _pollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      if (!_isAvailable || _conductorId == null) return;
      await _refrescarSolicitud();
    });
  }

  // =========================
  // CARGAR CONDUCTOR
  // =========================

  Future<void> _cargarConductor() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final usuario = await AuthService.obtenerUsuario();

      if (usuario == null) {
        throw Exception('No hay una sesión activa.');
      }

      final usuarioId = usuario['_id'] ?? usuario['id'];

      if (usuarioId == null) {
        throw Exception('No se encontró el ID del usuario.');
      }

      final conductor = await ConductorService.obtenerPorUsuario(
        usuarioId.toString(),
      );

      if (!mounted) return;

      setState(() {
        _conductor = conductor;
        _conductorId = conductor['_id']?.toString() ?? conductor['id']?.toString();
        _isAvailable = conductor['disponible'] == true;
        _isLoading = false;
      });
      
      if (_isAvailable) {
        _startPolling();
      }
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isLoading = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  // =========================
  // CAMBIAR DISPONIBILIDAD
  // =========================

  Future<void> _cambiarDisponibilidad(bool value) async {
    if (_conductorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se encontró el conductor.')),
      );
      return;
    }

    if (_isUpdatingAvailability) {
      return;
    }

    final disponibilidadAnterior = _isAvailable;

    setState(() {
      _isAvailable = value;
      _isUpdatingAvailability = true;
    });

    try {
      final conductor = await ConductorService.actualizarDisponibilidad(
        _conductorId!,
        value,
      );

      if (!mounted) return;

      setState(() {
        _conductor = conductor;
        _isAvailable = conductor['disponible'] == true;
        _isUpdatingAvailability = false;
      });

      if (_isAvailable) {
        _startPolling();
      } else {
        _pollingTimer?.cancel();
        _solicitudAsignada = null;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isAvailable
                ? 'Ahora estás disponible para recibir solicitudes.'
                : 'Ahora estás fuera de servicio.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _isAvailable = disponibilidadAnterior;
        _isUpdatingAvailability = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF5F7F8),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: Color(0xFFFF8A00),
            ),
          ),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.error_outline,
                      color: Colors.red[400],
                      size: 42,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'No se pudo cargar el conductor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _cargarConductor,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: RefreshIndicator(
          color: const Color(0xFFFF8A00),
          onRefresh: _cargarConductor,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    // =========================
                    // DISPONIBILIDAD (Top card)
                    // =========================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0F3D44).withOpacity(0.04),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _isAvailable
                                  ? const Color(0xFF10B981).withOpacity(0.12)
                                  : Colors.grey.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isAvailable ? Icons.sensors_rounded : Icons.sensors_off_rounded,
                              color: _isAvailable ? const Color(0xFF10B981) : Colors.grey[600],
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                                                Row(
                                  children: [
                                    const Text(
                                      'Disponibilidad',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: Color(0xFF16262D),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: _isAvailable
                                            ? const Color(0xFF10B981)
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _isAvailable
                                      ? 'Listo para recibir solicitudes'
                                      : 'Fuera de servicio',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: _isUpdatingAvailability
                                ? null
                                : _cambiarDisponibilidad,
                            activeThumbColor: const Color(0xFFFF8A00),
                            activeTrackColor: const Color(0xFFFF8A00).withOpacity(0.35),
                            inactiveThumbColor: Colors.grey[400],
                            inactiveTrackColor: Colors.grey[200],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // =========================
                    // SOLICITUDES / ESTADO
                    // =========================
                    if (_isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F3D44).withOpacity(0.06),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: _solicitudAsignada == null 
                        ? Column(
                          children: [
                            const SizedBox(height: 12),
                            Container(
                              width: 84,
                              height: 84,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF8A00).withOpacity(0.08),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF8A00).withOpacity(0.4),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.radar_rounded,
                                color: Color(0xFFFF8A00),
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Esperando viaje...',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF16262D),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'La nueva solicitud aparecerá aquí automáticamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.3,
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [Color(0xFFFF9500), Color(0xFFFF6D00)],
                                    ),
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFFFF8A00).withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.local_taxi_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Â¡Servicio Asignado!',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF16262D),
                                        ),
                                      ),
                                      if (_solicitudAsignada!.codigo != null)
                                        Text(
                                          _solicitudAsignada!.codigo!,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 6,
                                        height: 6,
                                        decoration: const BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: Color(0xFF10B981),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        (_solicitudAsignada!.estado ?? 'EN PROCESO').toUpperCase(),
                                        style: const TextStyle(
                                          color: Color(0xFF047857),
                                          fontWeight: FontWeight.w800,
                                          fontSize: 11,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            // Ficha del Cliente
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: const BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [Color(0xFF1B5A63), Color(0xFF0F3D44)],
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.person_rounded, color: Colors.white, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PASAJERO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _solicitudAsignada!.clienteNombre,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14.5,
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
                            ),
                            const SizedBox(height: 16),
                            // Ruta
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8FAFC),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: const Color(0xFFE2E8F0)),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Column(
                                    children: [
                                      const Icon(
                                        Icons.radio_button_checked,
                                        color: Color(0xFF10B981),
                                        size: 18,
                                      ),
                                      Container(
                                        width: 2,
                                        height: 32,
                                        color: const Color(0xFFCBD5E1),
                                      ),
                                      const Icon(
                                        Icons.location_on_rounded,
                                        color: Color(0xFFFF8A00),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'PUNTO DE RECOGIDA',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _solicitudAsignada!.origen ?? 'Origen desconocido',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        const Text(
                                          'DESTINO',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF64748B),
                                            letterSpacing: 0.6,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          _solicitudAsignada!.destino ?? 'Destino desconocido',
                                          style: const TextStyle(
                                            fontSize: 13.5,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF1E293B),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 22),
                            // Botón Ver Viaje
                            Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(18),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF8A00).withOpacity(0.35),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () async {
                                  if (_solicitudAsignada != null) {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DriverArrivedScreen(
                                          solicitud: _solicitudAsignada,
                                        ),
                                      ),
                                    );
                                    await _refrescarSolicitud();
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A00),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                ),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.navigation_rounded, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Ver Viaje',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0F3D44).withOpacity(0.04),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.pause_circle_outline_rounded,
                                color: Colors.grey[500],
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'Estás fuera de servicio',
                              style: TextStyle(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Activa tu disponibilidad en la parte superior para comenzar a recibir solicitudes de viajes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
