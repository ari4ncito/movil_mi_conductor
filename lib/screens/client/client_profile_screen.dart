import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/client_profile_service.dart';
import '../shared/edit_profile_screen.dart';
import '../client/addresses/favorite_addresses_screen.dart';
import '../shared/help_support_screen.dart';
import '../shared/settings_screen.dart';
import '../shared/terms_policies_screen.dart';
import '../auth/login_screen.dart';
import '../../services/auth_service.dart';
import '../../services/usuario_service.dart';
import '../../services/cliente_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6); // gris muy claro azulado
  static const Color petrolDark = Color(0xFF0B3B4A); // azul petróleo oscuro
  static const Color petrolBase = Color(0xFF12566B); // azul petróleo base
  static const Color petrolLight = Color(0xFF1D7A94); // azul petróleo claro
  static const Color petrolPale = Color(0xFFE7F0F2);
  static const Color slateGray = Color(0xFF5C6B73); // gris azulado (texto secundario)
  static const Color borderGray = Color(0xFFE1E7E9); // gris claro (divisores)
  static const Color textPrimary = Color(0xFF16262D); // casi negro azulado
  static const Color accentOrange = Color(0xFFE8821E); // naranja de acento
  static const Color white = Colors.white;
}

class ClientProfileScreen extends StatefulWidget {
  const ClientProfileScreen({super.key});

  @override
  State<ClientProfileScreen> createState() => _ClientProfileScreenState();
}

class _ClientProfileScreenState extends State<ClientProfileScreen> {
  final ImagePicker _imagePicker = ImagePicker();

  bool _loading = true;
  bool _uploadingPhoto = false;

  String? _usuarioId;
  String? _clienteId;
  String _nombre = '';
  String _apellido = '';
  String _correo = '';
  String _telefono = '';
  String _documento = '';
  String _direccion = '';
  String _foto = '';

  @override
  void initState() {
    super.initState();
    _cargarUsuario();
  }

