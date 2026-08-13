import 'package:flutter/material.dart';
import '/models/vehicle.dart';
import 'vehicle_detail_screen.dart';
import 'add_vehicle_screen.dart';

class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      brand: 'BMW Serie 3',
      plates: 'KPW 842',
      color: 'Negro Zafiro',
      year: '2023',
      icon: Icons.directions_car_outlined,
      iconColor: const Color(0xFF78909C),
    ),
    Vehicle(
      id: '2',
      brand: 'Tesla Model 3',
      plates: 'LWO 123',
      color: 'Blanco Perla',
      year: '2022',
      icon: Icons.electric_car_outlined,
      iconColor: const Color(0xFFFFA726),
    ),
  ];

  Future<void> _navigateToAddVehicle() async {
    final newVehicle = await Navigator.of(context).push<Vehicle>(
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );
    if (newVehicle != null) {
      setState(() {
        _vehicles.add(newVehicle);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo agregado con éxito!')),
        );
      }
    }
  }

  Future<void> _navigateToVehicleDetail(Vehicle vehicle) async {
    final shouldDelete = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => VehicleDetailScreen(vehicle: vehicle)),
    );
    if (shouldDelete == true) {
      setState(() {
        _vehicles.removeWhere((v) => v.id == vehicle.id);
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vehículo eliminado!')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Mi Conductor',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFFFF8A00),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 18,
              backgroundColor: const Color(0xFFFF8A00),
              child: const Icon(Icons.person, color: Colors.white, size: 20),
            ),
          ),
        ],
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título y descripción
              const Text(
                'Mis Vehículos',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Gestiona tus vehículos registrados para solicitar tu conductor asignado rápidamente.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Lista de vehículos
              ..._vehicles.map((vehicle) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: _buildVehicleCard(vehicle),
                );
              }),

              const SizedBox(height: 24),

              // Texto de registro hasta 5
              Text(
                'Registra hasta 5 vehículos para alternar tus servicios con comodidad.',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToAddVehicle,
        backgroundColor: const Color(0xFFFF8A00),
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white, size: 32),
      ),
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return GestureDetector(
      onTap: () => _navigateToVehicleDetail(vehicle),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icono del auto
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                vehicle.icon,
                color: vehicle.iconColor,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // Información del auto
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vehicle.brand,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vehicle.plates,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        'Color ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        vehicle.color,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        '   •   Modelo ',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        vehicle.year,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Flecha derecha
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
              size: 28,
            ),
          ],
        ),
      ),
    );
  }
}
