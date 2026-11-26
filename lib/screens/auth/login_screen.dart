import 'package:flutter/material.dart';
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

  // Paleta de identidad visual "Mi Conductor"
  static const Color _bgDeep = Color(0xFF012538);
  static const Color _bgDarker = Color(0xFF04141F);
  static const Color _petrolLight = Color(0xFF1B768E);
  static const Color _accentOrange = Color(0xFFFB9833);
  static const Color _cardSurface = Color(0xFF082231);
  static const Color _inputSurface = Color(0xFF041722);
  static const Color _errorRed = Color(0xFFF43F5E);
  static const Color _validGreen = Color(0xFF10B981);

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
      if (!mounted) return;
      setState(() {
        if (!_emailFocus.hasFocus) {
          _touched['correo'] = true;
          _errors['correo'] =
              AuthValidators.validateCorreo(_emailController.text);
        }
      });
    });
    _passwordFocus.addListener(() {
      if (!mounted) return;
      setState(() {
        if (!_passwordFocus.hasFocus) {
          _touched['password'] = true;
          _errors['password'] =
              AuthValidators.validatePassword(_passwordController.text);
        }
      });
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

  Widget _buildBrandInputField({
    required String label,
    required String hint,
    required IconData prefixIcon,
    required TextEditingController controller,
    required FocusNode focusNode,
    required ValueChanged<String> onChanged,
    String? errorText,
    bool isValid = false,
    bool obscureText = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    IconData? suffixIcon,
    VoidCallback? onSuffixIconTap,
  }) {
    final hasError = errorText != null && errorText.isNotEmpty;
    final hasFocus = focusNode.hasFocus;

    Color borderColor = Colors.white.withValues(alpha: 0.14);
    double borderWidth = 1.1;

    if (hasError) {
      borderColor = _errorRed;
      borderWidth = 1.5;
    } else if (hasFocus) {
      borderColor = _accentOrange;
      borderWidth = 1.5;
    } else if (isValid) {
      borderColor = _validGreen.withValues(alpha: 0.75);
      borderWidth = 1.4;
    }

    Color iconColor = _petrolLight;
    if (hasError) {
      iconColor = _errorRed;
    } else if (hasFocus) {
      iconColor = _accentOrange;
    } else if (isValid) {
      iconColor = _validGreen;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 7),
          child: Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: _inputSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: borderColor,
              width: borderWidth,
            ),
            boxShadow: hasFocus
                ? [
                    BoxShadow(
                      color: (hasError ? _errorRed : _accentOrange)
                          .withValues(alpha: 0.14),
                      blurRadius: 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : null,
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            obscureText: obscureText,
            keyboardType: keyboardType,
            textInputAction: textInputAction,
            onChanged: onChanged,
            style: const TextStyle(
              fontSize: 14.5,
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
            cursorColor: _accentOrange,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.32),
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(
                prefixIcon,
                size: 20,
                color: iconColor,
              ),
              suffixIcon: suffixIcon != null
                  ? GestureDetector(
                      onTap: onSuffixIconTap,
                      child: Icon(
                        suffixIcon,
                        size: 20,
                        color: hasError
                            ? _errorRed
                            : Colors.white.withValues(alpha: 0.55),
                      ),
                    )
                  : (isValid && !hasError
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: _validGreen,
                          size: 19,
                        )
                      : null),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
            ),
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1.5),
                  child: Icon(
                    Icons.error_outline_rounded,
                    size: 13,
                    color: _errorRed,
                  ),
                ),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    errorText,
                    style: const TextStyle(
                      fontSize: 12,
                      color: _errorRed,
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

  Widget _buildTrustPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 13,
            color: _accentOrange,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final emailVal = _emailController.text;
    final passwordVal = _passwordController.text;

    return Scaffold(
      backgroundColor: _bgDarker,
      body: Stack(
        children: [
          // Fondo nocturno con gradiente petrol profundo (estilo Hero de la marca)
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _bgDeep,
                    Color(0xFF073347),
                    _bgDarker,
                  ],
                  stops: [0.0, 0.45, 1.0],
                ),
              ),
              child: CustomPaint(
                painter: _LoginAmbientGridPainter(),
              ),
            ),
          ),

          // Destello cálido superior (bokeh naranja nocturno)
          Positioned(
            top: -70,
            right: -60,
            child: IgnorePointer(
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _accentOrange.withValues(alpha: 0.24),
                      _accentOrange.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Destello petrol inferior izquierdo
          Positioned(
            bottom: -90,
            left: -70,
            child: IgnorePointer(
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      _petrolLight.withValues(alpha: 0.26),
                      _petrolLight.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Contenido principal
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 430),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Logo circular oficial + nombre Mi Conductor.
                        Container(
                          width: 118,
                          height: 118,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _accentOrange.withValues(alpha: 0.85),
                              width: 2.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.45),
                                blurRadius: 22,
                                offset: const Offset(0, 10),
                              ),
                              BoxShadow(
                                color: _accentOrange.withValues(alpha: 0.22),
                                blurRadius: 24,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Transform.scale(
                              scale: 1.07,
                              child: Image.asset(
                                'assets/images/logo_mi_conductor.jpg',
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                  color: _bgDeep,
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.directions_car_filled_rounded,
                                    color: _accentOrange,
                                    size: 48,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontFamily: 'Arial',
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.3,
                            ),
                            children: [
                              TextSpan(text: 'Mi Conductor'),
                              TextSpan(
                                text: '.',
                                style: TextStyle(
                                  color: _accentOrange,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 22),

                        // Tarjeta del Formulario de Login (estilo glassmorphism oscuro)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
                          decoration: BoxDecoration(
                            color: _cardSurface.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.13),
                              width: 1.1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.42),
                                blurRadius: 30,
                                offset: const Offset(0, 16),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Encabezado de la tarjeta centrado
                              const Center(
                                child: Text(
                                  'Iniciar sesión',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.white,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 18),

                              // Campo Correo electrónico
                              _buildBrandInputField(
                                label: 'Correo electrónico',
                                hint: 'nombre@empresa.com',
                                prefixIcon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                controller: _emailController,
                                focusNode: _emailFocus,
                                errorText:
                                    _getEffectiveError('correo', emailVal),
                                isValid: _isFieldValid('correo', emailVal),
                                onChanged: (val) {
                                  setState(() {
                                    if (_touched['correo'] == true ||
                                        val.isNotEmpty) {
                                      _touched['correo'] = true;
                                      _errors['correo'] =
                                          AuthValidators.validateCorreo(val);
                                    }
                                  });
                                },
                              ),

                              const SizedBox(height: 15),

                              // Campo Contraseña
                              _buildBrandInputField(
                                label: 'Contraseña',
                                hint: '••••••••',
                                prefixIcon: Icons.lock_outline_rounded,
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
                                errorText:
                                    _getEffectiveError('password', passwordVal),
                                isValid: _isFieldValid('password', passwordVal),
                                onChanged: (val) {
                                  setState(() {
                                    if (_touched['password'] == true ||
                                        val.isNotEmpty) {
                                      _touched['password'] = true;
                                      _errors['password'] =
                                          AuthValidators.validatePassword(val);
                                    }
                                  });
                                },
                              ),

                              const SizedBox(height: 10),

                              // Recordarme y ¿Olvidaste tu contraseña?
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  InkWell(
                                    borderRadius: BorderRadius.circular(8),
                                    onTap: () {
                                      setState(() {
                                        _rememberMe = !_rememberMe;
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 4,
                                        horizontal: 2,
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: _accentOrange,
                                              checkColor: _bgDeep,
                                              side: BorderSide(
                                                color: Colors.white
                                                    .withValues(alpha: 0.38),
                                                width: 1.4,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            'Recordarme',
                                            style: TextStyle(
                                              fontSize: 12.5,
                                              color: Colors.white
                                                  .withValues(alpha: 0.75),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
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
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 4,
                                      ),
                                      minimumSize: Size.zero,
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      '¿Olvidaste tu contraseña?',
                                      style: TextStyle(
                                        fontSize: 12.5,
                                        color: _accentOrange,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 18),

                              // Botón principal: Iniciar Sesión (naranja #FB9833 con texto #012538)
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _login,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _accentOrange,
                                    foregroundColor: _bgDeep,
                                    disabledBackgroundColor:
                                        _accentOrange.withValues(alpha: 0.55),
                                    disabledForegroundColor: _bgDeep,
                                    elevation: 6,
                                    shadowColor:
                                        _accentOrange.withValues(alpha: 0.45),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 15,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: _bgDeep,
                                            strokeWidth: 2.3,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Text(
                                              'Iniciar Sesión',
                                              style: TextStyle(
                                                fontSize: 15.5,
                                                fontWeight: FontWeight.w800,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                            SizedBox(width: 8),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 18,
                                            ),
                                          ],
                                        ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Botón secundario: Entrar como Invitado
                              SizedBox(
                                width: double.infinity,
                                child: OutlinedButton(
                                  onPressed: _isLoading ? null : _guest,
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor:
                                        Colors.white.withValues(alpha: 0.05),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
                                    side: BorderSide(
                                      color: Colors.white.withValues(alpha: 0.24),
                                      width: 1.2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child: const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.bolt_rounded,
                                        size: 18,
                                        color: _accentOrange,
                                      ),
                                      SizedBox(width: 7),
                                      Text(
                                        'Entrar como Invitado',
                                        style: TextStyle(
                                          fontSize: 14.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 18),

                        // Sellos de confianza
                        Center(
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _buildTrustPill(
                                Icons.verified_user_rounded,
                                'Conductores verificados',
                              ),
                              _buildTrustPill(
                                Icons.route_rounded,
                                'Ruta en vivo',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Enlace de registro
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
                                  fontFamily: 'Arial',
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.70),
                                ),
                                children: const [
                                  TextSpan(text: '¿No tienes cuenta? '),
                                  TextSpan(
                                    text: 'Regístrate',
                                    style: TextStyle(
                                      color: _accentOrange,
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
            ),
          ),
        ],
      ),
    );
  }
}

// Painter sutil para líneas de cuadrícula vial en el fondo nocturno
class _LoginAmbientGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.035)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const double step = 44;
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
