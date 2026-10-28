import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import '../../../models/solicitud.dart';
import '../../../services/auth_service.dart';
import 'driver_arrived_screen.dart';
import 'driver_report_novelty_screen.dart';
import 'driver_vehicle_delivery_verification.dart';
import '../../../widgets/report_novelty_modal.dart';

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
  static const Color petrolPale = Color(0xFFE7F0F2);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color accentOrangeSoft = Color(0xFFFBE3CB);
  static const Color white = Colors.white;
  static const Color success = Color(0xFF2E7D5B); // verde para "punto de origen"
}

class DriverNavigationScreen extends StatefulWidget {
  final Solicitud? solicitud;
  final bool isDrivingToDestination;

  const DriverNavigationScreen({
    super.key,
    this.solicitud,
    this.isDrivingToDestination = false,
  });

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  List<LatLng> _routePoints = [];
  List<LatLng> _originalRoutePoints = [];
  bool _isLoadingRoute = true;
  bool _isDetourActive = false;
  String? _detourReason;
  bool _isCardMinimized = false;
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

  Future<void> _openReportNovelty(BuildContext context) async {
    final usuarioId = await AuthService.obtenerUsuarioId();
    final conductorId = widget.solicitud?.conductorId ??
        widget.solicitud?.conductorData?['_id'] ??
        widget.solicitud?.conductorData?['id'];

    if (!context.mounted) return;
    await showReportNoveltyModal(
      context,
      solicitudId: widget.solicitud?.id,
      conductorId: conductorId?.toString(),
      usuarioId: usuarioId,
    );
  }

  @override
  Widget build(BuildContext context) {
    // Extraer datos reales del cliente y vehículo
    final clientName = widget.solicitud?.clienteNombre ?? 'Cliente';
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
            child: Column(
              children: [
                Container(
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
                              color: AppColors.petrolDark.withAlpha(30),
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
                          icon: const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange),
                          tooltip: 'Reportar Novedad',
                          onPressed: () => _openReportNovelty(context),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.12),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.fiber_manual_record,
                        color: widget.isDrivingToDestination
                            ? const Color(0xFF2E7D5B)
                            : AppColors.accentOrange,
                        size: 14,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        widget.isDrivingToDestination
                            ? 'VIAJE EN PROCESO · EN RUTA AL DESTINO'
                            : 'EN CAMINO AL PUNTO DE RECOGIDA',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: widget.isDrivingToDestination
                              ? const Color(0xFF2E7D5B)
                              : AppColors.accentOrange,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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

          // Tarjeta inferior con info del cliente y viaje (Minimizable para ver el mapa)
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeInOut,
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
                padding: EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: _isCardMinimized ? 12 : 20,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Manija para arrastrar / tocar y minimizar o expandir
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _isCardMinimized = !_isCardMinimized;
                        });
                      },
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.grey[350],
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    if (_isCardMinimized) ...[
                      // VISTA MINIMIZADA (Para ver el mapa completo)
                      Row(
                        children: [
                          Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: AppColors.petrolPale,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accentOrange,
                                width: 1.5,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.petrolDark,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.isDrivingToDestination
                                      ? 'En ruta · Destino final'
                                      : 'Punto de recogida · En camino',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slateGray,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_up_rounded,
                              size: 30,
                              color: AppColors.petrolDark,
                            ),
                            tooltip: 'Expandir información',
                            onPressed: () {
                              setState(() {
                                _isCardMinimized = false;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [AppColors.petrolBase, AppColors.petrolDark],
                            ),
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              if (widget.isDrivingToDestination) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DriverVehicleDeliveryVerification(
                                      solicitud: widget.solicitud,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DriverArrivedScreen(
                                      solicitud: widget.solicitud,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                            child: Text(
                              widget.isDrivingToDestination
                                  ? 'Finalizar / Entregar Vehículo'
                                  : 'Confirmar Llegada (Punto de Recogida)',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ] else ...[
                      // VISTA EXPANDIDA COMPLETA
                      Row(
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.petrolPale,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.accentOrange,
                                width: 2,
                              ),
                            ),
                            child: const Icon(
                              Icons.person_rounded,
                              color: AppColors.petrolDark,
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 7,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentOrangeSoft,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'CLIENTE',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  clientName,
                                  style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  vehicleDetails.isEmpty
                                      ? 'Vehículo del servicio'
                                      : vehicleDetails,
                                  style: const TextStyle(
                                    fontSize: 12.5,
                                    color: AppColors.slateGray,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              size: 30,
                              color: AppColors.petrolDark,
                            ),
                            tooltip: 'Minimizar para ver mapa',
                            onPressed: () {
                              setState(() {
                                _isCardMinimized = true;
                              });
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Info del viaje
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: AppColors.borderGray,
                            width: 1,
                          ),
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 5.5),
                              child: Container(
                                height: 18,
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
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

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
                                  fontSize: 11,
                                  color: AppColors.slateGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '14:30',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Tiempo restante',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slateGray,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                '15 min',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Botón para Reportar Novedad
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _openReportNovelty(context),
                          icon: const Icon(
                            Icons.warning_amber_rounded,
                            color: AppColors.accentOrange,
                            size: 18,
                          ),
                          label: const Text(
                            'Reportar Novedad',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.petrolDark,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(
                              color: AppColors.accentOrange,
                              width: 1.5,
                            ),
                            backgroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),

                      // Botón para confirmar llegada / entregar vehículo
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
                              if (widget.isDrivingToDestination) {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DriverVehicleDeliveryVerification(
                                      solicitud: widget.solicitud,
                                    ),
                                  ),
                                );
                              } else {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (context) => DriverArrivedScreen(
                                      solicitud: widget.solicitud,
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              widget.isDrivingToDestination
                                  ? 'Llegada a Destino / Entregar Vehículo'
                                  : 'Confirmar Llegada (Punto de Recogida)',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
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


