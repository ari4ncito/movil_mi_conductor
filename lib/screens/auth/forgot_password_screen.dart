import 'package:flutter/material.dart';

import '/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends State<ForgotPasswordScreen> {

  final TextEditingController _emailController =
      TextEditingController();

  bool _isEmailSent = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetLink() async {
    final email = _emailController.text.trim();

    if (email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, ingresa tu correo electrónico.',
          ),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      await AuthService.forgotPassword(email);

      if (!mounted) return;

      setState(() {
        _isEmailSent = true;
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

                // Botón de regreso
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back,
                    color: Colors.black87,
                  ),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),

                const SizedBox(height: 30),

                // Título
                const Text(
                  '¿Olvidaste tu Contraseña?',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),

                const SizedBox(height: 12),

                Text(
                  'Ingresa tu correo electrónico y te enviaremos un enlace para restablecer tu contraseña.',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                    height: 1.5,
                  ),
                ),

                const SizedBox(height: 40),

                if (_isEmailSent)

                  // ==============================
                  // CORREO ENVIADO
                  // ==============================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE8F5E9),
                      borderRadius:
                          BorderRadius.circular(20),
                    ),
                    child: Column(
                      children: [

                        Container(
                          width: 80,
                          height: 80,
                          decoration:
                              const BoxDecoration(
                            color: Color(0xFFFF8A00),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.email_outlined,
                            color: Colors.white,
                            size: 40,
                          ),
                        ),

                        const SizedBox(height: 24),

                        const Text(
                          '¡Enlace enviado!',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Hemos enviado un enlace de restablecimiento a ${_emailController.text.trim()}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            height: 1.5,
                          ),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.of(context)
                                  .pop();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color(0xFFFF8A00),
                              foregroundColor:
                                  Colors.white,
                              padding:
                                  const EdgeInsets.symmetric(
                                vertical: 16,
                              ),
                              shape:
                                  RoundedRectangleBorder(
                                borderRadius:
                                    BorderRadius.circular(
                                  30,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Volver al Inicio de Sesión',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        TextButton(
                          onPressed: _isLoading
                              ? null
                              : () {
                                  setState(() {
                                    _isEmailSent =
                                        false;
                                  });
                                },
                          child: const Text(
                            'Reenviar enlace',
                            style: TextStyle(
                              fontSize: 14,
                              color:
                                  Color(0xFFFF8A00),
                              fontWeight:
                                  FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )

                else ...[

                  // ==============================
                  // CAMPO DE CORREO
                  // ==============================
                  CustomTextField(
                    labelText:
                        'CORREO ELECTRÓNICO',
                    hintText:
                        'ejemplo@dominio.com',
                    prefixIcon:
                        Icons.email_outlined,
                    keyboardType:
                        TextInputType.emailAddress,
                    controller:
                        _emailController,
                  ),

                  const SizedBox(height: 32),

                  // ==============================
                  // BOTÓN ENVIAR
                  // ==============================
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : _sendResetLink,
                      style:
                          ElevatedButton.styleFrom(
                        backgroundColor:
                            const Color(0xFFFF8A00),
                        foregroundColor:
                            Colors.white,
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
                              'Enviar Enlace',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}