import 'package:flutter/material.dart';
import 'driver_cancel_reason_screen.dart';
import 'driver_arrived_screen.dart';

class DriverVehicleEvidenceScreen extends StatefulWidget {
  const DriverVehicleEvidenceScreen({super.key});

  @override
  State<DriverVehicleEvidenceScreen> createState() =>
      _DriverVehicleEvidenceScreenState();
}

class _DriverVehicleEvidenceScreenState
    extends State<DriverVehicleEvidenceScreen> {
  bool _hasPhoto = false;
  final List<bool> _checklist = [false, false, false];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const Text(
                    'Evidencia del Vehículo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F9F0),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'En Línea',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Time and Vehicle Info
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HORA ACTUAL',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '03:01 P. M.',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          const Text(
                            'VEHÍCULO',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'BMW i7',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.grey[800],
                        ),
                      ),
                      Text(
                        'ARC-1234',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Vehicle Photos Section
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fotografías del Vehículo',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPhotoSlot(
                          label: 'Frente',
                          hasPhoto: false,
                          onTap: () {
                            setState(() {
                              _hasPhoto = true;
                            });
                          },
                        ),
                        _buildPhotoSlot(
                          label: 'Lateral Izq.',
                          hasPhoto: false,
                          onTap: () {},
                        ),
                        _buildPhotoSlot(
                          label: 'Lateral Der.',
                          hasPhoto: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildPhotoSlot(
                          label: 'Trasera',
                          hasPhoto: false,
                          onTap: () {},
                        ),
                        _buildPhotoSlot(
                          label: 'Interior',
                          hasPhoto: false,
                          onTap: () {},
                        ),
                        _buildPhotoSlot(
                          label: 'Tablero',
                          hasPhoto: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Verification List
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Lista de Verificación',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildCheckItem(
                      label: 'Vehículo en buen estado',
                      isChecked: _checklist[0],
                      onTap: () {
                        setState(() {
                          _checklist[0] = !_checklist[0];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCheckItem(
                      label: 'Limpieza verificada',
                      isChecked: _checklist[1],
                      onTap: () {
                        setState(() {
                          _checklist[1] = !_checklist[1];
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildCheckItem(
                      label: 'Nivel de combustible / Carga OK',
                      isChecked: _checklist[2],
                      onTap: () {
                        setState(() {
                          _checklist[2] = !_checklist[2];
                        });
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_hasPhoto && _checklist.every((e) => e))
                      ? () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DriverArrivedScreen(),
                            ),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Continuar',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Cancel Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const DriverCancelReasonScreen(),
                      ),
                    );
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red, width: 2),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: const Text(
                    'Cancelar',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 28),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required String label,
    required bool hasPhoto,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: const Color(0xFFF8F9FA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasPhoto ? const Color(0xFFFF8A00) : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            hasPhoto
                ? const Icon(
                    Icons.check_circle,
                    color: Color(0xFFFF8A00),
                    size: 40,
                  )
                : Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.camera_alt_rounded,
                      color: Colors.grey[600],
                      size: 24,
                    ),
                  ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem({
    required String label,
    required bool isChecked,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: isChecked ? const Color(0xFFFF8A00) : Colors.white,
              border: Border.all(
                color: isChecked ? const Color(0xFFFF8A00) : Colors.grey[300]!,
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: isChecked
                ? const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 18,
                  )
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }
}
