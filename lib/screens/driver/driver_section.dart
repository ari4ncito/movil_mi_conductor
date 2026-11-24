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
  String _nombreConductor = '';
  String _apellidoConductor = '';
  String _fotoPerfil = '';

  String get _initials {
    final n = _nombreConductor.trim();
    final a = _apellidoConductor.trim();
    if (n.isNotEmpty && a.isNotEmpty) {
      return '${n[0]}${a[0]}'.toUpperCase();
    }
    if (n.isNotEmpty) {
      return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'C';
  }

  @override
  void initState() {
    super.initState();
    _cargarNombreConductor();
  }

  Future<void> _cargarNombreConductor() async {
    try {
      final user = await AuthService.obtenerUsuario();
      if (user != null && mounted) {
        final nombre = user['nombre']?.toString() ?? '';
        final apellido = user['apellido']?.toString() ?? '';
        String foto = user['fotoPerfil']?.toString() ?? user['foto']?.toString() ?? '';
        final usuarioId = user['_id'] ?? user['id'];
        if (usuarioId != null) {
          try {
            final conductor = await ConductorService.obtenerPorUsuario(usuarioId.toString());
            final condFoto = conductor['fotoPerfil']?.toString() ?? '';
            if (condFoto.isNotEmpty) {
              foto = condFoto;
            }
          } catch (_) {}
        }
        if (!mounted) return;
        setState(() {
          _nombreConductor = nombre;
          _apellidoConductor = apellido;
          _fotoPerfil = foto;
        });
      }
    } catch (_) {}
  }

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
              gradient: const LinearGradient(
                colors: [Color(0xFF1B5A63), Color(0xFF0B3B4A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: _fotoPerfil.isNotEmpty
                ? ClipOval(
                    child: Image.network(
                      _fotoPerfil,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          _initials,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  )
                : Center(
                    child: Text(
                      _initials,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _nombreConductor.isNotEmpty
                      ? 'Bienvenido, $_nombreConductor'
                      : 'Bienvenido Conductor',
                  style: const TextStyle(
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
                    color: Colors.white.withOpacity(0.75),
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
            color: AppColors.textPrimary.withOpacity(0.08),
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
      splashColor: AppColors.petrolLight.withOpacity(0.15),
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
                          color: AppColors.petrolBase.withOpacity(0.35),
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
  String _fotoPerfil = '';
  Map<String, dynamic>? _conductorData;

  String get _initials {
    final n = _nombre.trim();
    final a = _apellido.trim();
    if (n.isNotEmpty && a.isNotEmpty) {
      return '${n[0]}${a[0]}'.toUpperCase();
    }
    if (n.isNotEmpty) {
      return n.substring(0, n.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'C';
  }

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
            _conductorData = conductor;
            _licencia = conductor['licencia']?.toString() ?? '';
            _categoria = conductor['categoriaLicencia']?.toString() ?? conductor['categoria']?.toString() ?? '';
            _experiencia = conductor['experiencia']?.toString() ?? '0';
            final condFoto = conductor['fotoPerfil']?.toString() ?? '';
            if (condFoto.isNotEmpty) {
              _fotoPerfil = condFoto;
            }
          }
          if (_fotoPerfil.isEmpty) {
            _fotoPerfil = usuario['fotoPerfil']?.toString() ?? usuario['foto']?.toString() ?? '';
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
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F3D44).withOpacity(0.04),
                      blurRadius: 18,
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
                            width: 88,
                            height: 88,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1B5A63), Color(0xFF0B3B4A)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF0F3D44).withOpacity(0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: _fotoPerfil.isNotEmpty
                                ? ClipOval(
                                    child: Image.network(
                                      _fotoPerfil,
                                      width: 88,
                                      height: 88,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) => Center(
                                        child: Text(
                                          _initials,
                                          style: const TextStyle(
                                            fontSize: 30,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                : Center(
                                    child: Text(
                                      _initials,
                                      style: const TextStyle(
                                        fontSize: 30,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.white,
                                      ),
                                    ),
                                  ),
                          ),

                          const SizedBox(height: 16),

                          Text(
                            _nombreCompleto,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981).withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                                SizedBox(width: 5),
                                Text(
                                  'Conductor Verificado',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF059669),
                                  ),
                                ),
                              ],
                            ),
                          ),


                        ],
                      ),
              ),

              const SizedBox(height: 20),

              if (!_loading) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F3D44).withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 3.5,
                            height: 16,
                            decoration: BoxDecoration(
                              color: AppColors.accentOrange,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Datos del conductor',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        onTap: () => _mostrarLicencias(context),
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.petrolBase.withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.badge_rounded,
                                  color: AppColors.petrolBase,
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 14),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Licencias de conducción',
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    SizedBox(height: 2),
                                    Text(
                                      'Toca para ver o verificar vigencias',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppColors.slateGray,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                color: AppColors.petrolBase,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                      ),

                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF0F3D44).withOpacity(0.04),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildProfileOption(
                      icon: Icons.edit_rounded,
                      label: 'Editar Perfil',
                      onTap: () async {
                        final updated = await Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const EditProfileScreen(),
                          ),
                        );
                        if (updated == true) {
                          _cargarUsuario();
                        }
                      },
                    ),

                    const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),

                    _buildProfileOption(
                      icon: Icons.help_outline_rounded,
                      label: 'Ayuda y Soporte',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => const HelpSupportScreen(),
                          ),
                        );
                      },
                    ),

                    const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),

                    _buildProfileOption(
                      icon: Icons.settings_rounded,
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
                    backgroundColor: const Color(0xFFEF4444),
                    foregroundColor: AppColors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.logout_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
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
          horizontal: 20,
          vertical: 18,
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.petrolBase.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.petrolBase,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Color(0xFF94A3B8),
              size: 22,
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
    // Extraer lista de licencias o usar la principal
    final List<Map<String, dynamic>> licencias = [];
    if (_conductorData != null) {
      final rawList = _conductorData!['licencias'];
      if (rawList is List && rawList.isNotEmpty) {
        for (var item in rawList) {
          if (item is Map) {
            licencias.add(Map<String, dynamic>.from(item));
          }
        }
      }
    }

    if (licencias.isEmpty && _licencia.isNotEmpty) {
      licencias.add({
        'numero': _licencia,
        'categoria': _categoria.isNotEmpty ? _categoria : 'B1',
        'fechaExpedicion': _conductorData?['fechaExpedicion'],
        'fechaVencimiento': _conductorData?['fechaVencimiento'],
        'lugarExpedicion': _conductorData?['lugarExpedicion'] ?? '',
        'fotoLicencia': _conductorData?['fotoLicencia'],
      });
    }

    String formatearFecha(dynamic f) {
      if (f == null) return 'No registrada';
      final s = f.toString();
      if (s.isEmpty) return 'No registrada';
      try {
        final dt = DateTime.parse(s).toLocal();
        const meses = [
          'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
          'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
        ];
        final dia = dt.day.toString().padLeft(2, '0');
        final mes = meses[dt.month - 1];
        return '$dia $mes ${dt.year}';
      } catch (_) {
        return s.split('T').first;
      }
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
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
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Mis Licencias',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (licencias.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.petrolPale,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${licencias.length} ${licencias.length == 1 ? 'licencia' : 'licencias'}',
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
            Flexible(
              child: licencias.isEmpty
                  ? Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.borderGray),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.badge_outlined, size: 40, color: AppColors.slateGray),
                          SizedBox(height: 8),
                          Text(
                            'No tienes licencias registradas actualmente.',
                            style: TextStyle(fontSize: 14, color: AppColors.slateGray),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: licencias.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final lic = licencias[index];
                        final numLic = lic['numero']?.toString() ??
                            lic['licencia']?.toString() ??
                            _licencia;
                        final catLic = lic['categoria']?.toString() ??
                            lic['categoriaLicencia']?.toString() ??
                            _categoria;
                        final fExp = formatearFecha(lic['fechaExpedicion']);
                        final fVenc = formatearFecha(lic['fechaVencimiento']);
                        final lugar = lic['lugarExpedicion']?.toString().trim();
                        final fotoLic = lic['fotoLicencia']?.toString() ??
                            _conductorData?['fotoLicencia']?.toString();

                        return Container(
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
                                  Expanded(
                                    child: Text(
                                      numLic.isEmpty ? 'Sin registro' : numLic,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.petrolBase,
                                      ),
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: AppColors.petrolPale,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      catLic.isEmpty ? 'N/A' : catLic,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.petrolBase,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Fecha de expedición', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                                      const SizedBox(height: 2),
                                      Text(fExp, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('Fecha de vencimiento', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                                      const SizedBox(height: 2),
                                      Text(fVenc, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ],
                              ),
                              if (lugar != null && lugar.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Lugar de expedición', style: TextStyle(fontSize: 11.5, color: Colors.grey[500])),
                                    const SizedBox(height: 2),
                                    Text(lugar, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ],
                              if (fotoLic != null && fotoLic.isNotEmpty) ...[
                                const SizedBox(height: 14),
                                const Divider(height: 1),
                                const SizedBox(height: 12),
                                const Text(
                                  'Documento digital de la licencia',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.slateGray,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => Dialog(
                                        backgroundColor: Colors.transparent,
                                        insetPadding: const EdgeInsets.all(16),
                                        child: Stack(
                                          alignment: Alignment.topRight,
                                          children: [
                                            ClipRRect(
                                              borderRadius: BorderRadius.circular(16),
                                              child: Image.network(
                                                fotoLic,
                                                fit: BoxFit.contain,
                                                errorBuilder: (_, __, ___) => Container(
                                                  color: Colors.white,
                                                  padding: const EdgeInsets.all(24),
                                                  child: const Text('No se pudo cargar la imagen de la licencia'),
                                                ),
                                              ),
                                            ),
                                            IconButton(
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.black54,
                                                foregroundColor: Colors.white,
                                              ),
                                              icon: const Icon(Icons.close),
                                              onPressed: () => Navigator.pop(ctx),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Container(
                                      height: 140,
                                      width: double.infinity,
                                      color: const Color(0xFFF1F5F9),
                                      child: Stack(
                                        alignment: Alignment.center,
                                        children: [
                                          Image.network(
                                            fotoLic,
                                            height: 140,
                                            width: double.infinity,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => const Center(
                                              child: Text('Documento digital registrado'),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withValues(alpha: 0.55),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: const Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(Icons.zoom_in, color: Colors.white, size: 16),
                                                SizedBox(width: 4),
                                                Text(
                                                  'Tocar para ampliar',
                                                  style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
            ),
            const SizedBox(height: 20),
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
            const SafeArea(child: SizedBox(height: 8)),
          ],
        ),
      ),
    );
  }
}
