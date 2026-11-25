import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mi_conductor/main.dart';
import 'package:mi_conductor/screens/auth/login_screen.dart';

void main() {
  testWidgets('MyApp inicia en LoginScreen cuando no hay sesión activa', (
    WidgetTester tester,
  ) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const MyApp());
    await tester.pumpAndSettle();

    expect(find.byType(LoginScreen), findsOneWidget);
    expect(find.text('Mi Conductor'), findsOneWidget);
    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}
