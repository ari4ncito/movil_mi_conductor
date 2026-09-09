import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../client/client_section.dart';
import '../driver/driver_section.dart';
import 'login_screen.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {

  @override
  void initState() {
    super.initState();
    _verificarSesion();
  }

  Future<void> _verificarSesion() async {

    final tieneSesion = await AuthService.tieneSesion();

    if (!tieneSesion) {
      _irA(const LoginScreen());
      return;
    }

    final usuario = await AuthService.obtenerUsuario();

    if (usuario == null) {
      await AuthService.logout();
      _irA(const LoginScreen());
      return;
    }

    final rol = usuario['rol'];

    if (rol == 'CLIENTE') {
      _irA(
        const ClientSection(
          isGuest: false,
        ),
      );
    } 
    
    else if (rol == 'CONDUCTOR') {
      _irA(
        const DriverSection(),
      );
    } 
    
    else {
      await AuthService.logout();
      _irA(const LoginScreen());
    }
  }

  void _irA(Widget pantalla) {

    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => pantalla,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}