import 'dart:async';
import 'package:flutter/material.dart';

import '/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _aceptaTerminos = false;
  bool _aceptaPoliticas = false;
  bool _termsError = false;

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  // FocusNodes para detectar 'blur' (pérdida de foco)
  final _nombreFocus = FocusNode();
  final _apellidoFocus = FocusNode();
  final _documentoFocus = FocusNode();
  final _correoFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _direccionFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmarPasswordFocus = FocusNode();

  // Tipo de documento (CC por defecto)
  String? _tipoDocumento = 'CC';

  // Visibilidad de contraseñas
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Estados de validación por campo
  final Map<String, bool> _touched = {};
  final Map<String, String?> _errors = {};
  final Map<String, String?> _asyncErrors = {};
  final Map<String, bool> _validating = {
    'correo': false,
    'documento': false,
  };
  final Map<String, bool?> _serverAvailability = {
    'correo': null,
    'documento': null,
  };

  // Timers de debounce (500ms)
  Timer? _correoDebounceTimer;
  Timer? _documentoDebounceTimer;

  @override
  void initState() {
    super.initState();

    // Listeners de foco para marcar 'touched' al salir del campo (onBlur)
    _nombreFocus.addListener(() => _handleFocusChange('nombre', _nombreFocus));
    _apellidoFocus
        .addListener(() => _handleFocusChange('apellido', _apellidoFocus));
    _documentoFocus
        .addListener(() => _handleFocusChange('documento', _documentoFocus));
    _correoFocus.addListener(() => _handleFocusChange('correo', _correoFocus));
    _telefonoFocus
        .addListener(() => _handleFocusChange('telefono', _telefonoFocus));
    _direccionFocus
        .addListener(() => _handleFocusChange('direccion', _direccionFocus));
    _passwordFocus.addListener(() {
      setState(() {});
      _handleFocusChange('password', _passwordFocus);
    });
    _confirmarPasswordFocus.addListener(
      () => _handleFocusChange('confirmPassword', _confirmarPasswordFocus),
    );
  }

  void _handleFocusChange(String field, FocusNode node) {
    if (!node.hasFocus) {
      setState(() {
        _touched[field] = true;
      });
      _validateField(field);
    }
  }

  @override
  void dispose() {
    _correoDebounceTimer?.cancel();
    _documentoDebounceTimer?.cancel();

    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();

    _nombreFocus.dispose();
    _apellidoFocus.dispose();
    _documentoFocus.dispose();
    _correoFocus.dispose();
    _telefonoFocus.dispose();
    _direccionFocus.dispose();
    _passwordFocus.dispose();
    _confirmarPasswordFocus.dispose();

    super.dispose();
  }

  // ==========================================
  // REGLAS DE VALIDACIÓN SÍNCRONAS
  // ==========================================

  void _validateField(String field) {
    String? err;
    switch (field) {
      case 'nombre':
        err = AuthValidators.validateNombre(_nombreController.text);
        break;
      case 'apellido':
        err = AuthValidators.validateApellido(_apellidoController.text);
        break;
      case 'tipoDocumento':
        err = AuthValidators.validateTipoDocumento(_tipoDocumento);
        break;
      case 'documento':
        err = AuthValidators.validateDocumento(
          _documentoController.text,
          _tipoDocumento,
        );
        break;
      case 'correo':
        err = AuthValidators.validateCorreo(_correoController.text);
        break;
      case 'telefono':
        err = AuthValidators.validateTelefono(_telefonoController.text);
        break;
      case 'direccion':
        err = AuthValidators.validateDireccion(_direccionController.text);
        break;
      case 'password':
        err = AuthValidators.validatePassword(_passwordController.text);
        break;
      case 'confirmPassword':
        err = AuthValidators.validateConfirmPassword(
          _confirmarPasswordController.text,
          _passwordController.text,
        );
        break;
    }

    setState(() {
      if (err != null) {
        _errors[field] = err;
      } else {
        _errors.remove(field);
      }
    });
  }

  // ==========================================
  // COMPROBACIONES ASÍNCRONAS CON DEBOUNCE (500MS)
  // ==========================================

  void _triggerEmailCheck(String email) {
    _correoDebounceTimer?.cancel();
    final trimmed = email.trim();
    final syncErr = AuthValidators.validateCorreo(trimmed);

    if (syncErr != null || trimmed.isEmpty) {
      setState(() {
        _validating['correo'] = false;
        _asyncErrors.remove('correo');
        _serverAvailability['correo'] = null;
      });
      return;
    }

    setState(() {
      _validating['correo'] = true;
      _asyncErrors.remove('correo');
    });

    _correoDebounceTimer = Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await AuthService.checkEmail(trimmed);
        final exists = res['exists'] == true;

        if (!mounted) return;
        setState(() {
          if (exists) {
            _asyncErrors['correo'] =
                'Este correo electrónico ya está registrado.';
            _serverAvailability['correo'] = false;
          } else {
            _asyncErrors.remove('correo');
            _serverAvailability['correo'] = true;
          }
        });
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().toLowerCase();
        if (msg.contains('ya está registrado') || msg.contains('ya existe')) {
          setState(() {
            _asyncErrors['correo'] =
                'Este correo electrónico ya está registrado.';
            _serverAvailability['correo'] = false;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _validating['correo'] = false;
          });
        }
      }
    });
  }

  void _triggerDocumentCheck(String doc, [String? tipoDocOverride]) {
    _documentoDebounceTimer?.cancel();
    final effectiveTipo = tipoDocOverride ?? _tipoDocumento;
    final trimmed = doc.trim();
    final syncErr = AuthValidators.validateDocumento(trimmed, effectiveTipo);

    if (syncErr != null || trimmed.isEmpty) {
      setState(() {
        _validating['documento'] = false;
        _asyncErrors.remove('documento');
        _serverAvailability['documento'] = null;
      });
      return;
    }

    setState(() {
      _validating['documento'] = true;
      _asyncErrors.remove('documento');
    });

    final normalizedTipo = AuthValidators.normalizeTipoDocumento(effectiveTipo);
    final normalizedDoc =
        AuthValidators.normalizeDocumento(trimmed, normalizedTipo);

    _documentoDebounceTimer =
        Timer(const Duration(milliseconds: 500), () async {
      try {
        final res = await AuthService.checkDocument(
          normalizedDoc,
          normalizedTipo,
        );
        final exists = res['exists'] == true;

        if (!mounted) return;
        setState(() {
          if (exists) {
            _asyncErrors['documento'] =
                'Este número de documento ya está registrado.';
            _serverAvailability['documento'] = false;
          } else {
            _asyncErrors.remove('documento');
            _serverAvailability['documento'] = true;
          }
        });
      } catch (e) {
        if (!mounted) return;
        final msg = e.toString().toLowerCase();
        if (msg.contains('ya está registrado') || msg.contains('ya existe')) {
          setState(() {
            _asyncErrors['documento'] =
                'Este número de documento ya está registrado.';
            _serverAvailability['documento'] = false;
          });
        }
      } finally {
        if (mounted) {
          setState(() {
            _validating['documento'] = false;
          });
        }
      }
    });
  }

  // ==========================================
  // HELPERS DE ESTADO VISUAL
  // ==========================================

  String? _getEffectiveError(String field) {
    final isTouched = _touched[field] == true;
    if (!isTouched) return null;
    return _errors[field] ?? _asyncErrors[field];
  }

  bool _isFieldValid(String field, String value) {
    final isTouched = _touched[field] == true;
    final hasErr = (_errors[field] != null) || (_asyncErrors[field] != null);
    final isVal = _validating[field] == true;
    return isTouched && !hasErr && !isVal && value.trim().isNotEmpty;
  }

  bool get _isFormValid {
    final hasEmpty = _tipoDocumento == null ||
        _documentoController.text.trim().isEmpty ||
        _nombreController.text.trim().isEmpty ||
        _apellidoController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmarPasswordController.text.isEmpty;

    final hasValidationFailures =
        AuthValidators.validateTipoDocumento(_tipoDocumento) != null ||
            AuthValidators.validateDocumento(
                  _documentoController.text,
                  _tipoDocumento,
                ) !=
                null ||
            AuthValidators.validateNombre(_nombreController.text) != null ||
            AuthValidators.validateApellido(_apellidoController.text) != null ||
            AuthValidators.validateCorreo(_correoController.text) != null ||
            AuthValidators.validateTelefono(_telefonoController.text) != null ||
            AuthValidators.validateDireccion(_direccionController.text) !=
                null ||
            AuthValidators.validatePassword(_passwordController.text) != null ||
            AuthValidators.validateConfirmPassword(
                  _confirmarPasswordController.text,
                  _passwordController.text,
                ) !=
                null;

    final hasErrors =
        _errors.isNotEmpty || _asyncErrors.isNotEmpty || hasValidationFailures;
    final isChecking =
        (_validating['correo'] == true) || (_validating['documento'] == true);
    final termsAccepted = _aceptaTerminos && _aceptaPoliticas;

    return !hasEmpty && !hasErrors && !isChecking && termsAccepted && !_isLoading;
  }

  // ==========================================
  // VALIDACIÓN INTEGRAL PREVIA AL ENVÍO
  // ==========================================

  bool _validateAll() {
    _errors.clear();

    final errTipo = AuthValidators.validateTipoDocumento(_tipoDocumento);
    if (errTipo != null) _errors['tipoDocumento'] = errTipo;

    final errDoc = AuthValidators.validateDocumento(
      _documentoController.text,
      _tipoDocumento,
    );
    if (errDoc != null) _errors['documento'] = errDoc;

    final errNombre = AuthValidators.validateNombre(_nombreController.text);
    if (errNombre != null) _errors['nombre'] = errNombre;

    final errApellido =
        AuthValidators.validateApellido(_apellidoController.text);
    if (errApellido != null) _errors['apellido'] = errApellido;

    final errCorreo = AuthValidators.validateCorreo(_correoController.text);
    if (errCorreo != null) _errors['correo'] = errCorreo;

    final errTel = AuthValidators.validateTelefono(_telefonoController.text);
    if (errTel != null) _errors['telefono'] = errTel;

    final errDir = AuthValidators.validateDireccion(_direccionController.text);
    if (errDir != null) _errors['direccion'] = errDir;

    final errPass = AuthValidators.validatePassword(_passwordController.text);
    if (errPass != null) _errors['password'] = errPass;

    final errConf = AuthValidators.validateConfirmPassword(
      _confirmarPasswordController.text,
      _passwordController.text,
    );
    if (errConf != null) _errors['confirmPassword'] = errConf;

    // Marcar todos como tocados
    setState(() {
      _touched['tipoDocumento'] = true;
      _touched['documento'] = true;
      _touched['nombre'] = true;
      _touched['apellido'] = true;
      _touched['correo'] = true;
      _touched['telefono'] = true;
      _touched['direccion'] = true;
      _touched['password'] = true;
      _touched['confirmPassword'] = true;
      _termsError = !_aceptaTerminos || !_aceptaPoliticas;
    });

    _formKey.currentState?.validate();

    return _errors.isEmpty &&
        _asyncErrors.isEmpty &&
        _aceptaTerminos &&
        _aceptaPoliticas;
  }

  // ==========================================
  // REGISTRAR CLIENTE
  // ==========================================

  Future<void> _register() async {
    if (_isLoading) return;

    if (_validating['correo'] == true || _validating['documento'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Espera a que finalice la verificación de tus datos.'),
          backgroundColor: Color(0xFFFB9833),
        ),
      );
      return;
    }

    if (!_validateAll()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('Por favor corrige los campos con errores antes de continuar.'),
          backgroundColor: Color(0xFFE53935),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final tipoNormalizado =
          AuthValidators.normalizeTipoDocumento(_tipoDocumento);
      final documentoNormalizado = AuthValidators.normalizeDocumento(
        _documentoController.text,
        tipoNormalizado,
      );

      await AuthService.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        tipoDocumento: tipoNormalizado,
        documento: documentoNormalizado,
        correo: _correoController.text.trim().toLowerCase(),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              '¡Cuenta creada correctamente! Ahora puedes iniciar sesión.'),
          backgroundColor: Color(0xFF2E7D32),
          duration: Duration(seconds: 3),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final rawError = e.toString().replaceFirst('Exception: ', '');

      if (e is AuthApiException && e.fieldErrors.isNotEmpty) {
        setState(() {
          e.fieldErrors.forEach((campo, mensaje) {
            _errors[campo] = mensaje;
            _touched[campo] = true;
          });
        });
      } else if (rawError.toLowerCase().contains('correo')) {
        setState(() {
          _asyncErrors['correo'] = 'Este correo electrónico ya está registrado.';
          _touched['correo'] = true;
        });
      } else if (rawError.toLowerCase().contains('documento')) {
        setState(() {
          _asyncErrors['documento'] =
              'Este número de documento ya está registrado.';
          _touched['documento'] = true;
        });
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(rawError),
          backgroundColor: const Color(0xFFE53935),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ==========================================
  // WIDGET CHECKLIST Y FORTALEZA DE CONTRASEÑA
  // ==========================================

  Widget _buildPasswordRequirements() {
    final pwd = _passwordController.text;
    if (!_passwordFocus.hasFocus && pwd.isEmpty) {
      return const SizedBox.shrink();
    }

    final hasLength = pwd.length >= 6;
    final hasUpper = RegExp(r'[A-Z]').hasMatch(pwd);
    final hasLower = RegExp(r'[a-z]').hasMatch(pwd);
    final hasNumber = RegExp(r'\d').hasMatch(pwd);

    int score = 0;
    if (hasLength) score++;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasNumber) score++;

    String strengthText;
    Color strengthColor;
    double strengthProgress;

    if (score <= 1) {
      strengthText = 'Muy débil';
      strengthColor = const Color(0xFFE53935);
      strengthProgress = 0.25;
    } else if (score == 2) {
      strengthText = 'Débil';
      strengthColor = Colors.amber.shade700;
      strengthProgress = 0.50;
    } else if (score == 3) {
      strengthText = 'Aceptable';
      strengthColor = const Color(0xFFFB9833);
      strengthProgress = 0.75;
    } else {
      strengthText = 'Fuerte y segura';
      strengthColor = const Color(0xFF2E7D32);
      strengthProgress = 1.0;
    }

    Widget buildRequirementItem(String text, bool satisfied) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Icon(
              satisfied
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              size: 14,
              color: satisfied ? const Color(0xFF2E7D32) : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              text,
              style: TextStyle(
                fontSize: 12,
                color: satisfied
                    ? const Color(0xFF2E7D32)
                    : Colors.grey.shade700,
                fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Seguridad de la contraseña:',
                style: TextStyle(fontSize: 12, color: Colors.black54),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: strengthProgress,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
              minHeight: 5,
            ),
          ),
          const SizedBox(height: 10),
          buildRequirementItem('Mínimo 6 caracteres', hasLength),
          buildRequirementItem('Al menos una mayúscula (A-Z)', hasUpper),
          buildRequirementItem('Al menos una minúscula (a-z)', hasLower),
          buildRequirementItem('Al menos un número (0-9)', hasNumber),
        ],
      ),
    );
  }

  // ==========================================
  // SELECTOR DE TIPO DE DOCUMENTO
  // ==========================================

  Widget _buildTipoDocumentoField() {
    final isTouched = _touched['tipoDocumento'] == true;
    final error = _errors['tipoDocumento'];
    final hasError = isTouched && error != null;
    final isValid = isTouched && !hasError && _tipoDocumento != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFE53935)
                  : (isValid ? const Color(0xFF2E7D32) : Colors.transparent),
              width: (hasError || isValid) ? 1.5 : 0.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _tipoDocumento,
              hint: const Row(
                children: [
                  Icon(Icons.credit_card_outlined, color: Colors.grey),
                  SizedBox(width: 12),
                  Text(
                    'Tipo de documento *',
                    style: TextStyle(color: Colors.grey),
                  ),
                ],
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF12566B),
              ),
              items: AuthValidators.documentTypeOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.value,
                      child: Text(opt.label),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoDocumento = value;
                    _touched['tipoDocumento'] = true;
                    _errors.remove('tipoDocumento');
                    if (_documentoController.text.isNotEmpty ||
                        _touched['documento'] == true) {
                      _touched['documento'] = true;
                      final docErr = AuthValidators.validateDocumento(
                        _documentoController.text,
                        value,
                      );
                      if (docErr != null) {
                        _errors['documento'] = docErr;
                      } else {
                        _errors.remove('documento');
                      }
                      _triggerDocumentCheck(_documentoController.text, value);
                    }
                  });
                }
              },
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 8),
            child: Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 14,
                  color: Color(0xFFE53935),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    error,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFFE53935),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final nombreVal = _nombreController.text;
    final apellidoVal = _apellidoController.text;
    final documentoVal = _documentoController.text;
    final correoVal = _correoController.text;
    final telefonoVal = _telefonoController.text;
    final direccionVal = _direccionController.text;
    final passwordVal = _passwordController.text;
    final confirmVal = _confirmarPasswordController.text;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),

                  // Botón de regreso
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color:
                            const Color(0xFF12566B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new,
                        color: Color(0xFF12566B),
                        size: 20,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Crea tu Cuenta',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF12566B),
                    ),
                  ),

                  const SizedBox(height: 6),

                  const Text(
                    'Completa tus datos para registrarte como cliente en Mi Conductor.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.black54,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 1. TIPO DE DOCUMENTO
                  _buildTipoDocumentoField(),

                  const SizedBox(height: 12),

                  // 2. NÚMERO DE DOCUMENTO
                  CustomTextField(
                    labelText: 'Número de documento',
                    hintText: _tipoDocumento == 'PA'
                        ? 'Ej: AB123456'
                        : 'Ej: 1020304050',
                    requiredMark: true,
                    prefixIcon: Icons.badge_outlined,
                    controller: _documentoController,
                    focusNode: _documentoFocus,
                    keyboardType: _tipoDocumento == 'PA'
                        ? TextInputType.text
                        : TextInputType.number,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('documento'),
                    isValid: _isFieldValid('documento', documentoVal),
                    isValidating: _validating['documento'] == true,
                    onChanged: (val) {
                      if (_touched['documento'] == true || val.isNotEmpty) {
                        _touched['documento'] = true;
                        _validateField('documento');
                      }
                      _triggerDocumentCheck(val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // NOMBRES
                  CustomTextField(
                    labelText: 'Nombres',
                    hintText: 'Ej: Carlos Eduardo',
                    requiredMark: true,
                    prefixIcon: Icons.person_outline,
                    controller: _nombreController,
                    focusNode: _nombreFocus,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('nombre'),
                    isValid: _isFieldValid('nombre', nombreVal),
                    onChanged: (val) {
                      if (_touched['nombre'] == true || val.length >= 2) {
                        _touched['nombre'] = true;
                        _validateField('nombre');
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // APELLIDOS
                  CustomTextField(
                    labelText: 'Apellidos',
                    hintText: 'Ej: Pérez Gómez',
                    requiredMark: true,
                    prefixIcon: Icons.person_outline,
                    controller: _apellidoController,
                    focusNode: _apellidoFocus,
                    keyboardType: TextInputType.name,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('apellido'),
                    isValid: _isFieldValid('apellido', apellidoVal),
                    onChanged: (val) {
                      if (_touched['apellido'] == true || val.length >= 2) {
                        _touched['apellido'] = true;
                        _validateField('apellido');
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // CORREO ELECTRÓNICO
                  CustomTextField(
                    labelText: 'Correo electrónico',
                    hintText: 'nombre@dominio.com',
                    requiredMark: true,
                    prefixIcon: Icons.email_outlined,
                    controller: _correoController,
                    focusNode: _correoFocus,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('correo'),
                    isValid: _isFieldValid('correo', correoVal),
                    isValidating: _validating['correo'] == true,
                    onChanged: (val) {
                      if (_touched['correo'] == true || val.contains('@')) {
                        _touched['correo'] = true;
                        _validateField('correo');
                      }
                      _triggerEmailCheck(val);
                    },
                  ),

                  const SizedBox(height: 12),

                  // TELÉFONO
                  CustomTextField(
                    labelText: 'Número de teléfono',
                    hintText: '3001234567',
                    requiredMark: true,
                    prefixIcon: Icons.phone_outlined,
                    controller: _telefonoController,
                    focusNode: _telefonoFocus,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('telefono'),
                    isValid: _isFieldValid('telefono', telefonoVal),
                    onChanged: (val) {
                      if (_touched['telefono'] == true || val.length >= 7) {
                        _touched['telefono'] = true;
                        _validateField('telefono');
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // DIRECCIÓN
                  CustomTextField(
                    labelText: 'Dirección',
                    hintText: 'Ej: Calle 50 # 12-34',
                    requiredMark: true,
                    prefixIcon: Icons.location_on_outlined,
                    controller: _direccionController,
                    focusNode: _direccionFocus,
                    keyboardType: TextInputType.streetAddress,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('direccion'),
                    isValid: _isFieldValid('direccion', direccionVal),
                    onChanged: (val) {
                      if (_touched['direccion'] == true || val.length >= 5) {
                        _touched['direccion'] = true;
                        _validateField('direccion');
                      }
                    },
                  ),

                  const SizedBox(height: 12),

                  // CONTRASEÑA
                  CustomTextField(
                    labelText: 'Contraseña',
                    hintText: 'Mínimo 6 caracteres',
                    requiredMark: true,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    obscureText: _obscurePassword,
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    textInputAction: TextInputAction.next,
                    errorText: _getEffectiveError('password'),
                    isValid: _isFieldValid('password', passwordVal),
                    onChanged: (val) {
                      _touched['password'] = true;
                      _validateField('password');
                      if (_confirmarPasswordController.text.isNotEmpty ||
                          _touched['confirmPassword'] == true) {
                        _validateField('confirmPassword');
                      }
                    },
                  ),

                  // Indicador de seguridad y checklist en tiempo real
                  _buildPasswordRequirements(),

                  const SizedBox(height: 12),

                  // CONFIRMAR CONTRASEÑA
                  CustomTextField(
                    labelText: 'Confirmar contraseña',
                    hintText: 'Repite tu contraseña',
                    requiredMark: true,
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: _obscureConfirmPassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      });
                    },
                    obscureText: _obscureConfirmPassword,
                    controller: _confirmarPasswordController,
                    focusNode: _confirmarPasswordFocus,
                    textInputAction: TextInputAction.done,
                    errorText: _getEffectiveError('confirmPassword'),
                    isValid: _isFieldValid('confirmPassword', confirmVal),
                    onChanged: (val) {
                      _touched['confirmPassword'] = true;
                      _validateField('confirmPassword');
                    },
                  ),

                  const SizedBox(height: 20),

                  // TÉRMINOS Y CONDICIONES
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _aceptaTerminos,
                        activeColor: const Color(0xFF12566B),
                        onChanged: (value) {
                          setState(() {
                            _aceptaTerminos = value ?? false;
                            if (_aceptaTerminos && _aceptaPoliticas) {
                              _termsError = false;
                            }
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Acepto los Términos y Condiciones *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  // POLÍTICA DE PRIVACIDAD
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Checkbox(
                        value: _aceptaPoliticas,
                        activeColor: const Color(0xFF12566B),
                        onChanged: (value) {
                          setState(() {
                            _aceptaPoliticas = value ?? false;
                            if (_aceptaTerminos && _aceptaPoliticas) {
                              _termsError = false;
                            }
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Acepto la Política de Privacidad *',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ],
                  ),

                  if (_termsError)
                    const Padding(
                      padding: EdgeInsets.only(left: 12, bottom: 8),
                      child: Text(
                        'Debes aceptar los Términos y la Política de Privacidad.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFFE53935),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),

                  // BOTÓN CREAR CUENTA
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isFormValid ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12566B),
                        disabledBackgroundColor:
                            const Color(0xFF12566B).withValues(alpha: 0.4),
                        foregroundColor: Colors.white,
                        disabledForegroundColor: Colors.white70,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        elevation: _isFormValid ? 3 : 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              (_validating['correo'] == true ||
                                      _validating['documento'] == true)
                                  ? 'Verificando datos...'
                                  : 'Crear Cuenta',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // IR AL LOGIN
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (context) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          children: const [
                            TextSpan(
                              text: '¿Ya tienes cuenta? ',
                            ),
                            TextSpan(
                              text: 'Inicia Sesión',
                              style: TextStyle(
                                color: Color(0xFF12566B),
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
