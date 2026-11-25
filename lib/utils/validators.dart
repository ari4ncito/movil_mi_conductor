// ============================================================================
// VALIDACIONES COMPARTIDAS DE LOGIN Y REGISTRO — MI CONDUCTOR MOBILE
// ============================================================================
//
// Reglas documentadas por tipo de documento en Colombia (alineadas con Backend):
// 1. CC (Cédula de ciudadanía - Registraduría Nacional / PILA Res. 2388 de 2016):
//    - Solo dígitos numéricos (0-9), sin letras, espacios ni caracteres especiales.
//    - Longitud: entre 6 y 10 dígitos.
// 2. TI (Tarjeta de identidad - Registraduría Nacional / Decreto 412 de 2000):
//    - Solo dígitos numéricos (0-9), sin letras, espacios ni caracteres especiales.
//    - Longitud: entre 10 y 11 dígitos.
// 3. CE (Cédula de extranjería - Migración Colombia / PILA Res. 2388 y Res. 1529):
//    - Solo dígitos numéricos (0-9), sin letras, espacios ni caracteres especiales.
//    - Longitud: entre 6 y 7 dígitos.
// 4. PPT (Permiso por Protección Temporal - Migración Colombia Decreto 216 de 2021 /
//    MinSalud Res. 1178 de 2021, Res. 572 de 2022 y Res. 2012 de 2022):
//    - Solo dígitos numéricos (0-9), sin letras, espacios ni caracteres especiales.
//    - Longitud: entre 6 y 8 dígitos.
// 5. PA / Pasaporte (OACI Doc 9303 / MinSalud Res. 2388 de 2016):
//    - Alfanumérico (letras A-Z y números 0-9), sin espacios internos ni caracteres especiales.
//    - Se normaliza en mayúsculas. Longitud: entre 6 y 16 caracteres.
// ============================================================================

class DocumentRule {
  final bool numericOnly;
  final int minLength;
  final int maxLength;
  final RegExp regex;
  final String charError;
  final String lengthError;

  const DocumentRule({
    required this.numericOnly,
    required this.minLength,
    required this.maxLength,
    required this.regex,
    required this.charError,
    required this.lengthError,
  });
}

class DocumentTypeOption {
  final String value;
  final String label;

  const DocumentTypeOption({
    required this.value,
    required this.label,
  });
}

class AuthValidators {
  const AuthValidators._();

  static final RegExp nameRegex = RegExp(r"^[a-zA-ZáéíóúÁÉÍÓÚñÑüÜ\s'-]+$");
  static final RegExp emailRegex =
      RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$");
  static final RegExp digitsRegex = RegExp(r"^\d+$");
  static final RegExp alphanumericRegex = RegExp(r"^[0-9A-Za-z]+$");
  static final RegExp celularColombiaRegex = RegExp(r"^3\d{9}$");
  static final RegExp passwordUpperRegex = RegExp(r"[A-ZÁÉÍÓÚÑ]");
  static final RegExp passwordLowerRegex = RegExp(r"[a-záéíóúñ]");
  static final RegExp passwordNumberRegex = RegExp(r"\d");
  static final RegExp passwordSpecialRegex =
      RegExp(r'''[!@#$%^&*()_+\-=\[\]{};':"\\|,.<>/?`~¡¿]''');
  static final RegExp tipoViaStartRegex = RegExp(
    r'^(?:calle|carrera|avenida(?:\s+(?:calle|carrera))?|diagonal|transversal|circular|autopista|cl\.?|cra\.?|kr\.?|av\.?|dg\.?|tv\.?)\s+\d+[a-zA-Z]?(?:\s+(?:bis|sur|norte|este|oeste|[a-zA-Z]))*',
    caseSensitive: false,
  );
  static final RegExp direccionColombiaFullRegex = RegExp(
    r'^(?:calle|carrera|avenida(?:\s+(?:calle|carrera))?|diagonal|transversal|circular|autopista|cl\.?|cra\.?|kr\.?|av\.?|dg\.?|tv\.?)\s+\d+[a-zA-Z]?(?:\s+(?:bis|sur|norte|este|oeste|[a-zA-Z]))*\s*(?:#|no\.?|nro\.?|n°)\s*\d+[a-zA-Z]?(?:\s+(?:bis|sur|norte|este|oeste|[a-zA-Z]))*\s*(?:-\s*\d+|\s+\d+)\b',
    caseSensitive: false,
  );

  static const int minNombreLength = 2;
  static const int maxNombreLength = 50;
  static const int minApellidoLength = 2;
  static const int maxApellidoLength = 50;
  static const int maxCorreoLength = 100;
  static const int telefonoLength = 10;
  static const int minDireccionLength = 5;
  static const int maxDireccionLength = 120;
  static const int minRegistrationPasswordLength = 8;
  static const int maxPasswordLength = 64;

