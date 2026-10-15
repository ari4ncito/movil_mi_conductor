import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../models/solicitud.dart';
import '../../../services/solicitud_service.dart';
import 'client_arrival_confirmation_screen.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color white = Colors.white;
  static const Color success = Color(0xFF2E7D5B);
}

class ClientDriverTrackingScreen extends StatefulWidget {
  final Solicitud? solicitud;

  const ClientDriverTrackingScreen({super.key, this.solicitud});

  @override
  State<ClientDriverTrackingScreen> createState() => _ClientDriverTrackingScreenState();
}

class _ClientDriverTrackingScreenState extends State<ClientDriverTrackingScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  final MapController _mapController = MapController();
  
  // Coordenadas fallback (Medellín, Colombia)
  LatLng _startPoint = const LatLng(6.2442, -75.5812);
  LatLng _endPoint = const LatLng(6.2518, -75.5636);

  Timer? _statusPollingTimer;
  final SolicitudService _solicitudService = SolicitudService();
  late Solicitud? _currentSolicitud;

  @override
  void initState() {
    super.initState();
    _currentSolicitud = widget.solicitud;
    _initializeMapAndRoute();
    _startStatusPolling();
  }

  @override
  void dispose() {
    _statusPollingTimer?.cancel();
    super.dispose();
  }

  void _startStatusPolling() {
    final solId = widget.solicitud?.id;
    if (solId == null || solId.isEmpty) return;

    _statusPollingTimer = Timer.periodic(const Duration(seconds: 4), (timer) async {
      try {
        final updated = await _solicitudService.obtenerSolicitudPorId(solId);
        if (!mounted) return;

        setState(() {
          _currentSolicitud = updated;
        });

        final estadoUpper = (updated.estado ?? '').toUpperCase();
        // Si el conductor finalizó el servicio en el destino:
        if (['COMPLETADO', 'COMPLETADA', 'FINALIZADO', 'FINALIZADA'].contains(estadoUpper)) {
          timer.cancel();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => ClientArrivalConfirmationScreen(
                solicitud: updated,
              ),
            ),
          );
        }
      } catch (e) {
        debugPrint('Error en polling de estado del viaje: $e');
      }
    });
  }

  Future<void> _initializeMapAndRoute() async {
    // 1. Intentar obtener coordenadas reales
    final originAddress = widget.solicitud?.origen;
    final destAddress = widget.solicitud?.destino;

    if (originAddress != null && originAddress.isNotEmpty) {
      final startCoords = await _geocodeAddress(originAddress);
      if (startCoords != null && mounted) {
        setState(() => _startPoint = startCoords);
      }
    }
    if (destAddress != null && destAddress.isNotEmpty) {
      final endCoords = await _geocodeAddress(destAddress);
      if (endCoords != null && mounted) {
        setState(() => _endPoint = endCoords);
      }
    }

    // 2. Obtener ruta con OSRM
    await _fetchRoute();
  }

  Future<LatLng?> _geocodeAddress(String address) async {
    try {
      final searchAddress = '$address, Medellín, Colombia';
      final url = 'https://nominatim.openstreetmap.org/search?q=${Uri.encodeComponent(searchAddress)}&format=json&limit=1';
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isNotEmpty) {
          final lat = double.parse(data[0]['lat'].toString());
          final lon = double.parse(data[0]['lon'].toString());
          return LatLng(lat, lon);
        }
      }
    } catch (e) {
      debugPrint('Error geocoding address: $e');
    }
    return null;
  }

  Future<void> _fetchRoute() async {
    try {
      final url =
          'http://router.project-osrm.org/route/v1/driving/${_startPoint.longitude},${_startPoint.latitude};${_endPoint.longitude},${_endPoint.latitude}?overview=full&geometries=geojson';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final geometry = data['routes'][0]['geometry'];
          final List coordinates = geometry['coordinates'];
          setState(() {
            _routePoints = coordinates
                .map((coord) => LatLng(coord[1], coord[0]))
                .toList();
            _isLoadingRoute = false;
          });
          _fitMapToRoute();
          return;
        }
      }
    } catch (e) {
      debugPrint('Error fetching route: $e');
    }
    
    if (mounted) {
      setState(() {
        _routePoints = [_startPoint, _endPoint];
        _isLoadingRoute = false;
      });
      _fitMapToRoute();
    }
  }

  void _fitMapToRoute() {
    if (_routePoints.isNotEmpty) {
      final bounds = LatLngBounds.fromPoints(_routePoints);
      _mapController.fitCamera(
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(50.0),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final usuarioConductor = _currentSolicitud?.conductorData?['usuario'];
    final driverName = (usuarioConductor is Map ? usuarioConductor['nombre'] : null) ??
        _currentSolicitud?.conductorData?['nombre'] ??
        'Conductor Asignado';

    final vehicleData = _currentSolicitud?.vehiculoData ?? {};
    final marca = vehicleData['marca'] ?? 'Vehículo';
    final modelo = vehicleData['modelo'] ?? '';
    final placa = vehicleData['placa'] ?? '';
    final color = vehicleData['color'] ?? '';
    final vehicleDetails = [marca, modelo, placa, color].where((s) => s.toString().isNotEmpty).join(' · ');

    final originAddress = _currentSolicitud?.origen ?? 'Punto de Origen';
    final destAddress = _currentSolicitud?.destino ?? 'Punto de Destino';

    final estadoUpper = (_currentSolicitud?.estado ?? '').toUpperCase();
    final isCompletado = ['COMPLETADO', 'COMPLETADA', 'FINALIZADO', 'FINALIZADA'].contains(estadoUpper);

    return Scaffold(
      body: Stack(
        children: [
          // Mapa
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _startPoint,
              initialZoom: 13.0,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.mi_conductor',
              ),
              if (!_isLoadingRoute)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: _routePoints,
                      color: AppColors.petrolLight,
                      strokeWidth: 5.0,
                    ),
                  ],
                ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _startPoint,
                    width: 24,
                    height: 24,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.success,
                      radius: 12,
                      child: Icon(Icons.my_location, color: Colors.white, size: 14),
                    ),
                  ),
                  Marker(
                    point: _endPoint,
                    width: 24,
                    height: 24,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.accentOrange,
                      radius: 12,
                      child: Icon(Icons.location_on, color: Colors.white, size: 16),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header con botón de volver y título
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.petrolDark.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ),
                      const Text(
                        'Mi Conductor',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.petrolDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.petrolDark.withValues(alpha: 0.12),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.notifications_outlined, color: AppColors.textPrimary),
                          onPressed: () {},
                        ),
                      ),
                    ],
                  ),
                ),

                // BADGE FLOTANTE DE VIAJE EN PROCESO
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.fiber_manual_record, color: Color(0xFF2E7D5B), size: 14),
                      SizedBox(width: 8),
                      Text(
                        'VIAJE EN PROCESO',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D5B),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tarjeta inferior con info del conductor y viaje
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.borderGray, width: 1),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.petrolDark.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info del conductor
                    Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [AppColors.petrolLight, AppColors.petrolDark],
                            ),
                            border: Border.all(color: AppColors.accentOrange, width: 2),
                          ),
                          child: Center(
                            child: Text(
                              driverName.isNotEmpty ? driverName[0].toUpperCase() : 'C',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.accentOrange,
                                    size: 15,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.9 · Conductor Calificado',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.slateGray,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 2),
                              Text(
                                vehicleDetails.isEmpty ? 'Vehículo asignado' : vehicleDetails,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slateGray,
                                  fontWeight: FontWeight.w500,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Info de Ruta
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGray, width: 1),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  originAddress,
                                  style: const TextStyle(fontSize: 13, color: AppColors.slateGray),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4),
                            child: Divider(height: 8, thickness: 0.5),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  destAddress,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 16),

                    // Estado del viaje en tiempo real
                    if (isCompletado) ...[
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            _statusPollingTimer?.cancel();
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => ClientArrivalConfirmationScreen(
                                  solicitud: _currentSolicitud,
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.accentOrange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 2,
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 20),
                              SizedBox(width: 8),
                              Text(
                                '¡Llegada Confirmada! Calificar',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0FDF4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFBBF7D0), width: 1.2),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF16A34A)),
                              ),
                            ),
                            SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Viaje en curso al destino',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF15803D),
                                    ),
                                  ),
                                  SizedBox(height: 3),
                                  Text(
                                    'El conductor confirmará la llegada y certificará la entrega del vehículo en el destino.',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFF166534),
                                      height: 1.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
