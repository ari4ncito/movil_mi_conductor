import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../utils/validators.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;

  Future<void> _abrirCambiarPassword() async {
    final changed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _ChangePasswordDialog(),
    );

    if (changed == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 10),
              Expanded(
                child: Text('Contraseña actualizada correctamente.'),
              ),
            ],
          ),
          backgroundColor: Color(0xFF12566B),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E1E1E),
            letterSpacing: -0.5,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E1E1E), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications
              _buildSettingsSection(
                title: 'Preferencias',
                children: [
                  _buildSwitchOption(
                    icon: Icons.notifications_active_rounded,
                    label: 'Notificaciones Push',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                    // Uses default orange color
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFE0E0E0)),
                  _buildSwitchOption(
                    icon: Icons.location_on_rounded,
                    label: 'Servicios de Ubicación',
                    value: _locationServicesEnabled,
                    activeColor: const Color(0xFF12566B), // App's dark teal
                    onChanged: (value) {
                      setState(() {
                        _locationServicesEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 32),
              // Account
              _buildSettingsSection(
                title: 'Seguridad y Cuenta',
                children: [
                  _buildSimpleOption(
                    icon: Icons.lock_rounded,
                    label: 'Cambiar Contraseña',
                    iconColor: const Color(0xFF12566B), // App's dark teal
                    onTap: _abrirCambiarPassword,
                  ),
                  const Divider(height: 1, indent: 64, color: Color(0xFFE0E0E0)),
                  _buildSimpleOption(
                    icon: Icons.no_accounts_rounded,
                    label: 'Eliminar Cuenta',
                    isDestructive: true,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Color(0xFF8E8E93),
              letterSpacing: 1.2,
            ),
          ),
        ),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildSwitchOption({
    required IconData icon,
    required String label,
    required bool value,
    required Function(bool) onChanged,
    Color activeColor = const Color(0xFFFF8A00),
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: activeColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: activeColor,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2C2C2E),
              ),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: activeColor,
            activeTrackColor: activeColor.withOpacity(0.2),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleOption({
    required IconData icon,
    required String label,
    bool isDestructive = false,
    Color iconColor = const Color(0xFF607D8B),
    VoidCallback? onTap,
  }) {
    final bgColor = isDestructive
        ? Colors.red.withOpacity(0.1)
        : iconColor.withOpacity(0.1);

    final finalIconColor = isDestructive
        ? Colors.red
        : iconColor;

    return InkWell(
      onTap: onTap ?? () {},
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: finalIconColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDestructive ? const Color(0xFFD50000) : const Color(0xFF2C2C2E),
                ),
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: Colors.grey[400],
              size: 24,
            ),
          ],
        ),
      ),
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  const _ChangePasswordDialog();

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSubmitting = false;

  String? _currentError;
  String? _newError;
  String? _confirmError;
  String? _generalError;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  bool _validateFields() {
    final currentErr = AuthValidators.validateCurrentPassword(
      _currentPasswordController.text,
    );
    final newErr = AuthValidators.validateNewPassword(
      _newPasswordController.text,
    );
    final confirmErr = AuthValidators.validateConfirmPassword(
      _confirmPasswordController.text,
      _newPasswordController.text,
    );

    setState(() {
      _currentError = currentErr;
      _newError = newErr;
      _confirmError = confirmErr;
      _generalError = null;
    });

    return currentErr == null && newErr == null && confirmErr == null;
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_validateFields()) return;

    setState(() {
      _isSubmitting = true;
      _generalError = null;
    });

    try {
      await AuthService.changePassword(
        currentPassword: _currentPasswordController.text,
        newPassword: _newPasswordController.text,
        confirmPassword: _confirmPasswordController.text,
      );

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on AuthApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _currentError = e.fieldErrors['currentPassword'] ?? _currentError;
        _newError = e.fieldErrors['newPassword'] ?? _newError;
        _confirmError = e.fieldErrors['confirmPassword'] ?? _confirmError;
        if (e.message.toLowerCase().contains('contraseña actual')) {
          _currentError = e.message;
        } else if (e.fieldErrors.isEmpty) {
          _generalError = e.message;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _generalError =
            e.toString().replaceFirst('Exception: ', '').trim();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE7F0F2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.lock_rounded,
                    color: Color(0xFF12566B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Cambiar Contraseña',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF16262D),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting
                      ? null
                      : () => Navigator.of(context).pop(false),
                  icon: const Icon(Icons.close, color: Color(0xFF5C6B73), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (_generalError != null && _generalError!.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Text(
                  _generalError!,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 14),
            ],
            _buildPasswordInput(
              controller: _currentPasswordController,
              label: 'Contraseña Actual',
              hint: 'Ingresa tu contraseña actual',
              obscureText: _obscureCurrent,
              errorText: _currentError,
              onToggleVisibility: () {
                setState(() => _obscureCurrent = !_obscureCurrent);
              },
              onChanged: (_) {
                if (_currentError != null || _generalError != null) {
                  setState(() {
                    _currentError = null;
                    _generalError = null;
                  });
                }
              },
            ),
            const SizedBox(height: 14),
            _buildPasswordInput(
              controller: _newPasswordController,
              label: 'Nueva Contraseña',
              hint: 'Mínimo 6 caracteres',
              obscureText: _obscureNew,
              errorText: _newError,
              onToggleVisibility: () {
                setState(() => _obscureNew = !_obscureNew);
              },
              onChanged: (val) {
                setState(() {
                  _newError = val.isEmpty
                      ? null
                      : AuthValidators.validateNewPassword(val);
                  if (_confirmPasswordController.text.isNotEmpty) {
                    _confirmError = AuthValidators.validateConfirmPassword(
                      _confirmPasswordController.text,
                      val,
                    );
                  }
                  _generalError = null;
                });
              },
            ),
            const SizedBox(height: 14),
            _buildPasswordInput(
              controller: _confirmPasswordController,
              label: 'Confirmar Nueva Contraseña',
              hint: 'Repite la contraseña',
              obscureText: _obscureConfirm,
              errorText: _confirmError,
              onToggleVisibility: () {
                setState(() => _obscureConfirm = !_obscureConfirm);
              },
              onChanged: (val) {
                setState(() {
                  _confirmError = val.isEmpty
                      ? null
                      : AuthValidators.validateConfirmPassword(
                          val,
                          _newPasswordController.text,
                        );
                  _generalError = null;
                });
              },
            ),
            const SizedBox(height: 22),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF5C6B73),
                      side: const BorderSide(color: Color(0xFFE1E7E9)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Cancelar',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF12566B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Guardar',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPasswordInput({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscureText,
    required VoidCallback onToggleVisibility,
    required ValueChanged<String> onChanged,
    String? errorText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF16262D),
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: obscureText,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 15, color: Color(0xFF16262D)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFF9EACB2), fontSize: 14),
            errorText: errorText,
            prefixIcon: const Icon(
              Icons.lock_outline,
              color: Color(0xFF5C6B73),
              size: 20,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: const Color(0xFF5C6B73),
                size: 20,
              ),
              onPressed: onToggleVisibility,
            ),
            filled: true,
            fillColor: const Color(0xFFF7FAFA),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE1E7E9)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: Color(0xFF12566B),
                width: 1.5,
              ),
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
}
