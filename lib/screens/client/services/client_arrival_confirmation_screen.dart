import 'package:flutter/material.dart';
import '../../../models/solicitud.dart';
import 'client_arrived_destination_screen.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
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
  static const Color successGreen = Color(0xFF2E7D32);
}

class ClientArrivalConfirmationScreen extends StatelessWidget {
  final Solicitud? solicitud;

  const ClientArrivalConfirmationScreen({super.key, this.solicitud});

  @override
  Widget build(BuildContext context) {
    // Extracción de datos reales de la solicitud
    final usuarioConductor = solicitud?.conductorData?['usuario'];
    final conductorNombre = (usuarioConductor is Map ? usuarioConductor['nombre'] : null) ??
        solicitud?.conductorData?['nombre'] ??
        'Conductor Asignado';

    final vehiculoData = solicitud?.vehiculoData ?? {};
    final marca = vehiculoData['marca'] ?? '';
    final modelo = vehiculoData['modelo'] ?? '';
    final placa = vehiculoData['placa'] ?? '';
    final vehiculoTexto = [marca, modelo, placa].where((s) => s.isNotEmpty).join(' · ');

    final origen = solicitud?.origen ?? 'Origen';
    final destino = solicitud?.destino ?? 'Destino';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icono principal de llegada con halo elegante
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.petrolLight, AppColors.petrolDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título y mensaje de confirmación
              const Text(
                '¡Has Llegado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu conductor ha completado el recorrido y entregado el vehículo en tu destino con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.slateGray,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Tarjeta de Ruta (Origen -> Destino)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Origen
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ORIGEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slateGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                origen,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Línea divisoria de ruta
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        height: 24,
                        width: 2,
                        color: AppColors.borderGray,
                      ),
                    ),

                    // Destino
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.accentOrange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'DESTINO',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slateGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                destino,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Información del viaje: Duración, Distancia y Vehículo (SIN PRECIO)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            icon: Icons.timer_outlined,
                            iconColor: AppColors.petrolBase,
                            label: 'Duración',
                            value: '25 min',
                          ),
                        ),
                        Container(
                          height: 40,
                          width: 1,
                          color: AppColors.borderGray,
                        ),
                        Expanded(
                          child: _buildMetricTile(
                            icon: Icons.route_outlined,
                            iconColor: AppColors.accentOrange,
                            label: 'Distancia',
                            value: '12.5 km',
                          ),
                        ),
                      ],
                    ),
                    if (vehiculoTexto.isNotEmpty) ...[
                      const Divider(height: 24, color: AppColors.borderGray),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.petrolBase.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.directions_car,
                              size: 20,
                              color: AppColors.petrolBase,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Vehículo entregado',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.slateGray,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  vehiculoTexto,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8F9F0),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'Inspeccionado',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.successGreen,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tarjeta del Conductor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.petrolLight, AppColors.petrolDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            conductorNombre,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Conductor Certificado',
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle_rounded,
                      color: AppColors.successGreen,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Botón para continuar a la calificación
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
                        color: AppColors.petrolDark.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) => ClientArrivedDestinationScreen(
                            solicitud: solicitud,
                          ),
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
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Calificar Servicio',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.3,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward_rounded, size: 20),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 10),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.slateGray,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
