import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';

class DriverHomeScreen extends StatefulWidget {
  const DriverHomeScreen({super.key});

  @override
  State<DriverHomeScreen> createState() => _DriverHomeScreenState();
}

class _DriverHomeScreenState extends State<DriverHomeScreen> {
  bool _isLoading = true;
  bool _isUpdatingAvailability = false;

  bool _isAvailable = false;

  String? _conductorId;
  Map<String, dynamic>? _conductor;

  String? _error;

  @override
  void initState() {
    super.initState();
    _cargarConductor();
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
        _conductorId = conductor['_id']?.toString();
        _isAvailable = conductor['disponible'] == true;
        _isLoading = false;
      });
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
      return Scaffold(
        backgroundColor: const Color(0xFFF5F7F8),
        body: SafeArea(
          child: Center(
            child: CircularProgressIndicator(
              color: const Color(0xFFFF8A00),
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
                            color: Colors.black.withOpacity(0.06),
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
                  ]),
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // =========================
                      // SOLICITUDES / ESTADO
                      // =========================
                      if (_isAvailable)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(24),
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
                                'Buscando viajes...',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Las nuevas solicitudes aparecerán aquí automáticamente.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (!_isAvailable)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(32),
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
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}