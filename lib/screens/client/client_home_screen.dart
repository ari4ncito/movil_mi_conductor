import 'package:flutter/material.dart';
import '../client/services/searching_driver_screen.dart';
import '../../models/vehicle.dart';

// ============================================================
// PALETA DE COLORES — Azul Petróleo · Gris · Naranja Tenue
// ============================================================
class AppColors {
  static const Color petrol = Color(0xFF0F3D44);        // Azul petróleo (principal)
  static const Color petrolDark = Color(0xFF0A2A30);     // Azul petróleo oscuro
  static const Color petrolLight = Color(0xFF1B5A63);    // Azul petróleo claro
  static const Color petrolPale = Color(0xFFDCE9EA);     // Azul petróleo muy tenue (badges/fondos)
  static const Color slate = Color(0xFF334A52);          // Azul grisáceo
  static const Color background = Color(0xFFF2F5F6);     // Fondo general
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFDDE4E6);         // Bordes suaves
  static const Color textPrimary = Color(0xFF1C2B2F);    // Texto principal
  static const Color textSecondary = Color(0xFF6B7C80);  // Texto secundario / labels
  static const Color accent = Color(0xFFE8862E);         // Naranja
  static const Color accentDark = Color(0xFFC96A1B);     // Naranja oscuro (gradiente)
  static const Color accentSoft = Color(0xFFFBEAD8);     // Naranja muy tenue (badges/fondos)
}

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
      iconColor: AppColors.slate,
    ),
    Vehicle(
      id: '2',
      brand: 'Honda Civic',
      plates: 'DEF 456',
      color: 'Azul',
      year: '2023',
      icon: Icons.directions_car_outlined,
      iconColor: AppColors.slate,
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

  // Estilo reutilizable para los inputs (mantiene la lógica intacta,
  // solo centraliza el theming visual)
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Color iconColor = AppColors.petrol,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.petrol, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Encabezado de sección reutilizable, con insignia circular a la izquierda
  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.petrolPale,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.petrol),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.petrol,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // Divisor sutil entre secciones del formulario
  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(height: 1, thickness: 1, color: AppColors.border.withOpacity(0.8)),
    );
  }

  // Pequeño chip informativo decorativo (confianza / valor agregado)
  Widget _trustChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.petrolPale.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.petrol),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------
              // HERO — Encabezado de bienvenida con gradiente
              // ---------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.petrolDark, AppColors.petrol, AppColors.petrolLight],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withOpacity(0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.25)),
                      ),
                      child: const Icon(Icons.local_taxi_rounded, color: AppColors.accent, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido de nuevo!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Solicita tu viaje en unos segundos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'En línea',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Título de sección
              const Text(
                'Información del Viaje',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petrolDark,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completa los datos para solicitar tu viaje',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),

              // Formulario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withOpacity(0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y Apellidos
                    _sectionLabel('DATOS PERSONALES', Icons.badge_outlined),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Nombre Completo',
                        icon: Icons.person_outline,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Número Telefónico',
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.accent,
                      ),
                    ),

                    _sectionDivider(),

                    // Selección de Vehículo
                    _sectionLabel('SELECCIONAR VEHÍCULO', Icons.directions_car_filled_outlined),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<Vehicle>(
                      initialValue: _selectedVehicle,
                      style: const TextStyle(color: AppColors.textPrimary),
                      dropdownColor: AppColors.cardBackground,
                      icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.petrol),
                      decoration: _inputDecoration(
                        label: 'Vehículo',
                        icon: Icons.directions_car_outlined,
                        iconColor: AppColors.petrol,
                      ),
                      items: _vehicles.map((vehicle) {
                        return DropdownMenuItem<Vehicle>(
                          value: vehicle,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(vehicle.brand),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.petrolPale,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  vehicle.plates,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.petrol,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVehicle = value;
                        });
                      },
                      hint: const Text(
                        'Selecciona tu vehículo',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ),

                    _sectionDivider(),

                    // Origen y Destino
                    _sectionLabel('DETALLES DEL VIAJE', Icons.alt_route_outlined),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Lugar de Origen',
                        icon: Icons.my_location,
                        iconColor: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _destinationController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Lugar de Destino',
                        icon: Icons.location_pin,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón Solicitar Viaje — acento naranja para destacar la acción principal
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.accent, AppColors.accentDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withOpacity(0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
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
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.send_rounded, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Solicitar Viaje',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // ---------------------------------------------
              // Franja de confianza — detalle decorativo extra
              // ---------------------------------------------
              Row(
                children: [
                  _trustChip(Icons.shield_outlined, 'Pago\nSeguro'),
                  const SizedBox(width: 10),
                  _trustChip(Icons.verified_outlined, 'Conductor\nVerificado'),
                  const SizedBox(width: 10),
                  _trustChip(Icons.bolt_outlined, 'Llegada\nRápida'),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}