import 'package:flutter/material.dart';
import '../../driver/services_driver/driver_assigned_screen.dart';

class RequestReceivedScreen extends StatelessWidget {
  const RequestReceivedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF3E0), // Fondo naranja claro
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFF3E0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          'Lumière',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(32),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Icono de viaje
                      Container(
                        width: 100,
                        height: 100,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF8A00),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          color: Colors.white,
                          size: 50,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título
                      const Text(
                        'Información del\nViaje',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Chips de información del viaje
                      Column(
                        children: [
                          _buildTripInfoChip(
                            icon: Icons.location_on,
                            label1: 'ORIGEN',
                            label2: 'Torre Virreyes, Pedregal 24',
                          ),
                          const SizedBox(height: 16),
                          _buildTripInfoChip(
                            icon: Icons.location_pin,
                            label1: 'DESTINO',
                            label2: 'Aeropuerto Internacional',
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildSmallInfoChip(
                                  icon: Icons.access_time,
                                  label1: 'TIEMPO',
                                  label2: '32 min',
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildSmallInfoChip(
                                  icon: Icons.route,
                                  label1: 'DISTANCIA',
                                  label2: '18.4 km',
                                ),
                              ),
                            ],
                          ),

                        ],
                      ),
                      const SizedBox(height: 48),

                      // Botón Entendido
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            // Ir a pantalla de conductor asignado
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(
                                builder: (context) => const DriverAssignedScreen(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF8A00),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text(
                            'Entendido',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTripInfoChip({
    required IconData icon,
    required String label1,
    required String label2,
    Color? color,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color?.withOpacity(0.15) ?? const Color(0xFFE0E0E0),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: color ?? Colors.grey[700],
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label1,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[500],
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label2,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.grey[800],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallInfoChip({
    required IconData icon,
    required String label1,
    required String label2,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F7FA),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF8A00),
              size: 22,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label1,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[500],
              fontWeight: FontWeight.w600,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label2,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
