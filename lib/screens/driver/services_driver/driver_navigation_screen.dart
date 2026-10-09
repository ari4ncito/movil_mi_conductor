import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../models/solicitud.dart';
import 'driver_arrived_screen.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// (Misma paleta usada en el resto de las pantallas del proyecto.)
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
  static const Color success = Color(0xFF2E7D5B); // verde para "punto de origen"
}

class DriverNavigationScreen extends StatefulWidget {
  final Solicitud? solicitud;

  const DriverNavigationScreen({super.key, this.solicitud});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  List<LatLng> _routePoints = [];
  bool _isLoadingRoute = true;
  final MapController _mapController = MapController();
  
  // Coordenadas fallback (Medellín, Colombia)
  LatLng _startPoint = const LatLng(6.2442, -75.5812);
  LatLng _endPoint = const LatLng(6.2518, -75.5636);

  @override
  void initState() {
    super.initState();
    _initializeMapAndRoute();
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
      // Append Medellín, Colombia to improve geocoding accuracy
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
    
    // Fallback a línea recta en caso de error
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
    // Extraer datos reales
    final driverName = widget.solicitud?.conductorData?['nombre'] ?? 'Ruta al Cliente';
    final vehicleData = widget.solicitud?.vehiculoData ?? {};
    final marca = vehicleData['marca'] ?? 'Vehículo';
    final modelo = vehicleData['modelo'] ?? '';
    final placa = vehicleData['placa'] ?? '';
    final color = vehicleData['color'] ?? '';
    final vehicleDetails = [marca, modelo, placa, color].where((s) => s.toString().isNotEmpty).join(' · ');

    final originAddress = widget.solicitud?.origen ?? 'Punto de Origen';
    final destAddress = widget.solicitud?.destino ?? 'Punto de Destino';

    return Scaffold(
      body: Stack(
        children: [
          // Mapa real con OpenStreetMap
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
                    width: 20,
                    height: 20,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.success,
                      radius: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 8,
                        child: CircleAvatar(
                          backgroundColor: AppColors.success,
                          radius: 5,
                        ),
                      ),
                    ),
                  ),
                  Marker(
                    point: _endPoint,
                    width: 20,
                    height: 20,
                    child: const CircleAvatar(
                      backgroundColor: AppColors.accentOrange,
                      radius: 10,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        radius: 8,
                        child: CircleAvatar(
                          backgroundColor: AppColors.accentOrange,
                          radius: 5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          // Header
          SafeArea(
            child: Container(
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
                          color: AppColors.petrolDark.withAlpha(30), // fixed withOpacity warning
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
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
                          color: AppColors.petrolDark.withAlpha(30),
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
          ),

          // Icono del conductor en el mapa
          Center(
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.petrolLight, AppColors.petrolDark],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.petrolBase.withAlpha(100),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.directions_car,
                color: AppColors.white,
                size: 40,
              ),
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
                    color: AppColors.petrolDark.withAlpha(40),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Info del conductor
                    Row(
                      children: [
                        Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.accentOrange, width: 2),
                            image: const DecorationImage(
                              image: NetworkImage(
                                'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                driverName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              const Row(
                                children: [
                                  Icon(
                                    Icons.star,
                                    color: AppColors.accentOrange,
                                    size: 16,
                                  ),
                                  SizedBox(width: 4),
                                  Text(
                                    '4.9 · 240 viajes',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.slateGray,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                vehicleDetails.isEmpty ? 'Vehículo no especificado' : vehicleDetails,
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: AppColors.slateGray,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderGray),
                              ),
                              child: const Icon(
                                Icons.call,
                                color: AppColors.petrolDark,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.background,
                                shape: BoxShape.circle,
                                border: Border.all(color: AppColors.borderGray),
                              ),
                              child: const Icon(
                                Icons.message_outlined,
                                color: AppColors.petrolDark,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Info del viaje
                    Container(
                      padding: const EdgeInsets.all(16),
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
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.success,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  originAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 5.5),
                            child: Container(
                              height: 24,
                              width: 2,
                              color: AppColors.borderGray,
                            ),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: const BoxDecoration(
                                  color: AppColors.accentOrange,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  destAddress,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Tiempo estimado
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Llegada estimada',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slateGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '14:30',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tiempo restante',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.slateGray,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '15 min',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Botón para confirmar llegada (solo para prueba)
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.petrolBase, AppColors.petrolDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.petrolDark.withAlpha(76),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => DriverArrivedScreen(solicitud: widget.solicitud),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Confirmar Llegada',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    ),
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

