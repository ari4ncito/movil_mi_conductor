import 'dart:async';
import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';
import '../../services/solicitud_service.dart';
import '../../models/solicitud.dart';
import 'services_driver/driver_navigation_screen.dart';

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
  String _debugPollingText = 'Inicializando...';

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

  void _startPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      if (!_isAvailable || _conductorId == null) return;
      try {
        final solicitudes = await _solicitudService.listar();
        final activa = solicitudes.where((s) {
          final isTerminated = ['Completada', 'Cancelada', 'Cancelado', 'Completado', 'Finalizada', 'Finalizado'].contains(s.estado);
          final matchesConductor = s.conductorId == _conductorId;
          return !isTerminated && matchesConductor;
        }).toList();
        
        if (mounted) {
          setState(() {
            _debugPollingText = 'ConductorId: $_conductorId\nTotal solicitudes recibidas: ${solicitudes.length}\nActivas para ti: ${activa.length}\nEjemplo conductorIds recibidos: ${solicitudes.take(3).map((s) => s.conductorId).join(',')}';
            if (activa.isNotEmpty) {
              _solicitudAsignada = activa.first;
            } else {
              _solicitudAsignada = null;
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _debugPollingText = 'Error en polling: $e';
          });
        }
        debugPrint('Error en polling de solicitudes: $e');
      }
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
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Disponibilidad',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isAvailable
                                    ? 'Listo para recibir solicitudes'
                                    : 'No recibir solicitudes',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _isAvailable,
                            onChanged: _isUpdatingAvailability
                                ? null
                                : _cambiarDisponibilidad,
                            activeThumbColor: const Color(0xFFFF8A00),
                            inactiveThumbColor: Colors.grey[400],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // =========================
                    // SOLICITUDES / ESTADO
                    // =========================
                    if (_isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: _solicitudAsignada == null 
                        ? Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF8F9FA),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF8A00),
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.radar,
                                color: Color(0xFFFF8A00),
                                size: 42,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Esperando viaje...',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _debugPollingText,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.blueGrey,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'La nueva solicitud aparecerá aquí automáticamente.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        )
                        : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  '¡Nueva Solicitud!',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFFF8A00),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[50],
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    _solicitudAsignada!.estado ?? '',
                                    style: TextStyle(
                                      color: Colors.green[700],
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                backgroundColor: Color(0xFFF8F9FA),
                                child: Icon(Icons.person, color: Color(0xFF16262D)),
                              ),
                              title: const Text('Cliente'),
                              subtitle: Text(
                                _solicitudAsignada!.cliente ?? 'Cliente asignado',
                                style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.black),
                              ),
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                const Icon(Icons.my_location, color: Colors.green, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _solicitudAsignada!.origen ?? 'Origen desconocido',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                const Icon(Icons.location_on, color: Colors.red, size: 20),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _solicitudAsignada!.destino ?? 'Destino desconocido',
                                    style: const TextStyle(fontSize: 15),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  if (_solicitudAsignada != null) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => DriverNavigationScreen(
                                          solicitud: _solicitudAsignada,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFFF8A00),
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: const Text(
                                  'Ver Viaje',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (!_isAvailable)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 12,
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
                                color: Colors.grey[200],
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.pause_circle_outline,
                                color: Colors.grey[500],
                                size: 44,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'Estás fuera de servicio',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey[800],
                              ),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Activa tu disponibilidad en la parte superior para comenzar a recibir solicitudes de viajes.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 15,
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