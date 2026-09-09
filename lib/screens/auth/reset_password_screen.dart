import 'package:flutter/material.dart';

import '/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String token;

  const ResetPasswordScreen({
    super.key,
    required this.token,
  });

  @override
  State<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends State<ResetPasswordScreen> {

  final TextEditingController _passwordController =
      TextEditingController();

  final TextEditingController _confirmarPasswordController =
      TextEditingController();

  bool _isLoading = false;
  bool _passwordUpdated = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    final password = _passwordController.text;
    final confirmarPassword =
        _confirmarPasswordController.text;

    if (password.isEmpty || confirmarPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Completa todos los campos.',
          ),
        ),
      );
      return;
    }

    if (password.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'La contraseña debe tener mínimo 6 caracteres.',
          ),
        ),
      );
      return;
    }

    if (password != confirmarPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Las contraseñas no coinciden.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.resetPassword(
        token: widget.token,
        password: password,
      );

      if (!mounted) return;

      setState(() {
        _passwordUpdated = true;
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
          ),
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

  void _volverLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (context) => const LoginScreen(),
      ),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,
              children: [

                const SizedBox(height: 20),

                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                  ),
                  onPressed: _volverLogin,
                ),

                const SizedBox(height: 30),

                if (!_passwordUpdated) ...[
                  const Text(
                    'Nueva Contraseña',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Crea una nueva contraseña para tu cuenta de Mi Conductor.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  CustomTextField(
                    labelText: 'NUEVA CONTRASEÑA',
                    hintText: 'Mínimo 6 caracteres',
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: Icons.visibility_off_outlined,
                    obscureText: true,
                    controller: _passwordController,
                  ),

                  const SizedBox(height: 16),

                  CustomTextField(
                    labelText: 'CONFIRMAR CONTRASEÑA',
                    hintText: 'Repite tu contraseña',
                    prefixIcon: Icons.lock_outlined,
                    suffixIcon: Icons.visibility_off_outlined,
                    obscureText: true,
                    controller:
                        _confirmarPasswordController,
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _resetPassword,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child:
                                  CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Cambiar Contraseña',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ] else ...[
                  Center(
                    child: Container(
                      width: 90,
                      height: 90,
                      decoration:
                          const BoxDecoration(
                        color: Color(0xFFE8F5E9),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_circle_outline,
                        color: Color(0xFF2E7D32),
                        size: 55,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  const Center(
                    child: Text(
                      '¡Contraseña actualizada!',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  Text(
                    'Tu contraseña ha sido cambiada correctamente. Ya puedes iniciar sesión con tu nueva contraseña.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _volverLogin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF8A00),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Volver al Inicio de Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}