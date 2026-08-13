import 'package:flutter/material.dart';
import '/models/vehicle.dart';
import '/widgets/custom_text_field.dart';

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _brandController = TextEditingController();
  final _platesController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();
  final Map<String, bool> _documents = {
    'Tarjeta de Circulación': false,
    'Seguro': false,
    'Verificación': false,
  };

  @override
  void dispose() {
    _brandController.dispose();
    _platesController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newVehicle = Vehicle(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        brand: _brandController.text.trim(),
        plates: _platesController.text.trim().toUpperCase(),
        color: _colorController.text.trim(),
        year: _yearController.text.trim(),
        icon: Icons.directions_car_outlined,
        iconColor: const Color(0xFF78909C),
      );
      Navigator.of(context).pop(newVehicle);
    }
  }

  Widget _buildDocumentCard(String title) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _documents[title] = !_documents[title]!;
        });
      },
      child: Container(
        width: 110,
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
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Agregar Vehículo',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ingresa los datos del vehículo',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 24),
                CustomTextField(
                  labelText: 'MARCA Y MODELO',
                  hintText: 'Ej: Toyota Corolla',
                  prefixIcon: Icons.directions_car_outlined,
                  controller: _brandController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'PLACAS',
                  hintText: 'Ej: ABC 123',
                  prefixIcon: Icons.confirmation_number_outlined,
                  controller: _platesController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'COLOR',
                  hintText: 'Ej: Rojo',
                  prefixIcon: Icons.palette_outlined,
                  controller: _colorController,
                ),
                const SizedBox(height: 16),
                CustomTextField(
                  labelText: 'AÑO',
                  hintText: 'Ej: 2023',
                  prefixIcon: Icons.calendar_today_outlined,
                  keyboardType: TextInputType.number,
                  controller: _yearController,
                ),
                const SizedBox(height: 28),
                // Sección de documentos
                const Text(
                  'FOTOS DE DOCUMENTOS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.black54,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildDocumentCard('Tarjeta de Circulación'),
                    _buildDocumentCard('Seguro'),
                    _buildDocumentCard('Verificación'),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Guardar Vehículo',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