  static const List<String> allowedDocumentTypes = [
    'CC',
    'TI',
    'CE',
    'PPT',
    'PA',
  ];

  static const List<DocumentTypeOption> documentTypeOptions = [
    DocumentTypeOption(value: 'CC', label: 'CC — Cédula de ciudadanía'),
    DocumentTypeOption(value: 'TI', label: 'TI — Tarjeta de identidad'),
    DocumentTypeOption(value: 'CE', label: 'CE — Cédula de extranjería'),
    DocumentTypeOption(
      value: 'PPT',
      label: 'PPT — Permiso por Protección Temporal',
    ),
    DocumentTypeOption(value: 'PA', label: 'Pasaporte'),
  ];

  static const List<DocumentTypeOption> clientDocumentTypeOptions = [
    DocumentTypeOption(value: 'CC', label: 'CC — Cédula'),
    DocumentTypeOption(value: 'CE', label: 'CE — Extranjería'),
    DocumentTypeOption(value: 'PPT', label: 'PPT — Temporal'),
    DocumentTypeOption(value: 'PA', label: 'PA — Pasaporte'),
  ];

  static final Map<String, DocumentRule> documentRules = {
    'CC': DocumentRule(
      numericOnly: true,
      minLength: 6,
      maxLength: 10,
      regex: digitsRegex,
      charError:
          'La Cédula de ciudadanía (CC) solo debe contener números, sin letras, espacios ni caracteres especiales.',
      lengthError:
          'La Cédula de ciudadanía (CC) debe tener entre 6 y 10 dígitos.',
    ),
    'TI': DocumentRule(
      numericOnly: true,
      minLength: 10,
      maxLength: 11,
      regex: digitsRegex,
      charError:
          'La Tarjeta de identidad (TI) solo debe contener números, sin letras, espacios ni caracteres especiales.',
      lengthError:
          'La Tarjeta de identidad (TI) debe tener entre 10 y 11 dígitos.',
    ),
    'CE': DocumentRule(
      numericOnly: true,
      minLength: 6,
      maxLength: 7,
      regex: digitsRegex,
      charError:
          'La Cédula de extranjería (CE) solo debe contener números, sin letras, espacios ni caracteres especiales.',
      lengthError:
          'La Cédula de extranjería (CE) debe tener entre 6 y 7 dígitos.',
    ),
    'PPT': DocumentRule(
      numericOnly: true,
      minLength: 6,
      maxLength: 8,
      regex: digitsRegex,
      charError:
          'El Permiso por Protección Temporal (PPT) solo debe contener números, sin letras, espacios ni caracteres especiales.',
      lengthError:
          'El Permiso por Protección Temporal (PPT) debe tener entre 6 y 8 dígitos.',
    ),
    'PA': DocumentRule(
      numericOnly: false,
      minLength: 6,
      maxLength: 16,
      regex: alphanumericRegex,
      charError:
          'El Pasaporte solo puede contener letras y números, sin espacios ni caracteres especiales.',
      lengthError:
          'El Pasaporte debe tener entre 6 y 16 caracteres alfanuméricos.',
    ),
  };

  static String normalizeTipoDocumento(String? val) {
    final upper = (val ?? '').trim().toUpperCase();
    if (upper == 'PASAPORTE' || upper == 'PAS') {
      return 'PA';
    }
    return upper;
  }

  static String normalizeDocumento(String? val, String? tipoDoc) {
    final trimmed = (val ?? '').trim();
    final tipo = normalizeTipoDocumento(tipoDoc);
    if (tipo == 'PA') {
      return trimmed.toUpperCase();
    }
    return trimmed;
  }

  static String? validateTipoDocumento(String? val) {
    final normalized = normalizeTipoDocumento(val);
    if (normalized.isEmpty) {
      return 'Selecciona un tipo de documento.';
    }
    if (!allowedDocumentTypes.contains(normalized)) {
      return 'Tipo de documento no válido. Debe ser CC, TI, CE, PPT o Pasaporte.';
    }
    return null;
  }