  Future<void> _cargarUsuario() async {
    try {
      final sessionUser = await AuthService.obtenerUsuario();
      if (!mounted) return;

      if (sessionUser != null) {
        final usuarioId = (sessionUser['_id'] ?? sessionUser['id'])?.toString();
        setState(() {
          _usuarioId = usuarioId;
          _nombre = sessionUser['nombre']?.toString() ?? '';
          _apellido = sessionUser['apellido']?.toString() ?? '';
          _correo = sessionUser['correo']?.toString() ?? '';
          _telefono = sessionUser['telefono']?.toString() ?? '';
          _documento = sessionUser['documento']?.toString() ?? '';
          _foto = sessionUser['foto']?.toString() ?? '';
          _loading = false;
        });

        if (usuarioId != null) {
          try {
            final cliente = await ClienteService.obtenerClienteActual();
            if (mounted && cliente != null) {
              final cid = (cliente['_id'] ?? cliente['id'])?.toString();
              final usuarioMap = cliente['usuario'] is Map
                  ? Map<String, dynamic>.from(cliente['usuario'] as Map)
                  : null;
              final fotoCliente = (cliente['foto'] ?? usuarioMap?['foto'])?.toString() ?? '';

              setState(() {
                _clienteId = cid ?? _clienteId;
                _direccion = cliente['direccion']?.toString() ?? _direccion;
                if (usuarioMap != null) {
                  _nombre = usuarioMap['nombre']?.toString() ?? _nombre;
                  _apellido = usuarioMap['apellido']?.toString() ?? _apellido;
                  _correo = usuarioMap['correo']?.toString() ?? _correo;
                  _telefono = usuarioMap['telefono']?.toString() ?? _telefono;
                  _documento = usuarioMap['documento']?.toString() ?? _documento;
                }
                if (fotoCliente.isNotEmpty) {
                  _foto = fotoCliente;
                }
              });

              if (fotoCliente.isNotEmpty) {
                ClientProfileService.instance.setPhotoUrl(fotoCliente, clientId: cid);
              }
            }
          } catch (_) {}

          try {
            final freshUser = await UsuarioService.obtenerPorId(usuarioId);
            if (mounted) {
              final freshFoto = freshUser['foto']?.toString() ?? '';
              setState(() {
                _nombre = freshUser['nombre']?.toString() ?? _nombre;
                _apellido = freshUser['apellido']?.toString() ?? _apellido;
                _correo = freshUser['correo']?.toString() ?? _correo;
                _telefono = freshUser['telefono']?.toString() ?? _telefono;
                _documento = freshUser['documento']?.toString() ?? _documento;
                if (freshFoto.isNotEmpty) {
                  _foto = freshFoto;
                }
              });
            }
          } catch (_) {}
        }
      } else {
        setState(() => _loading = false);
      }
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String get _nombreCompleto {
    final completo = '$_nombre $_apellido'.trim();
    return completo.isEmpty ? 'Cliente' : completo;
  }

  String get _initials {
    final first = _nombre.isNotEmpty ? _nombre[0].toUpperCase() : '';
    final second = _apellido.isNotEmpty ? _apellido[0].toUpperCase() : '';
    return '$first$second';
  }

  String get _currentFotoUrl {
    if (_foto.isNotEmpty) return _foto;
    return ClientProfileService.instance.profileNotifier.value.fotoUrl ?? '';
  }

  Future<void> _seleccionarYSubirFoto(ImageSource source) async {
    try {
      final XFile? picked = await _imagePicker.pickImage(
        source: source,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      if (picked == null || !mounted) return;

      setState(() => _uploadingPhoto = true);

      final Uint8List bytes = await picked.readAsBytes();
      final String? url = await ClientProfileService.instance.uploadProfilePhoto(
        bytes,
        clientId: _clienteId,
        usuarioId: _usuarioId,
        filename: picked.name,
      );

      if (!mounted) return;

      setState(() {
        _uploadingPhoto = false;
        if (url != null && url.isNotEmpty) {
          _foto = url;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                url != null ? Icons.check_circle : Icons.error_outline,
                color: Colors.white,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  url != null
                      ? 'Foto de perfil actualizada y sincronizada.'
                      : 'No se pudo subir la foto. Intenta nuevamente.',
                ),
              ),
            ],
          ),
          backgroundColor: url != null ? AppColors.petrolBase : Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _uploadingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al seleccionar la imagen: $e'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _mostrarOpcionesFoto() {
    final currentFoto = _currentFotoUrl;
    final localBytes = ClientProfileService.instance.profileNotifier.value.localImageBytes;
    final hasFoto = currentFoto.isNotEmpty || localBytes != null;

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Foto de perfil',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.petrolPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.photo_library_outlined, color: AppColors.petrolBase),
                ),
                title: const Text(
                  'Elegir de la galería',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarYSubirFoto(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: AppColors.accentOrange),
                ),
                title: const Text(
                  'Tomar una foto',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _seleccionarYSubirFoto(ImageSource.camera);
                },
              ),
              if (hasFoto)
                ListTile(
                  leading: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.zoom_in_outlined, color: AppColors.slateGray),
                  ),
                  title: const Text(
                    'Ver foto ampliada',
                    style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                  ),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    _mostrarDialogoFotoAmpliada(currentFoto, localBytes);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarDialogoFotoAmpliada(String currentFoto, Uint8List? localBytes) {
    final ImageProvider? imageProvider = currentFoto.isNotEmpty
        ? NetworkImage(currentFoto)
        : (localBytes != null ? MemoryImage(localBytes) : null);

    if (imageProvider == null) return;

    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.82),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
            Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
                image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Foto de perfil',
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                _mostrarOpcionesFoto();
              },
              icon: const Icon(Icons.camera_alt_outlined, size: 18),
              label: const Text('Cambiar foto'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accentOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.petrolBase,
          onRefresh: _cargarUsuario,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 12),
                // Tarjeta de información del usuario
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F3D44).withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _loading
                      ? const Center(
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: CircularProgressIndicator(color: AppColors.petrolBase),
                          ),
                        )
                      : ValueListenableBuilder<ClientProfile>(
                          valueListenable: ClientProfileService.instance.profileNotifier,
                          builder: (context, profileState, _) {
                            final currentFoto = _foto.isNotEmpty
                                ? _foto
                                : (profileState.fotoUrl ?? '');
                            final localBytes = profileState.localImageBytes;
                            final ImageProvider? avatarImage = currentFoto.isNotEmpty
                                ? NetworkImage(currentFoto)
                                : (localBytes != null ? MemoryImage(localBytes) : null);

                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    if (avatarImage != null) {
                                      _mostrarDialogoFotoAmpliada(currentFoto, localBytes);
                                    }
                                  },
                                  child: Container(
                                    width: 88,
                                    height: 88,
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        colors: [Color(0xFF1B5A63), Color(0xFF0B3B4A)],
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                      ),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0F3D44).withOpacity(0.25),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        ),
                                      ],
                                      image: avatarImage != null
                                          ? DecorationImage(
                                              image: avatarImage,
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                    ),
                                    child: avatarImage == null
                                        ? Center(
                                            child: _initials.isNotEmpty
                                                ? Text(
                                                    _initials,
                                                    style: const TextStyle(
                                                      fontSize: 30,
                                                      fontWeight: FontWeight.bold,
                                                      color: AppColors.white,
                                                    ),
                                                  )
                                                : const Icon(
                                                    Icons.person,
                                                    color: AppColors.white,
                                                    size: 44,
                                                  ),
                                          )
                                        : null,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  _nombreCompleto,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    fontSize: 21,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF10B981).withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.verified_rounded, size: 14, color: Color(0xFF059669)),
                                      SizedBox(width: 5),
                                      Text(
                                        'Cliente Verificado',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF059669),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                ),
                const SizedBox(height: 20),
                // Opciones del perfil
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F3D44).withOpacity(0.04),
                        blurRadius: 18,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      _buildProfileOption(
                        icon: Icons.edit_rounded,
                        label: 'Editar Perfil',
                        onTap: () async {
                          final updated = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const EditProfileScreen(),
                            ),
                          );
                          if (updated == true) {
                            _cargarUsuario();
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileOption(
                        icon: Icons.location_on_rounded,
                        label: 'Direcciones Favoritas',
                        onTap: () async {
                          final updated = await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const FavoriteAddressesScreen(),
                            ),
                          );
                          if (updated == true) {
                            _cargarUsuario();
                          }
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileOption(
                        icon: Icons.help_outline_rounded,
                        label: 'Ayuda y Soporte',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileOption(
                        icon: Icons.settings_rounded,
                        label: 'Configuración',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const SettingsScreen(),
                            ),
                          );
                        },
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20, color: Color(0xFFF1F5F9)),
                      _buildProfileOption(
                        icon: Icons.privacy_tip_outlined,
                        label: 'Términos y Políticas',
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const TermsPoliciesScreen(),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Logout button
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [AppColors.petrolBase, AppColors.petrolDark],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.petrolDark.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: () async {
                        await AuthService.logout();

                        if (!context.mounted) return;

                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(
                            builder: (context) => const LoginScreen(),
                          ),
                          (route) => false,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Cerrar Sesión',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
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
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.petrolBase.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.petrolBase,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slateGray,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.accentOrange.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: AppColors.accentOrange,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.petrolBase,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
