import 'package:flutter/material.dart';
import '../driver_section.dart';

class DriverVehicleDeliveryVerification extends StatefulWidget {
  const DriverVehicleDeliveryVerification({super.key});

  @override
  State<DriverVehicleDeliveryVerification> createState() =>
      _DriverVehicleDeliveryVerificationState();
}

class _DriverVehicleDeliveryVerificationState
    extends State<DriverVehicleDeliveryVerification> {
  final Map<String, bool> _photos = {
    'front': false,
    'back': false,
    'left': false,
    'right': false,
  };

  bool get _allPhotosTaken => _photos.values.every((v) => v);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Verificación de Entrega',
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
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fotos del Vehículo',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Toma 4 fotos: delantera, trasera, izquierda y derecha.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),

              // Photo Grid
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _buildPhotoCard(
                    title: 'Delantera',
                    icon: Icons.arrow_upward,
                    keyName: 'front',
                  ),
                  _buildPhotoCard(
                    title: 'Trasera',
                    icon: Icons.arrow_downward,
                    keyName: 'back',
                  ),
                  _buildPhotoCard(
                    title: 'Izquierda',
                    icon: Icons.arrow_back,
                    keyName: 'left',
                  ),
                  _buildPhotoCard(
                    title: 'Derecha',
                    icon: Icons.arrow_forward,
                    keyName: 'right',
                  ),
                ],
              ),

              const SizedBox(height: 40),

              // Confirm Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _allPhotosTaken
                      ? () {
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (context) => const DriverSection(),
                            ),
                            (route) => false,
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Finalizar Servicio',
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
    );
  }

  Widget _buildPhotoCard({
    required String title,
    required IconData icon,
    required String keyName,
  }) {
    final isTaken = _photos[keyName]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _photos[keyName] = !_photos[keyName]!;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isTaken ? const Color(0xFFFFF3E0) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isTaken ? const Color(0xFFFF8A00) : Colors.grey[300]!,
            width: 2,
          ),
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
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isTaken ? const Color(0xFFFF8A00) : Colors.grey[200],
                shape: BoxShape.circle,
              ),
              child: Icon(
                isTaken ? Icons.check_circle : Icons.camera_alt_outlined,
                color: isTaken ? Colors.white : Colors.grey[600],
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isTaken ? const Color(0xFFFF8A00) : Colors.grey[700],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
