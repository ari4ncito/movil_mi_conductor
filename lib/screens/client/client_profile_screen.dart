import 'package:flutter/material.dart';
import '../shared/edit_profile_screen.dart';
import '../client/addresses/favorite_addresses_screen.dart';
import '../shared/help_support_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/terms_policies_screen.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6); // gris muy claro azulado
  static const Color petrolDark = Color(0xFF0B3B4A); // azul petróleo oscuro
  static const Color petrolBase = Color(0xFF12566B); // azul petróleo base
  static const Color petrolLight = Color(0xFF1D7A94); // azul petróleo claro
  static const Color slateGray = Color(0xFF5C6B73); // gris azulado (texto secundario)
  static const Color borderGray = Color(0xFFE1E7E9); // gris claro (divisores)
  static const Color textPrimary = Color(0xFF16262D); // casi negro azulado
  static const Color accentOrange = Color(0xFFE8821E); // naranja de acento
  static const Color white = Colors.white;
}

class ClientProfileScreen extends StatelessWidget {
  const ClientProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              const Text(
                'Mi Perfil',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.2,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 24),
              // Tarjeta de información del usuario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [AppColors.petrolLight, AppColors.petrolDark],
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.petrolDark.withOpacity(0.28),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person,
                        color: AppColors.white,
                        size: 56,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Juan Pérez',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Cliente verificado',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentOrange,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'juan.perez@email.com',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slateGray,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      '+52 1 234 567 890',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.slateGray,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Opciones del perfil
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withOpacity(0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileOption(
                      icon: Icons.edit,
                      label: 'Editar Perfil',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.borderGray,
                    ),
                    _buildProfileOption(
                      icon: Icons.location_on,
                      label: 'Direcciones Favoritas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const FavoriteAddressesScreen(),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.borderGray,
                    ),
                    _buildProfileOption(
                      icon: Icons.help_outline,
                      label: 'Ayuda y Soporte',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.borderGray,
                    ),
                    _buildProfileOption(
                      icon: Icons.settings,
                      label: 'Configuración',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const SettingsScreen(),
                          ),
                        );
                      },
                    ),
                    Container(
                      width: double.infinity,
                      height: 1,
                      color: AppColors.borderGray,
                    ),
                    _buildProfileOption(
                      icon: Icons.privacy_tip_outlined,
                      label: 'Términos y Políticas',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const TermsPoliciesScreen(),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              // Logout button
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
                        color: AppColors.petrolDark.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () async {
                    await AuthService.logout();

                    if (!context.mounted) return;

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
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cerrar Sesión',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.accentOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.slateGray,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}