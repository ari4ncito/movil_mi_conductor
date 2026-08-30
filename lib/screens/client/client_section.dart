import 'package:flutter/material.dart';
import '../client/services/request_ride_screen.dart';
import '../client/vehicles/my_vehicles_screen.dart';
import 'client_history_screen.dart';
import 'client_profile_screen.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// (Misma paleta que en client_profile_screen.dart — lo ideal
// es moverla a un solo archivo, ej. lib/theme/app_colors.dart,
// e importarla en ambos lugares para no duplicarla.)
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

class ClientSection extends StatefulWidget {
  final bool isGuest;

  const ClientSection({super.key, required this.isGuest});

  @override
  State<ClientSection> createState() => _ClientSectionState();
}

class _ClientSectionState extends State<ClientSection> {
  int _currentIndex = 0;
  final PageController _pageController = PageController();

  final List<Widget> _screens = [
    const RequestRideScreen(),
    const MyVehiclesScreen(),
    const ClientHistoryScreen(),
    const ClientProfileScreen(),
  ];

  final List<_NavItemData> _navItems = const [
    _NavItemData(
      label: 'Inicio',
      filledIcon: Icons.home_rounded,
      outlineIcon: Icons.home_outlined,
    ),
    _NavItemData(
      label: 'Vehículos',
      filledIcon: Icons.directions_car_filled_rounded,
      outlineIcon: Icons.directions_car_outlined,
    ),
    _NavItemData(
      label: 'Actividad',
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
              color: Colors.white.withOpacity(0.12),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1,
              ),
            ),
            child: const Icon(
              Icons.local_taxi_rounded,
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
                Text(
                  widget.isGuest ? 'Modo Invitado' : 'Bienvenido',
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: 0.2,
                    color: AppColors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  widget.isGuest
                      ? 'Explorando sin cuenta'
                      : '¡Qué gusto tenerte de vuelta!',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withOpacity(0.75),
                  ),
                ),
              ],
            ),
          ),
          if (widget.isGuest)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.18),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppColors.accentOrange.withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: const Text(
                'Invitado',
                style: TextStyle(
                  color: AppColors.accentOrange,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                ),
              ),
            ),
        ],
      ),
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