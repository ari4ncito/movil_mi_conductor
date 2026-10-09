import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;

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
                color: Colors.black.withValues(alpha: 0.04),
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
              color: activeColor.withValues(alpha: 0.1),
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
            activeThumbColor: activeColor,
            activeTrackColor: activeColor.withValues(alpha: 0.2),
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
  }) {
    final bgColor = isDestructive 
        ? Colors.red.withValues(alpha: 0.1) 
        : iconColor.withValues(alpha: 0.1);
        
    final finalIconColor = isDestructive 
        ? Colors.red 
        : iconColor;

    return InkWell(
      onTap: () {
        // Implement navigation or action
      },
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

