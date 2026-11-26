import 'dart:async';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';
import '../shared/terms_policies_screen.dart';
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
  bool _termsError = false;

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _fechaNacimientoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  DateTime? _fechaNacimiento;

  // FocusNodes para detectar 'blur' (pérdida de foco)
  final _nombreFocus = FocusNode();
  final _apellidoFocus = FocusNode();
  final _documentoFocus = FocusNode();
  final _correoFocus = FocusNode();
  final _telefonoFocus = FocusNode();
  final _direccionFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmarPasswordFocus = FocusNode();

  // Recognizers para enlaces legales
  late final TapGestureRecognizer _terminosRecognizer;
  late final TapGestureRecognizer _privacidadRecognizer;

  // Tipo de documento (CC por defecto)
  String _tipoDocumento = 'CC';

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

  // Timers de debounce (500ms)
  Timer? _correoDebounceTimer;
  Timer? _documentoDebounceTimer;

  DocumentRule get _currentDocRule =>
      AuthValidators.documentRules[_tipoDocumento] ??
      AuthValidators.documentRules['CC']!;

  @override
  void initState() {
    super.initState();

    _terminosRecognizer = TapGestureRecognizer()
      ..onTap = () => _abrirDocumentoLegal(
            TermsPoliciesScreen.defaultUrlTerminos,
          );
    _privacidadRecognizer = TapGestureRecognizer()
      ..onTap = () => _abrirDocumentoLegal(
            TermsPoliciesScreen.defaultUrlPrivacidad,
          );

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
    if (!mounted) return;
    setState(() {
      if (!node.hasFocus) {
        _touched[field] = true;
      }
    });
    if (!node.hasFocus) {
      _validateField(field);
    }
  }

  @override
  void dispose() {
    _correoDebounceTimer?.cancel();
    _documentoDebounceTimer?.cancel();

    _terminosRecognizer.dispose();
    _privacidadRecognizer.dispose();

    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    _fechaNacimientoController.dispose();
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

  Future<void> _abrirDocumentoLegal(String url) async {
    final uri = Uri.parse(url);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        await launchUrl(uri, mode: LaunchMode.platformDefault);
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const TermsPoliciesScreen()),
      );
    }
  }

  String _formatDateIso(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  String _formatDateDisplay(DateTime date) {
    final d = date.day.toString().padLeft(2, '0');
    final m = date.month.toString().padLeft(2, '0');
    final y = date.year.toString().padLeft(4, '0');
    return '$d/$m/$y';
  }

  Future<void> _selectFechaNacimiento() async {
    final now = DateTime.now();
    final initialDate = _fechaNacimiento ??
        DateTime(now.year - 20, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isAfter(now) ? now : initialDate,
      firstDate: DateTime(1900, 1, 1),
      lastDate: DateTime(now.year, now.month, now.day),
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF12566B),
              onPrimary: Colors.white,
              onSurface: Color(0xFF012538),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
        _fechaNacimientoController.text = _formatDateDisplay(picked);
        _touched['fechaNacimiento'] = true;
      });
      _validateField('fechaNacimiento');
    } else if (_touched['fechaNacimiento'] != true) {
      setState(() {
        _touched['fechaNacimiento'] = true;
      });
      _validateField('fechaNacimiento');
    }
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
      case 'fechaNacimiento':
        err = AuthValidators.validateFechaNacimiento(_fechaNacimiento);
        break;
      case 'telefono':
        err = AuthValidators.validateTelefono(_telefonoController.text);
        break;
      case 'direccion':
        err = AuthValidators.validateDireccion(_direccionController.text);
        break;
      case 'password':
        err = AuthValidators.validateRegistrationPassword(
          _passwordController.text,
        );
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

        if (!mounted || _correoController.text.trim() != trimmed) return;
        setState(() {
          if (exists) {
            _asyncErrors['correo'] =
                'Este correo electrónico ya está registrado.';
          } else {
            _asyncErrors.remove('correo');
          }
        });
      } catch (e) {
        if (!mounted || _correoController.text.trim() != trimmed) return;
        final msg = e.toString().toLowerCase();
        if (msg.contains('ya está registrado') || msg.contains('ya existe')) {
          setState(() {
            _asyncErrors['correo'] =
                'Este correo electrónico ya está registrado.';
          });
        }
      } finally {
        if (mounted && _correoController.text.trim() == trimmed) {
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

        if (!mounted || _documentoController.text.trim() != trimmed) return;
        setState(() {
          if (exists) {
            _asyncErrors['documento'] =
                'Este número de documento ya está registrado.';
          } else {
            _asyncErrors.remove('documento');
          }
        });
      } catch (e) {
        if (!mounted || _documentoController.text.trim() != trimmed) return;
        final msg = e.toString().toLowerCase();
        if (msg.contains('ya está registrado') || msg.contains('ya existe')) {
          setState(() {
            _asyncErrors['documento'] =
                'Este número de documento ya está registrado.';
          });
        }
      } finally {
        if (mounted && _documentoController.text.trim() == trimmed) {
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
    final hasEmpty = _documentoController.text.trim().isEmpty ||
        _nombreController.text.trim().isEmpty ||
        _apellidoController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _fechaNacimiento == null ||
        _telefonoController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmarPasswordController.text.isEmpty;

    if (hasEmpty || !_aceptaTerminos) return false;

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
            AuthValidators.validateFechaNacimiento(_fechaNacimiento) != null ||
            AuthValidators.validateTelefono(_telefonoController.text) != null ||
            AuthValidators.validateDireccion(_direccionController.text) !=
                null ||
            AuthValidators.validateRegistrationPassword(
                  _passwordController.text,
                ) !=
                null ||
            AuthValidators.validateConfirmPassword(
                  _confirmarPasswordController.text,
                  _passwordController.text,
                ) !=
                null;

    final hasErrors =
        _errors.isNotEmpty || _asyncErrors.isNotEmpty || hasValidationFailures;
    final isChecking =
        (_validating['correo'] == true) || (_validating['documento'] == true);

    return !hasErrors && !isChecking && !_isLoading;
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

    final errFecha = AuthValidators.validateFechaNacimiento(_fechaNacimiento);
    if (errFecha != null) _errors['fechaNacimiento'] = errFecha;

    final errTel = AuthValidators.validateTelefono(_telefonoController.text);
    if (errTel != null) _errors['telefono'] = errTel;

    final errDir = AuthValidators.validateDireccion(_direccionController.text);
    if (errDir != null) _errors['direccion'] = errDir;

    final errPass = AuthValidators.validateRegistrationPassword(
      _passwordController.text,
    );
    if (errPass != null) _errors['password'] = errPass;

    final errConf = AuthValidators.validateConfirmPassword(
      _confirmarPasswordController.text,
      _passwordController.text,
    );
    if (errConf != null) _errors['confirmPassword'] = errConf;

    setState(() {
      _touched['tipoDocumento'] = true;
      _touched['documento'] = true;
      _touched['nombre'] = true;
      _touched['apellido'] = true;
      _touched['correo'] = true;
      _touched['fechaNacimiento'] = true;
      _touched['telefono'] = true;
      _touched['direccion'] = true;
      _touched['password'] = true;
      _touched['confirmPassword'] = true;
      _termsError = !_aceptaTerminos;
    });

    _formKey.currentState?.validate();

    return _errors.isEmpty && _asyncErrors.isEmpty && _aceptaTerminos;
  }

  // ==========================================
  // REGISTRAR CLIENTE
  // ==========================================

  bool _esErrorDuplicado(Object e, String mensaje) {
    if (e is AuthApiException && e.statusCode == 409) return true;
    final msg = mensaje.toLowerCase();
    return msg.contains('registrad') || msg.contains('ya existe');
  }

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
        SnackBar(
          content: Text(
            !_aceptaTerminos
                ? 'Debes aceptar los términos y condiciones y la política de tratamiento de datos personales.'
                : 'Por favor corrige los campos con errores antes de continuar.',
          ),
          backgroundColor: const Color(0xFFE53935),
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
        fechaNacimiento: _formatDateIso(_fechaNacimiento!),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
        aceptaTerminos: true,
        fechaAceptacionTerminos: DateTime.now().toIso8601String(),
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
      } else if (_esErrorDuplicado(e, rawError) && rawError.toLowerCase().contains('correo')) {
        setState(() {
          _asyncErrors['correo'] = 'Este correo electrónico ya está registrado.';
          _touched['correo'] = true;
        });
      } else if (_esErrorDuplicado(e, rawError) && rawError.toLowerCase().contains('documento')) {
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
  // WIDGET COMPACTO DE SEGURIDAD DE CONTRASEÑA
  // ==========================================

  Widget _buildPasswordRequirements() {
    final pwd = _passwordController.text;
    final hasLength = pwd.length >= AuthValidators.minRegistrationPasswordLength &&
        pwd.length <= AuthValidators.maxPasswordLength;
    final hasUpper = AuthValidators.passwordUpperRegex.hasMatch(pwd);
    final hasLower = AuthValidators.passwordLowerRegex.hasMatch(pwd);
    final hasNumber = AuthValidators.passwordNumberRegex.hasMatch(pwd);
    final hasSpecial = AuthValidators.passwordSpecialRegex.hasMatch(pwd);
    final hasSpaces = RegExp(r'\s').hasMatch(pwd);

    int score = 0;
    if (hasLength) score++;
    if (hasUpper) score++;
    if (hasLower) score++;
    if (hasNumber) score++;
    if (hasSpecial) score++;

    String strengthText;
    Color strengthColor;
    double strengthProgress;

    if (pwd.isEmpty) {
      strengthText = 'Sin evaluar';
      strengthColor = Colors.white.withValues(alpha: 0.45);
      strengthProgress = 0.0;
    } else if (score <= 1 || hasSpaces) {
      strengthText = 'Muy débil';
      strengthColor = const Color(0xFFF43F5E);
      strengthProgress = 0.2;
    } else if (score == 2) {
      strengthText = 'Débil';
      strengthColor = const Color(0xFFFB7185);
      strengthProgress = 0.4;
    } else if (score == 3) {
      strengthText = 'Media';
      strengthColor = const Color(0xFFFBBF24);
      strengthProgress = 0.6;
    } else if (score == 4) {
      strengthText = 'Casi lista';
      strengthColor = const Color(0xFFFB9833);
      strengthProgress = 0.8;
    } else {
      strengthText = 'Segura';
      strengthColor = const Color(0xFF10B981);
      strengthProgress = 1.0;
    }

    Widget buildChip(String text, bool satisfied) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            satisfied
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            size: 12,
            color: satisfied
                ? const Color(0xFF10B981)
                : Colors.white.withValues(alpha: 0.38),
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              color: satisfied
                  ? const Color(0xFF6EE7B7)
                  : Colors.white.withValues(alpha: 0.62),
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 7),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF041722),
        borderRadius: BorderRadius.circular(11),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Seguridad: ',
                style: TextStyle(
                  fontSize: 10.5,
                  color: Colors.white.withValues(alpha: 0.65),
                ),
              ),
              Text(
                strengthText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: strengthColor,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: strengthProgress,
                    backgroundColor: Colors.white.withValues(alpha: 0.10),
                    valueColor: AlwaysStoppedAnimation<Color>(strengthColor),
                    minHeight: 4,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            spacing: 10,
            runSpacing: 3,
            children: [
              buildChip('8+ caracteres', hasLength),
              buildChip('Mayúscula', hasUpper),
              buildChip('Minúscula', hasLower),
              buildChip('Número', hasNumber),
              buildChip('Carácter especial', hasSpecial),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // SELECTOR COMPACTO DE TIPO DE DOCUMENTO
  // ==========================================

  Widget _buildTipoDocumentoField() {
    final isTouched = _touched['tipoDocumento'] == true;
    final error = _errors['tipoDocumento'];
    final hasError = isTouched && error != null;
    final isValid = isTouched && !hasError && _tipoDocumento.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 5),
          child: RichText(
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: TextStyle(
                fontFamily: 'Arial',
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: Colors.white.withValues(alpha: 0.74),
              ),
              children: const [
                TextSpan(text: 'TIPO DE DOCUMENTO'),
                TextSpan(
                  text: ' *',
                  style: TextStyle(
                    color: Color(0xFFFB9833),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 46,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: const Color(0xFF041722),
            borderRadius: BorderRadius.circular(13),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFF43F5E)
                  : (isValid
                      ? const Color(0xFF10B981).withValues(alpha: 0.75)
                      : Colors.white.withValues(alpha: 0.14)),
              width: (hasError || isValid) ? 1.4 : 1.1,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              dropdownColor: const Color(0xFF082231),
              value: _tipoDocumento,
              style: const TextStyle(
                fontFamily: 'Arial',
                fontSize: 13.5,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: Color(0xFFFB9833),
                size: 19,
              ),
              items: AuthValidators.clientDocumentTypeOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.value,
                      child: Row(
                        children: [
                          const Icon(
                            Icons.assignment_ind_outlined,
                            size: 17,
                            color: Color(0xFF1B768E),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              opt.label,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    _tipoDocumento = value;
                    _touched['tipoDocumento'] = true;
                    _errors.remove('tipoDocumento');

                    final nextRule = AuthValidators.documentRules[value] ??
                        AuthValidators.documentRules['CC']!;
                    String adjusted = _documentoController.text;
                    if (nextRule.numericOnly) {
                      adjusted = adjusted.replaceAll(RegExp(r'\D'), '');
                    } else {
                      adjusted = adjusted
                          .replaceAll(RegExp(r'[^0-9A-Za-z]'), '')
                          .toUpperCase();
                    }
                    if (adjusted.length > nextRule.maxLength) {
                      adjusted = adjusted.substring(0, nextRule.maxLength);
                    }
                    if (adjusted != _documentoController.text) {
                      _documentoController.text = adjusted;
                    }

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
            padding: const EdgeInsets.only(top: 3, left: 3),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFFF43F5E),
                fontWeight: FontWeight.w500,
              ),
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
    final fechaVal = _fechaNacimientoController.text;
    final telefonoVal = _telefonoController.text;
    final direccionVal = _direccionController.text;
    final passwordVal = _passwordController.text;
    final confirmVal = _confirmarPasswordController.text;

    final docFormatters = <TextInputFormatter>[
      if (_currentDocRule.numericOnly)
        FilteringTextInputFormatter.digitsOnly
      else
        FilteringTextInputFormatter.allow(RegExp(r'[0-9A-Za-z]')),
      LengthLimitingTextInputFormatter(_currentDocRule.maxLength),
    ];

    const Color bgDeep = Color(0xFF012538);
    const Color bgDarker = Color(0xFF04141F);
    const Color cardSurface = Color(0xFF082231);
    const Color accentOrange = Color(0xFFFB9833);

    return Scaffold(
      backgroundColor: bgDarker,
      body: Stack(
        children: [
          // Fondo nocturno sutil con la misma paleta del Login
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    bgDeep,
                    Color(0xFF073347),
                    bgDarker,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
            ),
          ),

          // Destello cálido superior ligero
          Positioned(
            top: -80,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentOrange.withValues(alpha: 0.18),
                      accentOrange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: 420,
                        minHeight: constraints.maxHeight - 20,
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // CABECERA COMPACTA CON BOTÓN VOLVER Y LOGO
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: () => Navigator.of(context).pop(),
                                  child: Container(
                                    width: 38,
                                    height: 38,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.08),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.white.withValues(alpha: 0.16),
                                      ),
                                    ),
                                    child: const Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Crea tu Cuenta',
                                        style: TextStyle(
                                          fontSize: 19,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.white,
                                          height: 1.1,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        'Regístrate como cliente en Mi Conductor',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          color:
                                              Colors.white.withValues(alpha: 0.68),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: accentOrange.withValues(alpha: 0.8),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: ClipOval(
                                    child: Transform.scale(
                                      scale: 1.07,
                                      child: Image.asset(
                                        'assets/images/logo_mi_conductor.jpg',
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                const Icon(
                                          Icons.directions_car_filled_rounded,
                                          color: accentOrange,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // TARJETA DEL FORMULARIO: CADA CAMPO TIENE SU PROPIA FILA DE ANCHO COMPLETO
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                              decoration: BoxDecoration(
                                color: cardSurface.withValues(alpha: 0.92),
                                borderRadius: BorderRadius.circular(22),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  width: 1.0,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.35),
                                    blurRadius: 24,
                                    offset: const Offset(0, 12),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // 1. TIPO DE DOCUMENTO (FILA PROPIA DE ANCHO COMPLETO)
                                  _buildTipoDocumentoField(),

                                  const SizedBox(height: 13),

                                  // 2. NÚMERO DE DOCUMENTO (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Número de documento',
                                    hintText: _tipoDocumento == 'PA'
                                        ? 'Ej. AB123456'
                                        : 'Ej. 1020304050',
                                    requiredMark: true,
                                    prefixIcon: Icons.badge_outlined,
                                    controller: _documentoController,
                                    focusNode: _documentoFocus,
                                    keyboardType: _tipoDocumento == 'PA'
                                        ? TextInputType.text
                                        : TextInputType.number,
                                    inputFormatters: docFormatters,
                                    maxLength: _currentDocRule.maxLength,
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('documento'),
                                    isValid:
                                        _isFieldValid('documento', documentoVal),
                                    isValidating: _validating['documento'] == true,
                                    onChanged: (val) {
                                      if (_touched['documento'] == true ||
                                          val.isNotEmpty) {
                                        _touched['documento'] = true;
                                        _validateField('documento');
                                      }
                                      _triggerDocumentCheck(val);
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 3. NOMBRES (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Nombres',
                                    hintText: 'Ej. Carlos Alberto',
                                    requiredMark: true,
                                    prefixIcon: Icons.person_outline,
                                    controller: _nombreController,
                                    focusNode: _nombreFocus,
                                    keyboardType: TextInputType.name,
                                    maxLength: AuthValidators.maxNombreLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxNombreLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('nombre'),
                                    isValid: _isFieldValid('nombre', nombreVal),
                                    onChanged: (val) {
                                      if (_touched['nombre'] == true ||
                                          val.length >= 2) {
                                        _touched['nombre'] = true;
                                        _validateField('nombre');
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 4. APELLIDOS (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Apellidos',
                                    hintText: 'Ej. Pérez Gómez',
                                    requiredMark: true,
                                    prefixIcon: Icons.person_outline,
                                    controller: _apellidoController,
                                    focusNode: _apellidoFocus,
                                    keyboardType: TextInputType.name,
                                    maxLength: AuthValidators.maxApellidoLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxApellidoLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('apellido'),
                                    isValid: _isFieldValid('apellido', apellidoVal),
                                    onChanged: (val) {
                                      if (_touched['apellido'] == true ||
                                          val.length >= 2) {
                                        _touched['apellido'] = true;
                                        _validateField('apellido');
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 5. CORREO ELECTRÓNICO (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Correo electrónico',
                                    hintText: 'nombre@dominio.com',
                                    requiredMark: true,
                                    prefixIcon: Icons.email_outlined,
                                    controller: _correoController,
                                    focusNode: _correoFocus,
                                    keyboardType: TextInputType.emailAddress,
                                    maxLength: AuthValidators.maxCorreoLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxCorreoLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('correo'),
                                    isValid: _isFieldValid('correo', correoVal),
                                    isValidating: _validating['correo'] == true,
                                    onChanged: (val) {
                                      if (_touched['correo'] == true ||
                                          val.contains('@')) {
                                        _touched['correo'] = true;
                                        _validateField('correo');
                                      }
                                      _triggerEmailCheck(val);
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 6. FECHA DE NACIMIENTO (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Fecha de nacimiento',
                                    hintText: 'DD/MM/AAAA',
                                    requiredMark: true,
                                    prefixIcon: Icons.calendar_today_outlined,
                                    controller: _fechaNacimientoController,
                                    readOnly: true,
                                    onTap: _selectFechaNacimiento,
                                    errorText:
                                        _getEffectiveError('fechaNacimiento'),
                                    isValid:
                                        _isFieldValid('fechaNacimiento', fechaVal),
                                  ),

                                  const SizedBox(height: 13),

                                  // 7. CELULAR (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Celular',
                                    hintText: 'Ej. 3001234567',
                                    requiredMark: true,
                                    prefixIcon: Icons.phone_outlined,
                                    controller: _telefonoController,
                                    focusNode: _telefonoFocus,
                                    keyboardType: TextInputType.phone,
                                    maxLength: AuthValidators.telefonoLength,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.telefonoLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('telefono'),
                                    isValid: _isFieldValid('telefono', telefonoVal),
                                    onChanged: (val) {
                                      if (_touched['telefono'] == true ||
                                          val.isNotEmpty) {
                                        _touched['telefono'] = true;
                                        _validateField('telefono');
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 8. DIRECCIÓN (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Dirección',
                                    hintText: 'Ej: Calle 50 # 12-34',
                                    requiredMark: true,
                                    prefixIcon: Icons.location_on_outlined,
                                    controller: _direccionController,
                                    focusNode: _direccionFocus,
                                    keyboardType: TextInputType.streetAddress,
                                    maxLength: AuthValidators.maxDireccionLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxDireccionLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('direccion'),
                                    isValid:
                                        _isFieldValid('direccion', direccionVal),
                                    onChanged: (val) {
                                      if (_touched['direccion'] == true ||
                                          val.length >= 5) {
                                        _touched['direccion'] = true;
                                        _validateField('direccion');
                                      }
                                    },
                                  ),

                                  const SizedBox(height: 13),

                                  // 9. CONTRASEÑA (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Contraseña',
                                    hintText: 'Mínimo 8 caracteres',
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
                                    maxLength: AuthValidators.maxPasswordLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxPasswordLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.next,
                                    errorText: _getEffectiveError('password'),
                                    isValid: _isFieldValid('password', passwordVal),
                                    onChanged: (val) {
                                      _touched['password'] = true;
                                      _validateField('password');
                                      if (_confirmarPasswordController
                                              .text.isNotEmpty ||
                                          _touched['confirmPassword'] == true) {
                                        _validateField('confirmPassword');
                                      }
                                    },
                                  ),

                                  // Indicador de seguridad de contraseña
                                  _buildPasswordRequirements(),

                                  const SizedBox(height: 13),

                                  // 10. CONFIRMAR CONTRASEÑA (FILA PROPIA DE ANCHO COMPLETO)
                                  CustomTextField(
                                    darkTheme: true,
                                    labelText: 'Confirmar contraseña',
                                    hintText: 'Repite tu contraseña',
                                    requiredMark: true,
                                    prefixIcon: Icons.lock_outlined,
                                    suffixIcon: _obscureConfirmPassword
                                        ? Icons.visibility_off_outlined
                                        : Icons.visibility_outlined,
                                    onSuffixIconTap: () {
                                      setState(() {
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword;
                                      });
                                    },
                                    obscureText: _obscureConfirmPassword,
                                    controller: _confirmarPasswordController,
                                    focusNode: _confirmarPasswordFocus,
                                    maxLength: AuthValidators.maxPasswordLength,
                                    inputFormatters: [
                                      LengthLimitingTextInputFormatter(
                                        AuthValidators.maxPasswordLength,
                                      ),
                                    ],
                                    textInputAction: TextInputAction.done,
                                    errorText:
                                        _getEffectiveError('confirmPassword'),
                                    isValid: _isFieldValid(
                                      'confirmPassword',
                                      confirmVal,
                                    ),
                                    onChanged: (val) {
                                      _touched['confirmPassword'] = true;
                                      _validateField('confirmPassword');
                                    },
                                  ),

                                  const SizedBox(height: 14),

                                  // ACEPTACIÓN DE TÉRMINOS Y POLÍTICA DE TRATAMIENTO DE DATOS
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: Checkbox(
                                          value: _aceptaTerminos,
                                          activeColor: accentOrange,
                                          checkColor: bgDeep,
                                          side: BorderSide(
                                            color: Colors.white
                                                .withValues(alpha: 0.42),
                                            width: 1.4,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(5),
                                          ),
                                          materialTapTargetSize:
                                              MaterialTapTargetSize.shrinkWrap,
                                          onChanged: (value) {
                                            setState(() {
                                              _aceptaTerminos = value ?? false;
                                              if (_aceptaTerminos) {
                                                _termsError = false;
                                              }
                                            });
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: TextStyle(
                                              fontFamily: 'Arial',
                                              fontSize: 12,
                                              color: Colors.white
                                                  .withValues(alpha: 0.78),
                                              height: 1.35,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text: 'He leído y acepto los ',
                                              ),
                                              TextSpan(
                                                text: 'términos y condiciones',
                                                recognizer: _terminosRecognizer,
                                                style: const TextStyle(
                                                  color: accentOrange,
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                              const TextSpan(text: ' y la '),
                                              TextSpan(
                                                text:
                                                    'política de tratamiento de datos personales',
                                                recognizer: _privacidadRecognizer,
                                                style: const TextStyle(
                                                  color: accentOrange,
                                                  fontWeight: FontWeight.w700,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                              const TextSpan(
                                                text: ' *',
                                                style: TextStyle(
                                                  color: Color(0xFFF43F5E),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (_termsError)
                                    const Padding(
                                      padding: EdgeInsets.only(left: 30, top: 3),
                                      child: Text(
                                        'Debes aceptar los términos y condiciones y la política de tratamiento de datos personales.',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFF43F5E),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),

                                  const SizedBox(height: 16),

                                  // BOTÓN CREAR CUENTA
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton(
                                      onPressed: _isFormValid ? _register : null,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: accentOrange,
                                        disabledBackgroundColor:
                                            Colors.white.withValues(alpha: 0.12),
                                        foregroundColor: bgDeep,
                                        disabledForegroundColor:
                                            Colors.white.withValues(alpha: 0.42),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 14,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        elevation: _isFormValid ? 4 : 0,
                                        shadowColor:
                                            accentOrange.withValues(alpha: 0.4),
                                      ),
                                      child: _isLoading
                                          ? const SizedBox(
                                              height: 18,
                                              width: 18,
                                              child: CircularProgressIndicator(
                                                color: bgDeep,
                                                strokeWidth: 2.2,
                                              ),
                                            )
                                          : Text(
                                              (_validating['correo'] == true ||
                                                      _validating['documento'] ==
                                                          true)
                                                  ? 'Verificando datos...'
                                                  : 'Crear Cuenta',
                                              style: const TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 10),

                            // IR AL LOGIN
                            Center(
                              child: TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                ),
                                onPressed: _isLoading
                                    ? null
                                    : () {
                                        Navigator.of(context).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                const LoginScreen(),
                                          ),
                                          (route) => false,
                                        );
                                      },
                                child: RichText(
                                  text: TextSpan(
                                    style: TextStyle(
                                      fontFamily: 'Arial',
                                      fontSize: 13.5,
                                      color: Colors.white.withValues(alpha: 0.70),
                                    ),
                                    children: const [
                                      TextSpan(text: '¿Ya tienes cuenta? '),
                                      TextSpan(
                                        text: 'Inicia Sesión',
                                        style: TextStyle(
                                          color: accentOrange,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
