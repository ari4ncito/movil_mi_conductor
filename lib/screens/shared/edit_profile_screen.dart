import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../services/cliente_service.dart';
import '../../services/conductor_service.dart';

class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color petrolPale = Color(0xFFE7F0F2);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color white = Colors.white;
}

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nombreController = TextEditingController();
  final _apellidoController = TextEditingController();
  final _documentoController = TextEditingController();
  final _correoController = TextEditingController();
  final _telefonoController = TextEditingController();
  final _direccionController = TextEditingController();
  final _experienciaController = TextEditingController();

  // Password change controllers
  final _nuevaPasswordController = TextEditingController();
  final _confirmarPasswordController = TextEditingController();

  String _tipoDocumento = 'CC';
  String _rol = '';
  String? _usuarioId;
  String? _clienteId;
  String? _conductorId;
  String _licencia = '';
  String _categoriaLicencia = '';

  bool _isLoading = true;
  bool _isSaving = false;
  bool _cambiarPassword = false;
  bool _obscureNuevaPassword = true;
  bool _obscureConfirmarPassword = true;

  final List<Map<String, String>> _tiposDocumento = const [
    {'value': 'CC', 'label': 'Cédula de Ciudadanía (CC)'},
    {'value': 'CE', 'label': 'Cédula de Extranjería (CE)'},
    {'value': 'PASAPORTE', 'label': 'Pasaporte'},
    {'value': 'PEP', 'label': 'PEP'},
    {'value': 'NIT', 'label': 'NIT'},
  ];

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _apellidoController.dispose();
    _documentoController.dispose();
    _correoController.dispose();
    _telefonoController.dispose();
    _direccionController.dispose();
    _experienciaController.dispose();
    _nuevaPasswordController.dispose();
    _confirmarPasswordController.dispose();
    super.dispose();
  }

  Future<void> _cargarDatos() async {
    try {
      final sessionUser = await AuthService.obtenerUsuario();
      if (!mounted) return;

      if (sessionUser != null) {
        _usuarioId = (sessionUser['_id'] ?? sessionUser['id'])?.toString();
        _rol = (sessionUser['rol'] is Map
                ? sessionUser['rol']['nombre']
                : sessionUser['rol'])
            ?.toString()
            .toUpperCase() ??
            '';

        // Pre-cargar con lo que está en sesión
        _nombreController.text = sessionUser['nombre']?.toString() ?? '';
        _apellidoController.text = sessionUser['apellido']?.toString() ?? '';
        _correoController.text = sessionUser['correo']?.toString() ?? '';
        _telefonoController.text = sessionUser['telefono']?.toString() ?? '';
        _documentoController.text = sessionUser['documento']?.toString() ?? '';
        final tipoDoc = sessionUser['tipoDocumento']?.toString().toUpperCase();
        if (tipoDoc != null && _tiposDocumento.any((t) => t['value'] == tipoDoc)) {
          _tipoDocumento = tipoDoc;
        }

        // Consultar API para obtener información completa y fresca
        if (_usuarioId != null) {
          try {
            final freshUser = await UsuarioService.obtenerPorId(_usuarioId!);
            if (mounted) {
              _nombreController.text = freshUser['nombre']?.toString() ?? _nombreController.text;
              _apellidoController.text = freshUser['apellido']?.toString() ?? _apellidoController.text;
              _correoController.text = freshUser['correo']?.toString() ?? _correoController.text;
              _telefonoController.text = freshUser['telefono']?.toString() ?? _telefonoController.text;
              _documentoController.text = freshUser['documento']?.toString() ?? _documentoController.text;
              final apiTipoDoc = freshUser['tipoDocumento']?.toString().toUpperCase();
              if (apiTipoDoc != null && _tiposDocumento.any((t) => t['value'] == apiTipoDoc)) {
                _tipoDocumento = apiTipoDoc;
              }
            }
          } catch (_) {
            // Continúa con datos de sesión si falla la red
          }

          // Cargar datos según rol
          if (_rol == 'CLIENTE') {
            try {
              final cliente = await ClienteService.obtenerClienteActual();
              if (mounted && cliente != null) {
                _clienteId = cliente['_id']?.toString() ?? cliente['id']?.toString();
                _direccionController.text = cliente['direccion']?.toString() ?? '';
              }
            } catch (_) {}
          } else if (_rol == 'CONDUCTOR') {
            try {
              final conductor = await ConductorService.obtenerPorUsuario(_usuarioId!);
              if (mounted) {
                _conductorId = conductor['_id']?.toString() ?? conductor['id']?.toString();
                _licencia = conductor['licencia']?.toString() ?? '';
                _categoriaLicencia = conductor['categoriaLicencia']?.toString() ?? '';
                _experienciaController.text = (conductor['experiencia'] ?? '0').toString();
              }
            } catch (_) {}
          }
        }
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarPerfil() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor revisa los campos señalados.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    if (_cambiarPassword) {
      if (_nuevaPasswordController.text.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('La nueva contraseña debe tener al menos 6 caracteres.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
      if (_nuevaPasswordController.text != _confirmarPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Las contraseñas no coinciden.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }
    }

    if (_usuarioId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró la sesión del usuario.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // 1. Actualizar usuario principal
      final datosUsuario = {
        'nombre': _nombreController.text.trim(),
        'apellido': _apellidoController.text.trim(),
        'tipoDocumento': _tipoDocumento,
        'documento': _documentoController.text.trim(),
        'correo': _correoController.text.trim().toLowerCase(),
        'telefono': _telefonoController.text.trim(),
      };

      if (_cambiarPassword && _nuevaPasswordController.text.trim().isNotEmpty) {
        datosUsuario['password'] = _nuevaPasswordController.text.trim();
      }

      await UsuarioService.actualizar(_usuarioId!, datosUsuario);

      // 2. Si es Cliente, actualizar dirección en Cliente
      if (_rol == 'CLIENTE' && _clienteId != null && _direccionController.text.trim().isNotEmpty) {
        try {
          await ClienteService.update(_clienteId!, {
            'direccion': _direccionController.text.trim(),
          });
        } catch (_) {
          // Ignorar si el endpoint de cliente no acepta update directo
        }
      }

      // 3. Si es Conductor, actualizar experiencia si se modificó
      if (_rol == 'CONDUCTOR' && _conductorId != null && _experienciaController.text.trim().isNotEmpty) {
        try {
          final expNum = int.tryParse(_experienciaController.text.trim()) ?? 0;
          await ConductorService.actualizar(_conductorId!, {
            'experiencia': expNum,
          });
        } catch (_) {}
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Text('Perfil actualizado correctamente.'),
            ],
          ),
          backgroundColor: Color(0xFF12566B),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSaving = false);

      String errorMsg = e.toString().replaceAll('Exception:', '').trim();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMsg.isEmpty ? 'Error al actualizar el perfil.' : errorMsg),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final initials = (_nombreController.text.isNotEmpty ? _nombreController.text[0] : '') +
        (_apellidoController.text.isNotEmpty ? _apellidoController.text[0] : '');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Editar Perfil',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.petrolBase),
            )
          : SafeArea(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Card con Avatar
                      _buildHeaderCard(initials),

                      const SizedBox(height: 24),

                      // Sección: Datos Personales
                      _buildSectionCard(
                        title: 'Datos Personales',
                        icon: Icons.person_rounded,
                        children: [
                          _buildTextField(
                            controller: _nombreController,
                            label: 'Nombre',
                            hint: 'Ingresa tu nombre',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El nombre es obligatorio.';
                              }
                              if (val.trim().length < 2) {
                                return 'Debe tener al menos 2 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _apellidoController,
                            label: 'Apellido',
                            hint: 'Ingresa tu apellido',
                            icon: Icons.badge_outlined,
                            textCapitalization: TextCapitalization.words,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El apellido es obligatorio.';
                              }
                              if (val.trim().length < 2) {
                                return 'Debe tener al menos 2 caracteres.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildDropdownTipoDocumento(),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _documentoController,
                            label: 'Número de Documento',
                            hint: 'Ej. 1020304050',
                            icon: Icons.pin_outlined,
                            keyboardType: TextInputType.text,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El documento es obligatorio.';
                              }
                              if (val.trim().length < 5) {
                                return 'Debe tener al menos 5 caracteres.';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // Sección: Contacto
                      _buildSectionCard(
                        title: 'Datos de Contacto',
                        icon: Icons.contact_mail_rounded,
                        children: [
                          _buildTextField(
                            controller: _correoController,
                            label: 'Correo Electrónico',
                            hint: 'ejemplo@correo.com',
                            icon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El correo es obligatorio.';
                              }
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(val.trim())) {
                                return 'Ingresa un correo electrónico válido.';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _telefonoController,
                            label: 'Número de Teléfono',
                            hint: 'Ej. 3001234567',
                            icon: Icons.phone_outlined,
                            keyboardType: TextInputType.phone,
                            validator: (val) {
                              if (val == null || val.trim().isEmpty) {
                                return 'El teléfono es obligatorio.';
                              }
                              if (val.trim().length < 7) {
                                return 'Debe tener al menos 7 dígitos.';
                              }
                              return null;
                            },
                          ),
                          if (_rol == 'CLIENTE') ...[
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _direccionController,
                              label: 'Dirección de Residencia',
                              hint: 'Ej. Calle 45 # 12-34',
                              icon: Icons.home_outlined,
                              textCapitalization: TextCapitalization.sentences,
                            ),
                          ],
                        ],
                      ),

                      // Sección para conductor: Licencia y Experiencia
                      if (_rol == 'CONDUCTOR') ...[
                        const SizedBox(height: 20),
                        _buildSectionCard(
                          title: 'Datos de Conducción',
                          icon: Icons.drive_eta_rounded,
                          children: [
                            if (_licencia.isNotEmpty) ...[
                              _buildInfoRow('Licencia de Conducción', _licencia, Icons.credit_card_rounded),
                              const SizedBox(height: 12),
                            ],
                            if (_categoriaLicencia.isNotEmpty) ...[
                              _buildInfoRow('Categoría', _categoriaLicencia, Icons.verified_rounded),
                              const SizedBox(height: 16),
                            ],
                            _buildTextField(
                              controller: _experienciaController,
                              label: 'Años de Experiencia',
                              hint: 'Ej. 3',
                              icon: Icons.timer_outlined,
                              keyboardType: TextInputType.number,
                              validator: (val) {
                                if (val != null && val.trim().isNotEmpty) {
                                  final n = int.tryParse(val.trim());
                                  if (n == null || n < 0) {
                                    return 'Debe ser un número válido.';
                                  }
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Sección: Cambiar Contraseña (Opcional)
                      _buildSecurityCard(),

                      const SizedBox(height: 32),

                      // Botón Guardar Cambios
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              colors: [AppColors.petrolBase, AppColors.petrolDark],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.petrolDark.withOpacity(0.3),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _guardarPerfil,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: AppColors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: _isSaving
                                ? const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      ),
                                      SizedBox(width: 12),
                                      Text(
                                        'Guardando...',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : const Text(
                                    'Guardar Cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Widget _buildHeaderCard(String initials) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.petrolLight, AppColors.petrolDark],
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.petrolDark.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: initials.isNotEmpty
                  ? Text(
                      initials.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.person, color: Colors.white, size: 40),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_nombreController.text} ${_apellidoController.text}'.trim().isEmpty
                      ? 'Mi Perfil'
                      : '${_nombreController.text} ${_apellidoController.text}'.trim(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  _correoController.text.isEmpty ? 'Modifica tus datos de perfil' : _correoController.text,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slateGray,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _rol.isEmpty ? 'Usuario' : _rol,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: AppColors.accentOrange,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.petrolPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: AppColors.petrolBase, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: textCapitalization,
          validator: validator,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9EACB2), fontSize: 14),
            prefixIcon: Icon(icon, color: AppColors.slateGray, size: 20),
            filled: true,
            fillColor: const Color(0xFFF7FAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.petrolBase, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownTipoDocumento() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tipo de Documento',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          value: _tiposDocumento.any((t) => t['value'] == _tipoDocumento) ? _tipoDocumento : 'CC',
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            prefixIcon: const Icon(Icons.assignment_ind_outlined, color: AppColors.slateGray, size: 20),
            filled: true,
            fillColor: const Color(0xFFF7FAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.petrolBase, width: 1.5),
            ),
          ),
          items: _tiposDocumento.map((tipo) {
            return DropdownMenuItem<String>(
              value: tipo['value'],
              child: Text(tipo['label']!),
            );
          }).toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() => _tipoDocumento = val);
            }
          },
        ),
      ],
    );
  }

  Widget _buildInfoRow(String title, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.petrolPale,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.petrolBase, size: 20),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.slateGray,
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.petrolDark,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.petrolPale,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.lock_outline_rounded, color: AppColors.petrolBase, size: 18),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Seguridad (Opcional)',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Switch(
                value: _cambiarPassword,
                activeColor: AppColors.accentOrange,
                onChanged: (val) {
                  setState(() {
                    _cambiarPassword = val;
                    if (!val) {
                      _nuevaPasswordController.clear();
                      _confirmarPasswordController.clear();
                    }
                  });
                },
              ),
            ],
          ),
          if (_cambiarPassword) ...[
            const SizedBox(height: 16),
            const Text(
              'Ingresa tu nueva contraseña para actualizarla:',
              style: TextStyle(fontSize: 13, color: AppColors.slateGray),
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _nuevaPasswordController,
              label: 'Nueva Contraseña',
              hint: 'Mínimo 6 caracteres',
              obscureText: _obscureNuevaPassword,
              onToggleVisibility: () {
                setState(() => _obscureNuevaPassword = !_obscureNuevaPassword);
              },
            ),
            const SizedBox(height: 14),
            _buildPasswordField(
              controller: _confirmarPasswordController,
              label: 'Confirmar Nueva Contraseña',
              hint: 'Repite la contraseña',
              obscureText: _obscureConfirmarPassword,
              onToggleVisibility: () {
                setState(() => _obscureConfirmarPassword = !_obscureConfirmarPassword);
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          style: const TextStyle(fontSize: 15, color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9EACB2), fontSize: 14),
            prefixIcon: const Icon(Icons.lock_outline, color: AppColors.slateGray, size: 20),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                color: AppColors.slateGray,
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFA),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.petrolBase, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}
