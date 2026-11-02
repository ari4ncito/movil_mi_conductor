import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_conductor/screens/auth/forgot_password_screen.dart';
import 'package:mi_conductor/screens/auth/reset_password_screen.dart';
import 'package:mi_conductor/screens/shared/settings_screen.dart';
import 'package:mi_conductor/services/auth_service.dart';

void main() {
  tearDown(() {
    AuthService.httpClientOverride = null;
  });

  group('Recuperación de contraseña (ForgotPasswordScreen & ResetPasswordScreen)', () {
    testWidgets(
      'Bloquea correo vacío y formato inválido sin enviar petición',
      (tester) async {
        int calls = 0;
        AuthService.httpClientOverride = MockClient((request) async {
          calls++;
          return http.Response(jsonEncode({'success': true}), 200);
        });

        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );

        // 1. Vacío
        await tester.tap(find.text('Enviar Enlace'));
        await tester.pump();

        expect(calls, 0);
        expect(
          find.text('El correo electrónico es obligatorio.'),
          findsOneWidget,
        );
        expect(find.text('¡Enlace enviado!'), findsNothing);

        // 2. Formato inválido
        await tester.enterText(find.byType(TextField), 'correo-invalido');
        await tester.pump();
        await tester.tap(find.text('Enviar Enlace'));
        await tester.pump();

        expect(calls, 0);
        expect(
          find.text('Ingresa un correo electrónico válido.'),
          findsOneWidget,
        );
        expect(find.text('¡Enlace enviado!'), findsNothing);
      },
    );

    testWidgets(
      'Correo no registrado (404) muestra error y NO muestra confirmación falsa',
      (tester) async {
        AuthService.httpClientOverride = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message':
                  'El correo electrónico ingresado no se encuentra registrado.',
            }),
            404,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );

        await tester.enterText(
          find.byType(TextField),
          'noexiste@miconductor.com',
        );
        await tester.tap(find.text('Enviar Enlace'));
        await tester.pumpAndSettle();

        expect(find.text('¡Enlace enviado!'), findsNothing);
        expect(
          find.text(
            'El correo electrónico ingresado no se encuentra registrado.',
          ),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Fallo del servidor (500) muestra error y NO afirma que el correo fue enviado',
      (tester) async {
        AuthService.httpClientOverride = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message':
                  'No fue posible enviar el correo de recuperación en este momento. Intenta nuevamente.',
            }),
            500,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );

        await tester.enterText(
          find.byType(TextField),
          'cliente@miconductor.com',
        );
        await tester.tap(find.text('Enviar Enlace'));
        await tester.pumpAndSettle();

        expect(find.text('¡Enlace enviado!'), findsNothing);
        expect(
          find.textContaining('No fue posible enviar el correo'),
          findsWidgets,
        );
      },
    );

    testWidgets(
      'Correo registrado: confirma envío, bloquea reenvío por 10s, habilita al llegar a 0 y reinicia cuenta regresiva al reenviar',
      (tester) async {
        int calls = 0;
        AuthService.httpClientOverride = MockClient((request) async {
          calls++;
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          expect(body['correo'], 'cliente@miconductor.com');
          expect(body['origen'], 'mobile');
          return http.Response(
            jsonEncode({
              'success': true,
              'message':
                  'Se ha enviado un enlace de recuperación a tu correo electrónico.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );

        await tester.enterText(
          find.byType(TextField),
          'Cliente@MiConductor.com ',
        );
        await tester.tap(find.text('Enviar Enlace'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(calls, 1);
        expect(find.text('¡Enlace enviado!'), findsOneWidget);
        expect(find.text('Reenviar enlace (10s)'), findsOneWidget);

        // Durante los primeros 10 segundos el botón está deshabilitado
        TextButton resendBtn = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Reenviar enlace (10s)'),
        );
        expect(resendBtn.onPressed, isNull);

        // Avanzar 5 segundos -> sigue bloqueado en 5s
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Reenviar enlace (5s)'), findsOneWidget);
        await tester.tap(find.text('Reenviar enlace (5s)'));
        await tester.pump();
        expect(calls, 1);

        // Avanzar los 5 segundos restantes -> se habilita
        await tester.pump(const Duration(seconds: 5));
        expect(find.text('Reenviar enlace'), findsOneWidget);
        resendBtn = tester.widget<TextButton>(
          find.widgetWithText(TextButton, 'Reenviar enlace'),
        );
        expect(resendBtn.onPressed, isNotNull);

        // Reenviar y verificar reinicio de cuenta regresiva de 10s
        await tester.tap(find.text('Reenviar enlace'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(calls, 2);
        expect(find.text('Reenviar enlace (10s)'), findsOneWidget);

        // Limpiar temporizador restante
        await tester.pump(const Duration(seconds: 10));
      },
    );

    testWidgets(
      'Evita múltiples solicitudes simultáneas durante estado de carga',
      (tester) async {
        int calls = 0;
        final completer = Completer<http.Response>();
        AuthService.httpClientOverride = MockClient((request) {
          calls++;
          return completer.future;
        });

        await tester.pumpWidget(
          const MaterialApp(home: ForgotPasswordScreen()),
        );

        await tester.enterText(
          find.byType(TextField),
          'cliente@miconductor.com',
        );

        await tester.tap(find.text('Enviar Enlace'));
        await tester.pump();

        // El botón queda deshabilitado mientras carga
        final submitButton = tester.widget<ElevatedButton>(
          find.byType(ElevatedButton),
        );
        expect(submitButton.onPressed, isNull);
        expect(calls, 1);

        completer.complete(
          http.Response(jsonEncode({'success': true}), 200),
        );
        await tester.pump();
        await tester.pump(const Duration(seconds: 10));
      },
    );

    testWidgets(
      'Token vencido o inválido en ResetPasswordScreen conserva su manejo de error actual',
      (tester) async {
        AuthService.httpClientOverride = MockClient((request) async {
          return http.Response(
            jsonEncode({
              'success': false,
              'message':
                  'El enlace de recuperación no es válido o ha expirado.',
            }),
            400,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(
            home: ResetPasswordScreen(token: 'token-expirado'),
          ),
        );

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'NuevaClave123');
        await tester.enterText(fields.at(1), 'NuevaClave123');
        await tester.tap(find.text('Cambiar Contraseña'));
        await tester.pumpAndSettle();

        expect(find.text('¡Contraseña actualizada!'), findsNothing);
        expect(
          find.text('El enlace de recuperación no es válido o ha expirado.'),
          findsOneWidget,
        );
      },
    );
  });

  group('Cambio de contraseña en Mobile (Cliente y Conductor)', () {
    testWidgets(
      'Cambio exitoso del CLIENTE conserva el token y la sesión activa',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'token': 'jwt-cliente-valido',
          'usuario': jsonEncode({
            'id': '65f000000000000000000001',
            'nombre': 'Ana',
            'apellido': 'Gómez',
            'correo': 'ana@cliente.com',
            'rol': 'CLIENTE',
          }),
        });

        String? sentAuthHeader;
        Map<String, dynamic>? sentBody;

        AuthService.httpClientOverride = MockClient((request) async {
          sentAuthHeader = request.headers['Authorization'];
          sentBody = jsonDecode(request.body) as Map<String, dynamic>;
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Contraseña actualizada correctamente.',
            }),
            200,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: SettingsScreen()),
        );

        await tester.tap(find.text('Cambiar Contraseña'));
        await tester.pumpAndSettle();

        final fields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        expect(fields, findsNWidgets(3));

        // Verificar que los 3 campos estén ocultos por defecto
        expect(tester.widget<TextField>(fields.at(0)).obscureText, isTrue);
        expect(tester.widget<TextField>(fields.at(1)).obscureText, isTrue);
        expect(tester.widget<TextField>(fields.at(2)).obscureText, isTrue);

        await tester.enterText(fields.at(0), 'ClaveActual123');
        await tester.enterText(fields.at(1), 'NuevaClave456');
        await tester.enterText(fields.at(2), 'NuevaClave456');

        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(sentAuthHeader, 'Bearer jwt-cliente-valido');
        expect(sentBody?['currentPassword'], 'ClaveActual123');
        expect(sentBody?['newPassword'], 'NuevaClave456');
        expect(sentBody?['confirmPassword'], 'NuevaClave456');
        expect(
          find.text('Contraseña actualizada correctamente.'),
          findsOneWidget,
        );
        expect(await AuthService.tieneSesion(), isTrue);
        expect(await AuthService.obtenerToken(), 'jwt-cliente-valido');
      },
    );

    testWidgets(
      'Cambio exitoso del CONDUCTOR conserva el token y la sesión activa',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'token': 'jwt-conductor-valido',
          'usuario': jsonEncode({
            'id': '65f000000000000000000002',
            'nombre': 'Luis',
            'apellido': 'Pérez',
            'correo': 'luis@conductor.com',
            'rol': 'CONDUCTOR',
          }),
        });

        String? sentAuthHeader;
        AuthService.httpClientOverride = MockClient((request) async {
          sentAuthHeader = request.headers['Authorization'];
          return http.Response(
            jsonEncode({
              'success': true,
              'message': 'Contraseña actualizada correctamente.',
            }),
            200,
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: SettingsScreen()),
        );

        await tester.tap(find.text('Cambiar Contraseña'));
        await tester.pumpAndSettle();

        final fields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );
        await tester.enterText(fields.at(0), 'ConductorPass1');
        await tester.enterText(fields.at(1), 'ConductorPass2');
        await tester.enterText(fields.at(2), 'ConductorPass2');

        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(sentAuthHeader, 'Bearer jwt-conductor-valido');
        expect(
          find.text('Contraseña actualizada correctamente.'),
          findsOneWidget,
        );
        expect(await AuthService.tieneSesion(), isTrue);
      },
    );

    testWidgets(
      'Valida contraseña débil, confirmación distinta, contraseña actual incorrecta y error del servidor',
      (tester) async {
        SharedPreferences.setMockInitialValues({
          'token': 'jwt-cliente-valido',
          'usuario': jsonEncode({
            'id': '65f000000000000000000001',
            'rol': 'CLIENTE',
          }),
        });

        int calls = 0;
        int mode = 1; // 1 = contraseña actual incorrecta, 2 = error servidor
        AuthService.httpClientOverride = MockClient((request) async {
          calls++;
          if (mode == 1) {
            return http.Response(
              jsonEncode({
                'success': false,
                'message': 'La contraseña actual es incorrecta.',
              }),
              400,
              headers: {'content-type': 'application/json; charset=utf-8'},
            );
          }
          return http.Response(
            jsonEncode({
              'success': false,
              'message': 'Error interno del servidor.',
            }),
            500,
            headers: {'content-type': 'application/json; charset=utf-8'},
          );
        });

        await tester.pumpWidget(
          const MaterialApp(home: SettingsScreen()),
        );

        await tester.tap(find.text('Cambiar Contraseña'));
        await tester.pumpAndSettle();

        final fields = find.descendant(
          of: find.byType(Dialog),
          matching: find.byType(TextField),
        );

        // 1. Nueva contraseña corta y confirmación diferente
        await tester.enterText(fields.at(0), 'Actual123');
        await tester.enterText(fields.at(1), '123');
        await tester.enterText(fields.at(2), '999');
        await tester.tap(find.text('Guardar'));
        await tester.pump();

        expect(calls, 0);
        expect(
          find.text('La nueva contraseña debe tener al menos 6 caracteres.'),
          findsOneWidget,
        );
        expect(find.text('Las contraseñas no coinciden.'), findsOneWidget);

        // 2. Contraseña actual incorrecta en backend
        await tester.enterText(fields.at(1), 'NuevaSegura123');
        await tester.enterText(fields.at(2), 'NuevaSegura123');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(calls, 1);
        expect(
          find.text('La contraseña actual es incorrecta.'),
          findsOneWidget,
        );
        expect(find.byType(Dialog), findsOneWidget);

        // 3. Error del servidor (500)
        mode = 2;
        await tester.enterText(fields.at(0), 'OtraActual123');
        await tester.tap(find.text('Guardar'));
        await tester.pumpAndSettle();

        expect(calls, 2);
        expect(find.text('Error interno del servidor.'), findsOneWidget);
        expect(
          find.text('Contraseña actualizada correctamente.'),
          findsNothing,
        );
      },
    );

    test('Usuario no autenticado es rechazado con 401 antes de enviar petición', () async {
      SharedPreferences.setMockInitialValues({});
      int calls = 0;
      AuthService.httpClientOverride = MockClient((request) async {
        calls++;
        return http.Response(jsonEncode({'success': true}), 200);
      });

      await expectLater(
        () => AuthService.changePassword(
          currentPassword: 'Password123',
          newPassword: 'Password456',
          confirmPassword: 'Password456',
        ),
        throwsA(
          isA<AuthApiException>()
              .having((e) => e.statusCode, 'statusCode', 401),
        ),
      );
      expect(calls, 0);
    });
  });
}
