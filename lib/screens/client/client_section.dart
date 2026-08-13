import 'package:flutter/material.dart';
import '../client/services/request_ride_screen.dart';
import '../client/vehicles/my_vehicles_screen.dart';
import 'client_history_screen.dart';
import 'client_profile_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: _screens,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
            _pageController.animateToPage(
              index,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
            );
          });
        },
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: _currentIndex == 0
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.home,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.home_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 1
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.design_services,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.design_services_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
            label: 'Vehículos',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 2
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.access_time,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.access_time_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
            label: 'Actividad',
          ),
          BottomNavigationBarItem(
            icon: _currentIndex == 3
                ? Container(
                    width: 40,
                    height: 40,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFF8A00),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person,
                      color: Colors.white,
                      size: 22,
                    ),
                  )
                : const Icon(
                    Icons.person_outlined,
                    color: Colors.grey,
                    size: 24,
                  ),
            label: 'Perfil',
          ),
        ],
        selectedItemColor: const Color(0xFFFF8A00),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
      ),
      appBar: AppBar(
        title: widget.isGuest ? const Text('Modo Invitado') : const Text('Mi Conductor'),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
    );
  }
}
