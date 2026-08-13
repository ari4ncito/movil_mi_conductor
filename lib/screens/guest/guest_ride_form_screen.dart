import 'package:flutter/material.dart';
import '../../widgets/custom_text_field.dart';
import 'guest_confirmation_screen.dart';

class GuestRideFormScreen extends StatefulWidget {
  const GuestRideFormScreen({super.key});

  @override
  State<GuestRideFormScreen> createState() => _GuestRideFormScreenState();
}

class _GuestRideFormScreenState extends State<GuestRideFormScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _pickupController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _vehicleBrandController = TextEditingController();
  final TextEditingController _vehicleModelController = TextEditingController();
  final TextEditingController _vehiclePlatesController = TextEditingController();
  
  final Map<String, bool> _documents = {
    'Licencia': false,
    'Tarjeta de Pertenencia': false,
  };

  void _submitRequest() {
    if (_nameController.text.trim().isEmpty ||
        _phoneController.text.trim().isEmpty ||
        _pickupController.text.trim().isEmpty ||
        _destinationController.text.trim().isEmpty ||
        _vehicleBrandController.text.trim().isEmpty ||
        _vehicleModelController.text.trim().isEmpty ||
        _vehiclePlatesController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, completa todos los campos')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GuestConfirmationScreen(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          pickup: _pickupController.text.trim(),
          destination: _destinationController.text.trim(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _pickupController.dispose();
    _destinationController.dispose();
    _vehicleBrandController.dispose();
    _vehicleModelController.dispose();
    _vehiclePlatesController.dispose();
    super.dispose();
  }

  Widget _buildDocumentCard(String title) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _documents[title] = !_documents[title]!;
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          decoration: BoxDecoration(
            color: _documents[title]! ? const Color(0xFFFFF3E0) : const Color(0xFFF5F7FA),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _documents[title]! ? const Color(0xFFFF8A00) : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Column(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: _documents[title]! ? const Color(0xFFFF8A00) : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _documents[title]! ? Icons.check_circle : Icons.camera_alt_outlined,
                  color: _documents[title]! ? Colors.white : Colors.grey[600],
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _documents[title]! ? const Color(0xFFFF8A00) : Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.black,
                  Colors.grey[900]!,
                ],
              ),
            ),
            child: CustomPaint(
              painter: MapGridPainter(),
              size: Size.infinite,
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.of(context).pop();
                        },
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.grey,
                            size: 24,
                          ),
                        ),
                      ),
                      const Text(
                        'MI CONDUCTOR',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF8A00),
                          letterSpacing: 1.2,
                        ),
                      ),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=100&h=100&fit=crop',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.person, color: Colors.grey);
                            },
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Servicio Express',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Solicita un traslado premium al instante sin necesidad de registro.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Expanded(
                    child: SingleChildScrollView(
                      child: Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.15),
                              blurRadius: 20,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: CustomTextField(
                                      labelText: 'NOMBRES',
                                      hintText: 'Ej. Carlos',
                                      controller: _nameController,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: CustomTextField(
                                      labelText: 'APELLIDOS',
                                      hintText: 'Ej. Ortega',
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'NÚMERO TELEFÓNICO',
                                hintText: '+34 000 000 000',
                                prefixIcon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                controller: _phoneController,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'LUGAR DE ORIGEN',
                                hintText: '¿Dónde te recogemos?',
                                prefixIcon: Icons.my_location,
                                controller: _pickupController,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'LUGAR DE DESTINO',
                                hintText: '¿A dónde vas?',
                                prefixIcon: Icons.location_on,
                                controller: _destinationController,
                              ),
                              const SizedBox(height: 24),

                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DATOS DEL VEHÍCULO',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'MARCA',
                                hintText: 'Ej. Toyota',
                                prefixIcon: Icons.directions_car_outlined,
                                controller: _vehicleBrandController,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'MODELO',
                                hintText: 'Ej. Corolla',
                                prefixIcon: Icons.directions_car_outlined,
                                controller: _vehicleModelController,
                              ),
                              const SizedBox(height: 16),

                              CustomTextField(
                                labelText: 'PLACAS',
                                hintText: 'Ej. ABC 123',
                                prefixIcon: Icons.confirmation_number_outlined,
                                controller: _vehiclePlatesController,
                              ),
                              const SizedBox(height: 24),

                              const Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'DOCUMENTACIÓN',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black54,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                children: [
                                  _buildDocumentCard('Licencia'),
                                  const SizedBox(width: 12),
                                  _buildDocumentCard('Tarjeta de Pertenencia'),
                                ],
                              ),
                              const SizedBox(height: 32),

                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _submitRequest,
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
                                      Icon(Icons.flash_on, size: 28),
                                      SizedBox(width: 12),
                                      Text(
                                        'Solicitar Viaje Ahora',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),

                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '¿Ya tienes cuenta?',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                    },
                                    child: const Text(
                                      'Inicia Sesión',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Color(0xFFFF8A00),
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8860B).withOpacity(0.15)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.height; i += 60) {
      canvas.drawLine(
        Offset(0, i),
        Offset(size.width, i),
        paint,
      );
    }

    for (double i = 0; i < size.width; i += 60) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i, size.height),
        paint,
      );
    }

    final diagonalPaint = Paint()
      ..color = const Color(0xFFCD853F).withOpacity(0.1)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    for (double i = -size.width; i < size.width * 2; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.width, size.height),
        diagonalPaint,
      );
    }

    for (double i = 0; i < size.width * 2; i += 120) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i - size.width, size.height),
        diagonalPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
