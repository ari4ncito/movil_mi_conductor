import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _locationServicesEnabled = true;
  bool _darkModeEnabled = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Configuración',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Notifications
              _buildSettingsSection(
                title: 'Notificaciones',
                children: [
                  _buildSwitchOption(
                    icon: Icons.notifications_outlined,
                    label: 'Notificaciones Push',
                    value: _notificationsEnabled,
                    onChanged: (value) {
                      setState(() {
                        _notificationsEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Location
              _buildSettingsSection(
                title: 'Ubicación',
                children: [
                  _buildSwitchOption(
                    icon: Icons.location_on_outlined,
                    label: 'Servicios de Ubicación',
                    value: _locationServicesEnabled,
                    onChanged: (value) {
                      setState(() {
                        _locationServicesEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Appearance
              _buildSettingsSection(
                title: 'Apariencia',
                children: [
                  _buildSwitchOption(
                    icon: Icons.dark_mode_outlined,
                    label: 'Modo Oscuro',
                    value: _darkModeEnabled,
                    onChanged: (value) {
                      setState(() {
                        _darkModeEnabled = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 24),
              // Account
              _buildSettingsSection(
                title: 'Cuenta',
                children: [
                  _buildSimpleOption(
                    icon: Icons.lock_outlined,
                    label: 'Cambiar Contraseña',
                  ),
                  const SizedBox(height: 12),
                  _buildSimpleOption(
                    icon: Icons.delete_outlined,
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
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 12,
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
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF5F7F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: const Color(0xFFFF8A00),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFFF8A00),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleOption({
    required IconData icon,
    required String label,
    bool isDestructive = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDestructive
                  ? Colors.red.withOpacity(0.1)
                  : const Color(0xFFF5F7F8),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDestructive ? Colors.red : const Color(0xFFFF8A00),
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isDestructive ? Colors.red : Colors.black87,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right,
            color: Colors.grey[400],
            size: 24,
          ),
        ],
      ),
    );
  }
}
