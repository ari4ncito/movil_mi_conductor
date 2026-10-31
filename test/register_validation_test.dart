import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Pruebas unitarias de validación móvil de registro', () {
    final nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'-]+$");
    final emailRegex = RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
    final digitsRegex = RegExp(r"^\d+$");
    final alphanumericRegex = RegExp(r"^[0-9A-Za-z]+$");

    String? validateNombre(String val) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return 'El nombre es obligatorio.';
      if (trimmed.length < 2) return 'El nombre debe tener al menos 2 caracteres.';
      if (trimmed.length > 100) return 'El nombre no puede superar los 100 caracteres.';
      if (!nameRegex.hasMatch(trimmed)) return 'El nombre no puede contener números ni caracteres especiales.';
      return null;
    }

    String? validateDocumento(String val, String tipoDoc) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return 'El número de documento es obligatorio.';
      if (trimmed.length < 5) return 'El documento debe tener al menos 5 caracteres.';
      if (trimmed.length > 20) return 'El documento no puede superar los 20 caracteres.';

      if (tipoDoc == 'CC' || tipoDoc == 'TI') {
        if (!digitsRegex.hasMatch(trimmed)) return 'El documento debe contener únicamente números.';
        if (trimmed.length > 12) return 'El documento no puede superar los 12 dígitos.';
      } else {
        if (!alphanumericRegex.hasMatch(trimmed)) return 'El documento solo puede contener letras y números.';
      }
      return null;
    }

    String? validateCorreo(String val) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return 'El correo electrónico es obligatorio.';
      if (!emailRegex.hasMatch(trimmed)) return 'Ingresa un correo electrónico válido.';
      return null;
    }

    String? validateTelefono(String val) {
      final trimmed = val.trim();
      if (trimmed.isEmpty) return 'El teléfono es obligatorio.';
      if (!digitsRegex.hasMatch(trimmed)) return 'El teléfono solo debe contener números.';
      if (trimmed.length < 7 || trimmed.length > 10) return 'El teléfono debe tener entre 7 y 10 dígitos.';
      return null;
    }

    String? validatePassword(String val) {
      if (val.isEmpty) return 'La contraseña es obligatoria.';
      if (val.length < 6) return 'La contraseña debe tener al menos 6 caracteres.';
      return null;
    }

    String? validateConfirmPassword(String val, String original) {
      if (val.isEmpty) return 'Confirma tu contraseña.';
      if (val != original) return 'Las contraseñas no coinciden.';
      return null;
    }

    test('Validación de Nombre: vacío, números y válido', () {
      expect(validateNombre(''), equals('El nombre es obligatorio.'));
      expect(validateNombre('A'), equals('El nombre debe tener al menos 2 caracteres.'));
      expect(validateNombre('Juan123'), equals('El nombre no puede contener números ni caracteres especiales.'));
      expect(validateNombre('María José'), isNull);
    });

    test('Validación de Documento según tipo CC y CE', () {
      expect(validateDocumento('', 'CC'), equals('El número de documento es obligatorio.'));
      expect(validateDocumento('123', 'CC'), equals('El documento debe tener al menos 5 caracteres.'));
      expect(validateDocumento('12345ABC', 'CC'), equals('El documento debe contener únicamente números.'));
      expect(validateDocumento('1020304050', 'CC'), isNull);
      expect(validateDocumento('E123456', 'CE'), isNull);
    });

    test('Validación de Correo: formato y obligatoriedad', () {
      expect(validateCorreo(''), equals('El correo electrónico es obligatorio.'));
      expect(validateCorreo('correosinformato'), equals('Ingresa un correo electrónico válido.'));
      expect(validateCorreo('usuario@dominio.com'), isNull);
    });

    test('Validación de Teléfono: numérico y longitud 7-10', () {
      expect(validateTelefono(''), equals('El teléfono es obligatorio.'));
      expect(validateTelefono('300abc1234'), equals('El teléfono solo debe contener números.'));
      expect(validateTelefono('123'), equals('El teléfono debe tener entre 7 y 10 dígitos.'));
      expect(validateTelefono('3001234567'), isNull);
    });

    test('Validación de Contraseña y confirmación', () {
      expect(validatePassword(''), equals('La contraseña es obligatoria.'));
      expect(validatePassword('123'), equals('La contraseña debe tener al menos 6 caracteres.'));
      expect(validatePassword('Segura123'), isNull);

      expect(validateConfirmPassword('', 'Segura123'), equals('Confirma tu contraseña.'));
      expect(validateConfirmPassword('Otra123', 'Segura123'), equals('Las contraseñas no coinciden.'));
      expect(validateConfirmPassword('Segura123', 'Segura123'), isNull);
    });

    test('Checklist de seguridad de contraseña de 4 requisitos', () {
      const pwd = 'Clave1';
      final hasLength = pwd.length >= 6;
      final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
      final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
      final hasNumber = RegExp(r'\d').hasMatch(pwd);

      expect(hasLength, isTrue);
      expect(hasUpper, isTrue);
      expect(hasLower, isTrue);
      expect(hasNumber, isTrue);
    });
  });
}
