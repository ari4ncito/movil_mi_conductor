import 'package:flutter/material.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────
// Paleta unificada Mi Conductor
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color petrolPale = Color(0xFFDCE9EA);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color textSecondary = Color(0xFF6B7C80);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color accentOrangeDark = Color(0xFFC96A1B);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenSoft = Color(0xFFDCFCE7);
  static const Color white = Colors.white;
}

class GuestConfirmationScreen extends StatelessWidget {
  final String name;
  final String phone;
  final String pickup;
  final String destination;
  final String? codigo;

  const GuestConfirmationScreen({
    super.key,
    required this.name,
    required this.phone,
    required this.pickup,
    required this.destination,
    this.codigo,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Tarjeta Principal
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(28),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.borderGray),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withOpacity(0.08),
                        blurRadius: 24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícono animado de éxito
                      Container(
                        width: 86,
                        height: 86,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppColors.successGreen,
                              Color(0xFF15803D),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.successGreen.withOpacity(0.35),
                              blurRadius: 18,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 46,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Título
                      const Text(
                        '¡Solicitud Registrada!',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.petrolDark,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Mensaje
                      Text(
                        'Tu solicitud de servicio ha sido enviada con éxito. En breve un asesor o conductor asignado se comunicará al número proporcionado para confirmar los detalles.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13.5,
                          color: AppColors.textSecondary,
                          height: 1.45,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Resumen de la solicitud
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.borderGray),
                        ),
                        child: Column(
                          children: [
                            _buildInfoRow(
                              icon: Icons.person_outline_rounded,
                              label: 'Contacto',
                              value: name,
                            ),
                            const Divider(height: 20, thickness: 1, color: AppColors.borderGray),
                            _buildInfoRow(
                              icon: Icons.phone_outlined,
                              label: 'Teléfono',
                              value: phone,
                            ),
                            const Divider(height: 20, thickness: 1, color: AppColors.borderGray),
                            _buildInfoRow(
                              icon: Icons.my_location_rounded,
                              label: 'Origen',
                              value: pickup,
                            ),
                            const Divider(height: 20, thickness: 1, color: AppColors.borderGray),
                            _buildInfoRow(
                              icon: Icons.location_on_rounded,
                              label: 'Destino',
                              value: destination,
                              valueColor: AppColors.accentOrangeDark,
                            ),
                            if (codigo != null && codigo!.isNotEmpty) ...[
                              const Divider(height: 20, thickness: 1, color: AppColors.borderGray),
                              _buildInfoRow(
                                icon: Icons.confirmation_number_outlined,
                                label: 'Código',
                                value: codigo!,
                                valueColor: AppColors.petrolBase,
                              ),
                            ],
                          ],
                        ),
                      ),

                      const SizedBox(height: 28),

                      // Botón Volver al Inicio
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(26),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.accentOrange,
                                AppColors.accentOrangeDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentOrange.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(26),
                              ),
                            ),
                            child: const Text(
                              'Entendido, Volver al Inicio',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.petrolPale,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 17, color: AppColors.petrolBase),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