  static String? validateDocumento(String? val, String? tipoDoc) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) {
      return 'El número de documento es obligatorio.';
    }

    final tipoError = validateTipoDocumento(tipoDoc);
    if (tipoError != null) {
      return tipoError;
    }

    final tipo = normalizeTipoDocumento(tipoDoc);
    final rule = documentRules[tipo];
    if (rule == null) {
      return 'Tipo de documento no válido.';
    }

    if (!rule.regex.hasMatch(trimmed)) {
      return rule.charError;
    }

    if (trimmed.length < rule.minLength || trimmed.length > rule.maxLength) {
      return rule.lengthError;
    }

    return null;
  }

  static String? validateCorreo(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) {
      return 'El correo electrónico es obligatorio.';
    }
    if (trimmed.length > maxCorreoLength) {
      return 'El correo no puede superar los $maxCorreoLength caracteres.';
    }
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo electrónico válido.';
    }
    return null;
  }

  static String? validateFechaNacimiento(DateTime? fecha) {
    if (fecha == null) {
      return 'La fecha de nacimiento es obligatoria.';
    }
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final birth = DateTime(fecha.year, fecha.month, fecha.day);

    if (birth.isAfter(today)) {
      return 'La fecha de nacimiento no puede ser futura.';
    }

    int edad = today.year - birth.year;
    if (today.month < birth.month ||
        (today.month == birth.month && today.day < birth.day)) {
      edad--;
    }

    if (edad > 120) {
      return 'La fecha de nacimiento no es válida.';
    }
    if (edad < 18) {
      return 'Debes ser mayor de 18 años para registrarte (edad actual: $edad años).';
    }
    return null;
  }

  static String? validateRegistrationPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (RegExp(r'\s').hasMatch(val)) {
      return 'La contraseña no puede contener espacios.';
    }
    if (val.length < minRegistrationPasswordLength) {
      return 'Mínimo $minRegistrationPasswordLength caracteres.';
    }
    if (val.length > maxPasswordLength) {
      return 'Máximo $maxPasswordLength caracteres.';
    }
    if (!passwordUpperRegex.hasMatch(val)) {
      return 'Incluye al menos una letra mayúscula.';
    }
    if (!passwordLowerRegex.hasMatch(val)) {
      return 'Incluye al menos una letra minúscula.';
    }
    if (!passwordNumberRegex.hasMatch(val)) {
      return 'Incluye al menos un número.';
    }
    if (!passwordSpecialRegex.hasMatch(val)) {
      return 'Incluye al menos un carácter especial.';
    }
    return null;
  }

  static String? validatePassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'La contraseña es obligatoria.';
    }
    if (val.trim().isEmpty) {
      return 'La contraseña no puede estar compuesta solo por espacios.';
    }
    if (val.length < 6) {
      return 'La contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? validateCurrentPassword(String? val) {
    if (val == null || val.isEmpty || val.trim().isEmpty) {
      return 'La contraseña actual es obligatoria.';
    }
    return null;
  }

  static String? validateNewPassword(String? val) {
    if (val == null || val.isEmpty) {
      return 'La nueva contraseña es obligatoria.';
    }
    if (val.trim().isEmpty) {
      return 'La nueva contraseña no puede estar compuesta solo por espacios.';
    }
    if (val.length < 6) {
      return 'La nueva contraseña debe tener al menos 6 caracteres.';
    }
    return null;
  }

  static String? validateNombre(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'El nombre es obligatorio.';
    if (trimmed.length < minNombreLength) {
      return 'Mínimo $minNombreLength caracteres.';
    }
    if (trimmed.length > maxNombreLength) {
      return 'Máximo $maxNombreLength caracteres.';
    }
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Solo letras, tildes y espacios.';
    }
    return null;
  }

  static String? validateApellido(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'El apellido es obligatorio.';
    if (trimmed.length < minApellidoLength) {
      return 'Mínimo $minApellidoLength caracteres.';
    }
    if (trimmed.length > maxApellidoLength) {
      return 'Máximo $maxApellidoLength caracteres.';
    }
    if (!nameRegex.hasMatch(trimmed)) {
      return 'Solo letras, tildes y espacios.';
    }
    return null;
  }

  static String? validateTelefono(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'El teléfono es obligatorio.';
    if (!digitsRegex.hasMatch(trimmed)) {
      return 'Solo debe contener números.';
    }
    if (!celularColombiaRegex.hasMatch(trimmed)) {
      return 'Celular de 10 dígitos que empiece por 3.';
    }
    return null;
  }

  static String? validateDireccion(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'La dirección es obligatoria.';
    if (trimmed.length < minDireccionLength) {
      return 'Mínimo $minDireccionLength caracteres.';
    }
    if (trimmed.length > maxDireccionLength) {
      return 'Máximo $maxDireccionLength caracteres.';
    }
    if (!tipoViaStartRegex.hasMatch(trimmed) ||
        !direccionColombiaFullRegex.hasMatch(trimmed)) {
      return 'Formato inválido (ej: Calle 10 # 20-30).';
    }
    return null;
  }

  static String? validateConfirmPassword(String? val, String original) {
    if (val == null || val.isEmpty) return 'Confirma tu contraseña.';
    if (val != original) return 'Las contraseñas no coinciden.';
    return null;
  }
}
