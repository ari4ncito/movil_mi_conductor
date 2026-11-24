import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mi_conductor/screens/auth/login_screen.dart';
import 'package:mi_conductor/screens/auth/register_screen.dart';
import 'package:mi_conductor/services/auth_service.dart';
import 'package:mi_conductor/utils/validators.dart';

void main() {
  group('1. Validaciones de Login (Reglas unitarias)', () {
    test('Rechaza campos vacíos o compuestos solo por espacios', () {
      expect(
        AuthValidators.validateCorreo(''),
        'El correo electrónico es obligatorio.',
      );
      expect(
        AuthValidators.validateCorreo('   '),
        'El correo electrónico es obligatorio.',
      );
      expect(
        AuthValidators.validatePassword(''),
        'La contraseña es obligatoria.',
      );
      expect(
        AuthValidators.validatePassword('      '),
        'La contraseña no puede estar compuesta solo por espacios.',
      );
    });

    test('Valida el formato del correo electrónico y longitud de contraseña', () {
      expect(
        AuthValidators.validateCorreo('correo-invalido'),
        'Ingresa un correo electrónico válido.',
      );
      expect(
        AuthValidators.validateCorreo('usuario@dominio'),
        'Ingresa un correo electrónico válido.',
      );
      expect(
        AuthValidators.validatePassword('12345'),
        'La contraseña debe tener al menos 6 caracteres.',
      );
      expect(AuthValidators.validateCorreo('cliente@miconductor.com'), isNull);
      expect(AuthValidators.validatePassword('Secret123'), isNull);
    });
  });

  group('2. Tipos de documento y validaciones específicas', () {
    test('Incluye únicamente las 5 opciones solicitadas en el orden esperado', () {
      expect(
        AuthValidators.documentTypeOptions.map((o) => o.value).toList(),
        ['CC', 'TI', 'CE', 'PPT', 'PA'],
      );
      expect(
        AuthValidators.documentTypeOptions.map((o) => o.label).toList(),
        [
          'CC — Cédula de ciudadanía',
          'TI — Tarjeta de identidad',
          'CE — Cédula de extranjería',
          'PPT — Permiso por Protección Temporal',
          'Pasaporte',
        ],
      );
      expect(AuthValidators.validateTipoDocumento('NIT'), isNotNull);
      expect(AuthValidators.validateTipoDocumento(''), isNotNull);
    });

    test('Valida documentos válidos en los 5 tipos permitidos', () {
      expect(AuthValidators.validateDocumento('123456', 'CC'), isNull);
      expect(AuthValidators.validateDocumento('1020304050', 'CC'), isNull);

      expect(AuthValidators.validateDocumento('1020304050', 'TI'), isNull);
      expect(AuthValidators.validateDocumento('99010112345', 'TI'), isNull);

      expect(AuthValidators.validateDocumento('123456', 'CE'), isNull);
      expect(AuthValidators.validateDocumento('1234567', 'CE'), isNull);

      expect(AuthValidators.validateDocumento('123456', 'PPT'), isNull);
      expect(AuthValidators.validateDocumento('1234567', 'PPT'), isNull);
      expect(AuthValidators.validateDocumento('12345678', 'PPT'), isNull);

      expect(AuthValidators.validateDocumento('AB123456', 'PA'), isNull);
      expect(AuthValidators.validateDocumento('ab987654', 'PA'), isNull);
      expect(
        AuthValidators.normalizeDocumento('ab987654', 'PA'),
        'AB987654',
      );
    });

    test('Rechaza números demasiado cortos o largos según cada tipo', () {
      // CC (6-10)
      expect(AuthValidators.validateDocumento('12345', 'CC'), isNotNull);
      expect(AuthValidators.validateDocumento('12345678901', 'CC'), isNotNull);

      // TI (10-11)
      expect(AuthValidators.validateDocumento('12345678', 'TI'), isNotNull);
      expect(AuthValidators.validateDocumento('123456789012', 'TI'), isNotNull);

      // CE (6-7)
      expect(AuthValidators.validateDocumento('12345', 'CE'), isNotNull);
      expect(AuthValidators.validateDocumento('12345678', 'CE'), isNotNull);

      // PPT (6-8)
      expect(AuthValidators.validateDocumento('12345', 'PPT'), isNotNull);
      expect(AuthValidators.validateDocumento('123456789', 'PPT'), isNotNull);

      // PA (6-16)
      expect(AuthValidators.validateDocumento('AB123', 'PA'), isNotNull);
      expect(
        AuthValidators.validateDocumento('AB123456789012345', 'PA'),
        isNotNull,
      );
    });

    test('Rechaza letras en documentos numéricos y caracteres especiales en todos', () {
      expect(AuthValidators.validateDocumento('102030405A', 'CC'), isNotNull);
      expect(AuthValidators.validateDocumento('102030405A', 'TI'), isNotNull);
      expect(AuthValidators.validateDocumento('123456A', 'CE'), isNotNull);
      expect(AuthValidators.validateDocumento('1234567A', 'PPT'), isNotNull);

      expect(AuthValidators.validateDocumento('1020.304.050', 'CC'), isNotNull);
      expect(AuthValidators.validateDocumento('1020 304050', 'CC'), isNotNull);
      expect(AuthValidators.validateDocumento('AB-123456', 'PA'), isNotNull);
      expect(AuthValidators.validateDocumento('AB 123456', 'PA'), isNotNull);
    });

    test('AuthApiException conserva errores por campo y mensaje limpio', () {
      const ex = AuthApiException(
        'Ya existe un usuario con ese documento.',
        statusCode: 409,
        fieldErrors: {'documento': 'Documento duplicado'},
      );
      expect(
        ex.toString().replaceFirst('Exception: ', ''),
        'Ya existe un usuario con ese documento.',
      );
      expect(ex.statusCode, 409);
      expect(ex.fieldErrors['documento'], 'Documento duplicado');
    });
  });

  group('3. Pruebas de Widgets en LoginScreen y RegisterScreen', () {
    testWidgets('LoginScreen muestra errores al intentar iniciar sesión vacío o con correo inválido', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      await tester.tap(find.text('Iniciar Sesión'));
      await tester.pump();

      expect(find.text('El correo electrónico es obligatorio.'), findsOneWidget);
      expect(find.text('La contraseña es obligatoria.'), findsOneWidget);

      await tester.enterText(find.byType(TextField).first, 'correo_invalido');
      await tester.enterText(find.byType(TextField).last, '123');
      await tester.pump();

      expect(find.text('Ingresa un correo electrónico válido.'), findsOneWidget);
      expect(
        find.text('La contraseña debe tener al menos 6 caracteres.'),
        findsOneWidget,
      );
    });

    testWidgets('RegisterScreen ubica Tipo y Número de documento primero y revalida al cambiar tipo', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      final dropdownFinder = find.byType(DropdownButton<String>);
      expect(dropdownFinder, findsOneWidget);

      final docFieldFinder = find.widgetWithText(TextField, 'Número de documento *');
      final nombreFieldFinder = find.widgetWithText(TextField, 'Nombres *');
      expect(docFieldFinder, findsOneWidget);
      expect(nombreFieldFinder, findsOneWidget);

      final dropdownY = tester.getTopLeft(dropdownFinder).dy;
      final docFieldY = tester.getTopLeft(docFieldFinder).dy;
      final nombreFieldY = tester.getTopLeft(nombreFieldFinder).dy;

      // Verificar orden visual: 1. Tipo de documento, 2. Número de documento, 3. Nombres
      expect(dropdownY, lessThan(docFieldY));
      expect(docFieldY, lessThan(nombreFieldY));

      // Ingresar un número de 10 dígitos (válido para CC)
      await tester.enterText(docFieldFinder, '1020304050');
      await tester.pump();
      expect(
        find.text('La Cédula de extranjería (CE) debe tener entre 6 y 7 dígitos.'),
        findsNothing,
      );

      // Cambiar el tipo de documento a CE -> debe revalidar dinámicamente y mostrar error
      await tester.tap(dropdownFinder);
      await tester.pumpAndSettle();

      await tester.tap(find.text('CE — Cédula de extranjería').last);
      await tester.pumpAndSettle();

      expect(
        find.text('La Cédula de extranjería (CE) debe tener entre 6 y 7 dígitos.'),
        findsOneWidget,
      );

      // Cancelar timers pendientes de debounce (500ms) avanzando el reloj
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}
