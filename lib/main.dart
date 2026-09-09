import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';
import 'screens/auth/reset_password_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  Widget _pantallaInicial() {
    // Obtiene la URL actual del navegador
    final uri = Uri.base;

    // Verifica si estamos entrando desde:
    // /reset-password?token=...
    if (uri.path == '/reset-password') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty) {
        return ResetPasswordScreen(
          token: token,
        );
      }
    }

    // Si no es recuperación de contraseña,
    // continúa con el flujo normal.
    return const AuthGate();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi Conductor',

      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFF8A00),
        ),
        useMaterial3: true,
      ),

      debugShowCheckedModeBanner: false,

      // IMPORTANTE:
      // La pantalla inicial se decide según
      // la URL que abrió el navegador.
      home: _pantallaInicial(),

      onGenerateRoute: (settings) {
        final uri = Uri.parse(
          settings.name ?? '/',
        );

        if (uri.path == '/reset-password') {
          final token = uri.queryParameters['token'];

          if (token != null && token.isNotEmpty) {
            return MaterialPageRoute(
              builder: (context) => ResetPasswordScreen(
                token: token,
              ),
            );
          }
        }

        return MaterialPageRoute(
          builder: (context) => const AuthGate(),
        );
      },
    );
  }
}