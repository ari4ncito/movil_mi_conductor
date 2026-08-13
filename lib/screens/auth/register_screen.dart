import 'package:flutter/material.dart';
import '/widgets/custom_text_field.dart';
import '../client/client_section.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;

  void _register() async {
    setState(() {
      _isLoading = true;
    });
    // Simulate registration
    await Future.delayed(const Duration(seconds: 2));
    setState(() {
      _isLoading = false;
    });
    // Navigate to client section
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const ClientSection(isGuest: false)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                // Botón de regreso
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF5F7F8),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Crea tu Cuenta',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Regístrate como cliente para usar todos los servicios.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 40),
                const CustomTextField(
                  labelText: 'NOMBRE COMPLETO',
                  hintText: 'Tu nombre',
                  prefixIcon: Icons.person_outline,
                ),
                const SizedBox(height: 16),
                const CustomTextField(
                  labelText: 'CORREO ELECTRÓNICO',
                  hintText: 'ejemplo@dominio.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                const CustomTextField(
                  labelText: 'NÚMERO DE TELÉFONO',
                  hintText: '+123 456 7890',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                const CustomTextField(
                  labelText: 'CONTRASEÑA',
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: Icons.visibility_off_outlined,
                  obscureText: true,
                ),
                const SizedBox(height: 16),
                const CustomTextField(
                  labelText: 'CONFIRMAR CONTRASEÑA',
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: Icons.visibility_off_outlined,
                  obscureText: true,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Checkbox(
                      value: false,
                      onChanged: (value) {},
                    ),
                    Expanded(
                      child: Text(
                        'Acepto los Términos y Condiciones y la Política de Privacidad',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
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
                            'Crear Cuenta',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
                const SizedBox(height: 32),
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (context) => const LoginScreen()),
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
                          TextSpan(text: '¿Ya tienes cuenta? '),
                          TextSpan(
                            text: 'Inicia Sesión',
                            style: TextStyle(
                              color: Color(0xFFFF8A00),
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
    );
  }
}
