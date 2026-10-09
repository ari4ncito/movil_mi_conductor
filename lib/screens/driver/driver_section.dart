import 'package:flutter/material.dart';

import 'driver_home_screen.dart';
import 'driver_history_screen.dart';
import '../auth/login_screen.dart';
import '../shared/edit_profile_screen.dart';
import '../shared/help_support_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/notifications_screen.dart';

import '../../services/auth_service.dart';
import '../../services/conductor_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color petrolPale = Color(0xFFE7F0F2);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color accentOrangeSoft = Color(0xFFFBE3CB);
  static const Color white = Colors.white;
}

class DriverSection extends StatefulWidget {
  const DriverSection({super.key});

  @override
  State<DriverSection> createState() => _DriverSectionState();
}

class _DriverSectionState extends State<DriverSection> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const DriverHomeScreen(),
    const DriverHistoryScreen(),
    const _DriverProfileScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(
      label: 'Inicio',
      filledIcon: Icons.home_rounded,
      outlineIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Historial',
      filledIcon: Icons.history_rounded,
      outlineIcon: Icons.history_outlined,
    ),
    _NavItemData(
      label: 'Perfil',
      filledIcon: Icons.person_rounded,
      outlineIcon: Icons.person_outline_rounded,
    ),
  ];

  void _onNavTap(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      extendBodyBehindAppBar: false,
      appBar: _buildAppBar(),
      body: SafeArea(
        top: false,
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: _screens,
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      toolbarHeight: 68,
      centerTitle: false,
      elevation: 0,
      backgroundColor: Colors.transparent,
      automaticallyImplyLeading: false,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.petrolDark, AppColors.petrolBase],
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x330B3B4A),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
      ),
      title: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.directions_car_rounded,
              color: AppColors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bienvenido Conductor',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 0.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '¡Listo para rodar!',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_none, color: AppColors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotificationsScreen(),
              ),
            );
          },
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimary.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final selected = _currentIndex == index;
            return Expanded(
              child: _NavButton(
                selected: selected,
                item: item,
                onTap: () => _onNavTap(index),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItemData {
  final String label;
  final IconData filledIcon;
  final IconData outlineIcon;

  const _NavItemData({
    required this.label,
    required this.filledIcon,
    required this.outlineIcon,
  });
}

class _NavButton extends StatelessWidget {
  final bool selected;
  final _NavItemData item;
  final VoidCallback onTap;

  const _NavButton({
    required this.selected,
    required this.item,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      splashColor: AppColors.petrolLight.withValues(alpha: 0.15),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.petrolPale : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              curve: Curves.easeOutCubic,
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.petrolLight, AppColors.petrolDark],
                      )
                    : null,
                color: selected ? null : Colors.transparent,
                shape: BoxShape.circle,
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.petrolBase.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : [],
              ),
              child: Icon(
                selected ? item.filledIcon : item.outlineIcon,
                color: selected ? AppColors.white : AppColors.slateGray,
                size: 21,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppColors.petrolDark : AppColors.slateGray,
              ),
              child: Text(item.label),
            ),
            const SizedBox(height: 2),
            AnimatedContainer(
              duration: const Duration(milliseconds: 260),
              height: 3,
              width: selected ? 16 : 0,
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// =====================================================
// PERFIL DEL CONDUCTOR
// =====================================================

class _DriverProfileScreen extends StatefulWidget {
  const _DriverProfileScreen();

  @override
  State<_DriverProfileScreen> createState() => _DriverProfileScreenState();
}

class _DriverProfileScreenState extends State<_DriverProfileScreen> {
  bool _loading = true;

  String _nombre = 'Conductor';
  String _apellido = '';
  String _correo = '';
  String _telefono = '';
  String _licencia = '';
  String _categoria = '';
  String _experiencia = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final usuario = await AuthService.obtenerUsuario();

      if (!mounted) return;

      if (usuario != null) {
        final usuarioId = usuario['_id'] ?? usuario['id'];
        Map<String, dynamic>? conductor;
        
        if (usuarioId != null) {
          try {
            conductor = await ConductorService.obtenerPorUsuario(usuarioId.toString());
          } catch (e) {
            // Ignore if conductor fetch fails
          }
        }

        if (!mounted) return;

        setState(() {
          _nombre = usuario['nombre']?.toString() ?? 'Conductor';
          _apellido = usuario['apellido']?.toString() ?? '';
          _correo = usuario['correo']?.toString() ?? '';
          _telefono = usuario['telefono']?.toString() ?? '';
          
          if (conductor != null) {
            _licencia = conductor['licencia']?.toString() ?? '';
            _categoria = conductor['categoria']?.toString() ?? '';
            _experiencia = conductor['experiencia']?.toString() ?? '0';
          }
          
          _loading = false;
        });
      } else {
        setState(() {
          _loading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loading = false;
      });
    }
  }

  String get _nombreCompleto {
    final nombreCompleto = '$_nombre $_apellido'.trim();
    return nombreCompleto.isEmpty ? 'Conductor' : nombreCompleto;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _loading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppColors.petrolBase,
                        ),
                      )
                    : Column(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            decoration: const BoxDecoration(
                              color: AppColors.petrolBase,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: AppColors.white,
                              size: 56,
                            ),
                          ),

                          const SizedBox(height: 20),

                          Text(
                            _nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _correo.isEmpty ? 'Sin correo' : _correo,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slateGray,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            _telefono.isEmpty ? 'Sin teléfono' : _telefono,
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.slateGray,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 24),

              if (!_loading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.textPrimary.withValues(alpha: 0.06),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Datos del conductor',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () => _mostrarLicencias(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.petrolPale,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: const BoxDecoration(
                                  color: AppColors.white,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.badge_outlined,
                                  color: AppColors.petrolBase,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Expanded(
                                child: Text(
                                  'Ver mis licencias',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.petrolBase,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                color: AppColors.petrolBase,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _datoConductor(Icons.timer_outlined, 'Experiencia', '$_experiencia años'),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.textPrimary.withValues(alpha: 0.06),
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
                  ],
                ),
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    await AuthService.logout();

                    if (!context.mounted) {
                      return;
                    }

                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const LoginScreen(),
                      ),
                      (route) => false,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade600,
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
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 20,
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.petrolPale,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.petrolBase,
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

  Widget _datoConductor(IconData icon, String titulo, String valor) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(
            color: AppColors.petrolPale,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: AppColors.petrolBase,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGray,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                valor,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _mostrarLicencias(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Mis Licencias',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.borderGray),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.textPrimary.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _licencia.isEmpty ? 'Sin registro' : _licencia,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.petrolBase,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.petrolPale,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _categoria.isEmpty ? 'N/A' : _categoria,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.petrolBase,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fecha de expedición', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          const Text('01 Ene 2020', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('Fecha de vencimiento', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                          const Text('01 Ene 2025', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Lugar de expedición', style: TextStyle(fontSize: 12, color: Colors.grey[500])),
                      const Text('Secretaría de Movilidad, Bogotá', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.petrolBase,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: const Text('Cerrar', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
            const SafeArea(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}