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
    if (!emailRegex.hasMatch(trimmed)) {
      return 'Ingresa un correo electrónico válido.';
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
    if (trimmed.length < 2) {
      return 'El nombre debe tener al menos 2 caracteres.';
    }
    if (trimmed.length > 100) {
      return 'El nombre no puede superar los 100 caracteres.';
    }
    if (!nameRegex.hasMatch(trimmed)) {
      return 'El nombre no puede contener números ni caracteres especiales.';
    }
    return null;
  }

  static String? validateApellido(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'El apellido es obligatorio.';
    if (trimmed.length < 2) {
      return 'El apellido debe tener al menos 2 caracteres.';
    }
    if (trimmed.length > 100) {
      return 'El apellido no puede superar los 100 caracteres.';
    }
    if (!nameRegex.hasMatch(trimmed)) {
      return 'El apellido no puede contener números ni caracteres especiales.';
    }
    return null;
  }

  static String? validateTelefono(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'El teléfono es obligatorio.';
    if (!digitsRegex.hasMatch(trimmed)) {
      return 'El teléfono solo debe contener números.';
    }
    if (trimmed.length < 7 || trimmed.length > 10) {
      return 'El teléfono debe tener entre 7 y 10 dígitos.';
    }
    return null;
  }

  static String? validateDireccion(String? val) {
    final trimmed = (val ?? '').trim();
    if (trimmed.isEmpty) return 'La dirección es obligatoria.';
    if (trimmed.length < 5) {
      return 'La dirección debe tener al menos 5 caracteres.';
    }
    if (trimmed.length > 200) {
      return 'La dirección no puede superar los 200 caracteres.';
    }
    return null;
  }

  static String? validateConfirmPassword(String? val, String original) {
    if (val == null || val.isEmpty) return 'Confirma tu contraseña.';
    if (val != original) return 'Las contraseñas no coinciden.';
    return null;
  }
}
