import 'package:flutter/material.dart';

import '/widgets/custom_text_field.dart';
import '../../services/auth_service.dart';
import '../client/client_section.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _isLoading = false;
  bool _aceptaTerminos = false;

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  // Tipo de documento
  String _tipoDocumento = 'CC';

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _passwordController.dispose();
    _confirmarPasswordController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    // Validar campos vacíos
    if (_nombreController.text.trim().isEmpty ||
        _apellidoController.text.trim().isEmpty ||
        _documentoController.text.trim().isEmpty ||
        _correoController.text.trim().isEmpty ||
        _telefonoController.text.trim().isEmpty ||
        _direccionController.text.trim().isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmarPasswordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Completa todos los campos.'),
        ),
      );

      return;
    }

    // Validar contraseñas
    if (_passwordController.text !=
        _confirmarPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Las contraseñas no coinciden.'),
        ),
      );

      return;
    }

    // Validar términos
    if (!_aceptaTerminos) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes aceptar los Términos y Condiciones.',
          ),
        ),
      );

      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Registrar cliente en el backend
      await AuthService.register(
        nombre: _nombreController.text.trim(),
        apellido: _apellidoController.text.trim(),
        tipoDocumento: _tipoDocumento,
        documento: _documentoController.text.trim(),
        correo: _correoController.text.trim(),
        password: _passwordController.text,
        telefono: _telefonoController.text.trim(),
        direccion: _direccionController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cuenta creada correctamente. Ahora puedes iniciar sesión.',
          ),
        ),
      );

      // Ir al Login
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.toString().replaceFirst('Exception: ', ''),
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

                // NOMBRE
                CustomTextField(
                  labelText: 'NOMBRE',
                  hintText: 'Tu nombre',
                  prefixIcon: Icons.person_outline,
                  controller: _nombreController,
                ),

                const SizedBox(height: 16),

                // APELLIDO
                CustomTextField(
                  labelText: 'APELLIDO',
                  hintText: 'Tu apellido',
                  prefixIcon: Icons.person_outline,
                  controller: _apellidoController,
                ),

                const SizedBox(height: 16),

                // TIPO DE DOCUMENTO
                DropdownButtonFormField<String>(
                  initialValue: _tipoDocumento,
                  decoration: InputDecoration(
                    labelText: 'TIPO DE DOCUMENTO',
                    prefixIcon: const Icon(
                      Icons.badge_outlined,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'CC',
                      child: Text(
                        'Cédula de Ciudadanía',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'TI',
                      child: Text(
                        'Tarjeta de Identidad',
                      ),
                    ),
                    DropdownMenuItem(
                      value: 'CE',
                      child: Text(
                        'Cédula de Extranjería',
                      ),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        _tipoDocumento = value;
                      });
                    }
                  },
                ),

                const SizedBox(height: 16),

                // DOCUMENTO
                CustomTextField(
                  labelText: 'NÚMERO DE DOCUMENTO',
                  hintText: 'Tu número de documento',
                  prefixIcon: Icons.badge_outlined,
                  controller: _documentoController,
                  keyboardType: TextInputType.number,
                ),

                const SizedBox(height: 16),

                // CORREO
                CustomTextField(
                  labelText: 'CORREO ELECTRÓNICO',
                  hintText: 'ejemplo@dominio.com',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  controller: _correoController,
                ),

                const SizedBox(height: 16),

                // TELÉFONO
                CustomTextField(
                  labelText: 'NÚMERO DE TELÉFONO',
                  hintText: '3001234567',
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  controller: _telefonoController,
                ),

                const SizedBox(height: 16),

                // DIRECCIÓN
                CustomTextField(
                  labelText: 'DIRECCIÓN',
                  hintText: 'Tu dirección',
                  prefixIcon: Icons.location_on_outlined,
                  controller: _direccionController,
                ),

                const SizedBox(height: 16),

                // CONTRASEÑA
                CustomTextField(
                  labelText: 'CONTRASEÑA',
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: Icons.visibility_off_outlined,
                  obscureText: true,
                  controller: _passwordController,
                ),

                const SizedBox(height: 16),

                // CONFIRMAR CONTRASEÑA
                CustomTextField(
                  labelText: 'CONFIRMAR CONTRASEÑA',
                  prefixIcon: Icons.lock_outlined,
                  suffixIcon: Icons.visibility_off_outlined,
                  obscureText: true,
                  controller: _confirmarPasswordController,
                ),

                const SizedBox(height: 24),

                // TÉRMINOS Y CONDICIONES
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _aceptaTerminos,
                      onChanged: (value) {
                        setState(() {
                          _aceptaTerminos = value ?? false;
                        });
                      },
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Text(
                          'Acepto los Términos y Condiciones y la Política de Privacidad',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // BOTÓN CREAR CUENTA
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _register,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF8A00),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        vertical: 16,
                      ),
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
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),

                // IR AL LOGIN
                Center(
                  child: TextButton(
                    onPressed: () {
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