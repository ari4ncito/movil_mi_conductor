import 'package:flutter/material.dart';
import '../client/services/searching_driver_screen.dart';
import '../../models/vehicle.dart';

class ClientHomeScreen extends StatefulWidget {
  const ClientHomeScreen({super.key});

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _nameController = TextEditingController(text: 'Carlos Mendoza');
  final _phoneController = TextEditingController(text: '+34 000 000 000');
  final _originController = TextEditingController(text: 'Av. Paseo de la Reforma 250');
  final _destinationController = TextEditingController();

  // Datos de prueba de vehículos
  final List<Vehicle> _vehicles = [
    Vehicle(
      id: '1',
      brand: 'Toyota Corolla',
      plates: 'ABC 123',
      color: 'Rojo',
      year: '2022',
      icon: Icons.directions_car_outlined,
      iconColor: const Color(0xFF78909C),
    ),
    Vehicle(
      id: '2',
      brand: 'Honda Civic',
      plates: 'DEF 456',
      color: 'Azul',
      year: '2023',
      icon: Icons.directions_car_outlined,
      iconColor: const Color(0xFF78909C),
    ),
  ];
  Vehicle? _selectedVehicle;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Título
              const Text(
                'Información del Viaje',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 24),

              // Formulario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y Apellidos
                    const Text(
                      'DATOS PERSONALES',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Nombre Completo',
                        prefixIcon: const Icon(Icons.person_outline, color: Color(0xFFFF8A00)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Número Telefónico',
                        prefixIcon: const Icon(Icons.phone_outlined, color: Color(0xFFFF8A00)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Selección de Vehículo
                    const Text(
                      'SELECCIONAR VEHÍCULO',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Vehicle>(
                      value: _selectedVehicle,
                      decoration: InputDecoration(
                        labelText: 'Vehículo',
                        prefixIcon: const Icon(Icons.directions_car_outlined, color: Color(0xFFFF8A00)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                      items: _vehicles.map((vehicle) {
                        return DropdownMenuItem<Vehicle>(
                          value: vehicle,
                          child: Text('${vehicle.brand} (${vehicle.plates})'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicle = value;
                        });
                      },
                      hint: const Text('Selecciona tu vehículo'),
                    ),
                    const SizedBox(height: 24),

                    // Origen y Destino
                    const Text(
                      'DETALLES DEL VIAJE',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originController,
                      decoration: InputDecoration(
                        labelText: 'Lugar de Origen',
                        prefixIcon: const Icon(Icons.my_location, color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _destinationController,
                      decoration: InputDecoration(
                        labelText: 'Lugar de Destino',
                        prefixIcon: const Icon(Icons.location_pin, color: Color(0xFFFF8A00)),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.grey[200]!),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFFFF8A00), width: 2),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // Botón Solicitar Viaje
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_nameController.text.trim().isEmpty ||
                              _phoneController.text.trim().isEmpty ||
                              _originController.text.trim().isEmpty ||
                              _destinationController.text.trim().isEmpty ||
                              _selectedVehicle == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Por favor completa todos los campos')),
                            );
                            return;
                          }

                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SearchingDriverScreen(),
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
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send, size: 24),
                            SizedBox(width: 8),
                            Text(
                              'Solicitar Viaje',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
