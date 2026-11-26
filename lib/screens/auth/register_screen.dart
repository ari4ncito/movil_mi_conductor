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
      strengthColor = Colors.grey;
      strengthProgress = 0.0;
    } else if (score <= 1 || hasSpaces) {
      strengthText = 'Muy débil';
      strengthColor = const Color(0xFFE53935);
      strengthProgress = 0.2;
    } else if (score == 2) {
      strengthText = 'Débil';
      strengthColor = const Color(0xFFEF5350);
      strengthProgress = 0.4;
    } else if (score == 3) {
      strengthText = 'Media';
      strengthColor = Colors.amber.shade700;
      strengthProgress = 0.6;
    } else if (score == 4) {
      strengthText = 'Casi lista';
      strengthColor = const Color(0xFFFB9833);
      strengthProgress = 0.8;
    } else {
      strengthText = 'Segura';
      strengthColor = const Color(0xFF2E7D32);
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
            color: satisfied ? const Color(0xFF2E7D32) : Colors.grey,
          ),
          const SizedBox(width: 3),
          Text(
            text,
            style: TextStyle(
              fontSize: 10.5,
              color: satisfied ? const Color(0xFF2E7D32) : Colors.grey.shade700,
              fontWeight: satisfied ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      );
    }

    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Seguridad: ',
                style: TextStyle(fontSize: 10.5, color: Colors.grey.shade700),
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
                    backgroundColor: Colors.grey.shade200,
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
      children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFFF0F4F8),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasError
                  ? const Color(0xFFE53935)
                  : (isValid ? const Color(0xFF2E7D32) : Colors.transparent),
              width: (hasError || isValid) ? 1.5 : 0.0,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: _tipoDocumento,
              style: const TextStyle(
                fontSize: 12.5,
                color: Color(0xFF012538),
                fontWeight: FontWeight.w500,
              ),
              icon: const Icon(
                Icons.arrow_drop_down,
                color: Color(0xFF12566B),
                size: 20,
              ),
              items: AuthValidators.clientDocumentTypeOptions
                  .map(
                    (opt) => DropdownMenuItem<String>(
                      value: opt.value,
                      child: Text(
                        opt.value,
                        overflow: TextOverflow.ellipsis,
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
            padding: const EdgeInsets.only(top: 2, left: 6),
            child: Text(
              error,
              style: const TextStyle(
                fontSize: 10.5,
                color: Color(0xFFE53935),
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

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 20,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // CABECERA COMPACTA EN LÍNEA
                      Row(
                        children: [
                          GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: const Color(0xFF12566B)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(
                                Icons.arrow_back_ios_new,
                                color: Color(0xFF12566B),
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Crea tu Cuenta',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF12566B),
                                    height: 1.1,
                                  ),
                                ),
                                Text(
                                  'Regístrate como cliente en Mi Conductor',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: Colors.black54,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 10),

                      // 1. TIPO Y NÚMERO DE DOCUMENTO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildTipoDocumentoField(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 4,
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Documento',
                              hintText: _tipoDocumento == 'PA'
                                  ? 'AB123456'
                                  : '1020304050',
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
                              isValid: _isFieldValid('documento', documentoVal),
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 2. NOMBRES Y APELLIDOS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Nombres',
                              hintText: 'Carlos',
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
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Apellidos',
                              hintText: 'Pérez',
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 3. CORREO ELECTRÓNICO
                      CustomTextField(
                        compact: true,
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
                          if (_touched['correo'] == true || val.contains('@')) {
                            _touched['correo'] = true;
                            _validateField('correo');
                          }
                          _triggerEmailCheck(val);
                        },
                      ),

                      const SizedBox(height: 8),

                      // 4. FECHA DE NACIMIENTO (INMEDIATAMENTE DESPUÉS DE CORREO) Y TELÉFONO
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Fecha nac.',
                              hintText: 'DD/MM/AAAA',
                              requiredMark: true,
                              prefixIcon: Icons.calendar_today_outlined,
                              controller: _fechaNacimientoController,
                              readOnly: true,
                              onTap: _selectFechaNacimiento,
                              errorText: _getEffectiveError('fechaNacimiento'),
                              isValid: _isFieldValid('fechaNacimiento', fechaVal),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Celular',
                              hintText: '3001234567',
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
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // 5. DIRECCIÓN
                      CustomTextField(
                        compact: true,
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
                        isValid: _isFieldValid('direccion', direccionVal),
                        onChanged: (val) {
                          if (_touched['direccion'] == true ||
                              val.length >= 5) {
                            _touched['direccion'] = true;
                            _validateField('direccion');
                          }
                        },
                      ),

                      const SizedBox(height: 8),

                      // 6. CONTRASEÑA Y CONFIRMAR CONTRASEÑA
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Contraseña',
                              hintText: 'Mín. 8 car.',
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
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: CustomTextField(
                              compact: true,
                              labelText: 'Confirmar',
                              hintText: 'Repítela',
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
                              errorText: _getEffectiveError('confirmPassword'),
                              isValid: _isFieldValid(
                                'confirmPassword',
                                confirmVal,
                              ),
                              onChanged: (val) {
                                _touched['confirmPassword'] = true;
                                _validateField('confirmPassword');
                              },
                            ),
                          ),
                        ],
                      ),

                      // Indicador compacto de seguridad de contraseña en tiempo real
                      _buildPasswordRequirements(),

                      const SizedBox(height: 6),

                      // ACEPTACIÓN DE TÉRMINOS Y POLÍTICA DE TRATAMIENTO DE DATOS
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: 24,
                            width: 24,
                            child: Checkbox(
                              value: _aceptaTerminos,
                              activeColor: const Color(0xFF12566B),
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
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: Colors.black87,
                                  height: 1.3,
                                ),
                                children: [
                                  const TextSpan(
                                    text: 'He leído y acepto los ',
                                  ),
                                  TextSpan(
                                    text: 'términos y condiciones',
                                    recognizer: _terminosRecognizer,
                                    style: const TextStyle(
                                      color: Color(0xFF12566B),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(text: ' y la '),
                                  TextSpan(
                                    text:
                                        'política de tratamiento de datos personales',
                                    recognizer: _privacidadRecognizer,
                                    style: const TextStyle(
                                      color: Color(0xFF12566B),
                                      fontWeight: FontWeight.w600,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                  const TextSpan(
                                    text: ' *',
                                    style: TextStyle(color: Color(0xFFE53935)),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (_termsError)
                        const Padding(
                          padding: EdgeInsets.only(left: 32, top: 2),
                          child: Text(
                            'Debes aceptar los términos y condiciones y la política de tratamiento de datos personales.',
                            style: TextStyle(
                              fontSize: 10.5,
                              color: Color(0xFFE53935),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                      const SizedBox(height: 10),

                      // BOTÓN CREAR CUENTA
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isFormValid ? _register : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF12566B),
                            disabledBackgroundColor: const Color(0xFF12566B)
                                .withValues(alpha: 0.4),
                            foregroundColor: Colors.white,
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: _isFormValid ? 2 : 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
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
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ),

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
                                      builder: (context) => const LoginScreen(),
                                    ),
                                    (route) => false,
                                  );
                                },
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                fontSize: 12.5,
                                color: Colors.grey[600],
                              ),
                              children: const [
                                TextSpan(text: '¿Ya tienes cuenta? '),
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
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
