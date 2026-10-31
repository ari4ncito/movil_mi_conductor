import 'package:flutter/material.dart';
import '/widgets/custom_text_field.dart';
import '../client/client_section.dart';
import '../driver/driver_section.dart';
import 'register_screen.dart';
import '../guest/guest_welcome_screen.dart';
import 'forgot_password_screen.dart';
import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _rememberMe = false;

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  final FocusNode _emailFocus = FocusNode();
  final FocusNode _passwordFocus = FocusNode();

  final Map<String, bool> _touched = {
    'correo': false,
    'password': false,
  };
  final Map<String, String?> _errors = {};

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() {
      if (!_emailFocus.hasFocus) {
        setState(() {
          _touched['correo'] = true;
          _errors['correo'] =
              AuthValidators.validateCorreo(_emailController.text);
        });
      }
    });
    _passwordFocus.addListener(() {
      if (!_passwordFocus.hasFocus) {
        setState(() {
          _touched['password'] = true;
          _errors['password'] =
              AuthValidators.validatePassword(_passwordController.text);
        });
      }
    });
  }

  bool _validateForm() {
    final correoErr = AuthValidators.validateCorreo(_emailController.text);
    final passwordErr =
        AuthValidators.validatePassword(_passwordController.text);

    setState(() {
      _touched['correo'] = true;
      _touched['password'] = true;
      _errors['correo'] = correoErr;
      _errors['password'] = passwordErr;
    });

    _formKey.currentState?.validate();

    return correoErr == null && passwordErr == null;
  }

  String? _getEffectiveError(String field, String currentVal) {
    final isTouched = _touched[field] == true || currentVal.isNotEmpty;
    if (!isTouched) return null;
    return _errors[field];
  }

  bool _isFieldValid(String field, String currentVal) {
    final isTouched = _touched[field] == true || currentVal.isNotEmpty;
    final hasError = _errors[field] != null && _errors[field]!.isNotEmpty;
    return isTouched && !hasError && currentVal.trim().isNotEmpty;
  }

  Future<void> _login() async {
    if (_isLoading) return;

    if (!_validateForm()) {
      return;
    }

    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text;

    setState(() {
      _isLoading = true;
    });

    try {
      final resultado = await AuthService.login(
        email,
        password,
      );

      final usuario = resultado['usuario'];
      final String rol = usuario['rol'];

      if (!mounted) return;

      if (rol == 'CLIENTE') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const ClientSection(isGuest: false),
          ),
          (route) => false,
        );
      } else if (rol == 'CONDUCTOR') {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const DriverSection(),
          ),
          (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Este usuario no tiene acceso a la aplicación móvil.',
            ),
            backgroundColor: Color(0xFFE53935),
          ),
        );
      }
    } catch (error) {
      if (!mounted) return;

      String displayMessage =
          error.toString().replaceFirst('Exception: ', '');

      if (error is AuthApiException && error.fieldErrors.isNotEmpty) {
        setState(() {
          if (error.fieldErrors.containsKey('correo')) {
            _errors['correo'] = error.fieldErrors['correo'];
            _touched['correo'] = true;
          }
          if (error.fieldErrors.containsKey('password')) {
            _errors['password'] = error.fieldErrors['password'];
            _touched['password'] = true;
          }
        });
      }

      if (displayMessage.isEmpty) {
        displayMessage = 'Correo o contraseña incorrectos.';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(displayMessage),
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

  void _guest() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const GuestWelcomeScreen()),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final emailVal = _emailController.text;
    final passwordVal = _passwordController.text;

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
                  const SizedBox(height: 40),
                  // Logo y título
                  Center(
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF12566B),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.directions_car,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Center(
                    child: Text(
                      'Mi Conductor',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF12566B),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Campos de texto
                  CustomTextField(
                    labelText: 'Correo electrónico',
                    hintText: 'ejemplo@dominio.com',
                    prefixIcon: Icons.email_outlined,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    controller: _emailController,
                    focusNode: _emailFocus,
                    errorText: _getEffectiveError('correo', emailVal),
                    isValid: _isFieldValid('correo', emailVal),
                    onChanged: (val) {
                      setState(() {
                        if (_touched['correo'] == true || val.isNotEmpty) {
                          _touched['correo'] = true;
                          _errors['correo'] =
                              AuthValidators.validateCorreo(val);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    labelText: 'Contraseña',
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: _obscurePassword
                        ? Icons.visibility_off_outlined
                        : Icons.visibility_outlined,
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    onSuffixIconTap: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    errorText: _getEffectiveError('password', passwordVal),
                    isValid: _isFieldValid('password', passwordVal),
                    onChanged: (val) {
                      setState(() {
                        if (_touched['password'] == true || val.isNotEmpty) {
                          _touched['password'] = true;
                          _errors['password'] =
                              AuthValidators.validatePassword(val);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Checkbox(
                            value: _rememberMe,
                            activeColor: const Color(0xFF12566B),
                            onChanged: (value) {
                              setState(() {
                                _rememberMe = value ?? false;
                              });
                            },
                          ),
                          Text(
                            'Recordarme',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ForgotPasswordScreen(),
                            ),
                          );
                        },
                        child: Text(
                          '¿Olvidaste tu contraseña?',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Botón de iniciar sesión
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF12566B),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
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
                          : const Text(
                              'Iniciar Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Botón de invitado
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : _guest,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        side: const BorderSide(color: Color(0xFFE0E0E0)),
                      ),
                      child: const Text(
                        'Entrar como Invitado',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Botón de registro
                  Center(
                    child: TextButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) =>
                                      const RegisterScreen(),
                                ),
                              );
                            },
                      child: RichText(
                        text: TextSpan(
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                          children: const [
                            TextSpan(text: '¿No tienes cuenta? '),
                            TextSpan(
                              text: 'Regístrate',
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
