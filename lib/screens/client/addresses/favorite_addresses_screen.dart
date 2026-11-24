import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../services/auth_service.dart';
import '../../../services/cliente_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app: azul petróleo, escalas de azul oscuro,
// grises y un acento en naranja.
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color white = Colors.white;
}

class FavoriteAddressesScreen extends StatefulWidget {
  const FavoriteAddressesScreen({super.key});

  @override
  State<FavoriteAddressesScreen> createState() => _FavoriteAddressesScreenState();
}

class _FavoriteAddressesScreenState extends State<FavoriteAddressesScreen> {
  bool _isLoading = true;
  String? _clienteId;
  String? _userId;
  List<Map<String, dynamic>> _direcciones = [];

  @override
  void initState() {
    super.initState();
    _cargarDirecciones();
  }

  Future<void> _cargarDirecciones() async {
    setState(() => _isLoading = true);
    try {
      final user = await AuthService.obtenerUsuario();
      final userId = user?['id']?.toString() ?? user?['_id']?.toString();
      _userId = userId;

      String direccionBackend = '';
      try {
        final cliente = await ClienteService.obtenerClienteActual();
        if (cliente != null) {
          _clienteId = (cliente['_id'] ?? cliente['id'])?.toString();
          direccionBackend = cliente['direccion']?.toString().trim() ?? '';
        }
      } catch (_) {}

      final prefs = await SharedPreferences.getInstance();
      final key = 'fav_addresses_${userId ?? "default"}';
      final savedJson = prefs.getString(key);

      List<Map<String, dynamic>> lista = [];
      if (savedJson != null && savedJson.isNotEmpty) {
        try {
          final decoded = jsonDecode(savedJson);
          if (decoded is List) {
            lista = decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
          }
        } catch (_) {}
      }

      // Si no hay direcciones guardadas y hay dirección en backend, inicializar con Casa
      if (lista.isEmpty) {
        if (direccionBackend.isNotEmpty) {
          lista.add({
            'id': 'casa_default',
            'label': 'Casa',
            'address': direccionBackend,
            'icon': 'home',
            'isDefault': true,
          });
          await prefs.setString(key, jsonEncode(lista));
        }
      } else if (direccionBackend.isNotEmpty) {
        // Asegurar que si existe "Casa" y la dirección en backend cambió, actualizarla o sincronizarla
        final indexCasa = lista.indexWhere((d) => d['label']?.toString().toLowerCase() == 'casa' || d['isDefault'] == true);
        if (indexCasa != -1 && (lista[indexCasa]['address'] == null || lista[indexCasa]['address'].toString().isEmpty)) {
          lista[indexCasa]['address'] = direccionBackend;
          await prefs.setString(key, jsonEncode(lista));
        }
      }

      if (mounted) {
        setState(() {
          _direcciones = lista;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _guardarDirecciones() async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'fav_addresses_${_userId ?? "default"}';
    await prefs.setString(key, jsonEncode(_direcciones));
  }

  IconData _getIconData(String? iconName) {
    switch (iconName?.toLowerCase()) {
      case 'home':
      case 'casa':
        return Icons.home_rounded;
      case 'work':
      case 'trabajo':
      case 'oficina':
        return Icons.work_rounded;
      case 'gym':
      case 'gimnasio':
      case 'favorite':
        return Icons.fitness_center_rounded;
      case 'school':
      case 'universidad':
        return Icons.school_rounded;
      case 'shopping':
      case 'tienda':
        return Icons.shopping_bag_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  void _abrirModalDireccion({Map<String, dynamic>? itemAEditar, int? index}) {
    final bool esEdicion = itemAEditar != null;
    final labelCtrl = TextEditingController(text: itemAEditar?['label'] ?? '');
    final addressCtrl = TextEditingController(text: itemAEditar?['address'] ?? '');
    String selectedIcon = itemAEditar?['icon'] ?? 'home';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom + 24,
                top: 24,
                left: 20,
                right: 20,
              ),
              decoration: const BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.borderGray,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      esEdicion ? 'Editar Dirección' : 'Agregar Dirección Favorita',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.petrolDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Guarda tus ubicaciones frecuentes para pedir tus viajes más rápido.',
                      style: TextStyle(fontSize: 13, color: AppColors.slateGray),
                    ),
                    const SizedBox(height: 20),

                    // Tipo / Icono
                    const Text(
                      'Categoría / Icono',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.petrolDark,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildIconOption(
                          iconName: 'home',
                          icon: Icons.home_rounded,
                          label: 'Casa',
                          isSelected: selectedIcon == 'home',
                          onTap: () => setModalState(() {
                            selectedIcon = 'home';
                            if (labelCtrl.text.isEmpty || labelCtrl.text == 'Trabajo' || labelCtrl.text == 'Gimnasio') {
                              labelCtrl.text = 'Casa';
                            }
                          }),
                        ),
                        _buildIconOption(
                          iconName: 'work',
                          icon: Icons.work_rounded,
                          label: 'Trabajo',
                          isSelected: selectedIcon == 'work',
                          onTap: () => setModalState(() {
                            selectedIcon = 'work';
                            if (labelCtrl.text.isEmpty || labelCtrl.text == 'Casa' || labelCtrl.text == 'Gimnasio') {
                              labelCtrl.text = 'Trabajo';
                            }
                          }),
                        ),
                        _buildIconOption(
                          iconName: 'gym',
                          icon: Icons.fitness_center_rounded,
                          label: 'Gimnasio',
                          isSelected: selectedIcon == 'gym',
                          onTap: () => setModalState(() {
                            selectedIcon = 'gym';
                            if (labelCtrl.text.isEmpty || labelCtrl.text == 'Casa' || labelCtrl.text == 'Trabajo') {
                              labelCtrl.text = 'Gimnasio';
                            }
                          }),
                        ),
                        _buildIconOption(
                          iconName: 'location',
                          icon: Icons.location_on_rounded,
                          label: 'Otro',
                          isSelected: selectedIcon == 'location',
                          onTap: () => setModalState(() => selectedIcon = 'location'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),

                    // Nombre / Etiqueta
                    const Text(
                      'Nombre o Etiqueta',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.petrolDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: labelCtrl,
                      decoration: InputDecoration(
                        hintText: 'Ej. Casa, Oficina, Casa de mamá',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderGray),
                        ),
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
                    const SizedBox(height: 16),

                    // Dirección completa
                    const Text(
                      'Dirección',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.petrolDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: addressCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: 'Ej. Calle 10 # 25 - 30, Barrio El Prado',
                        filled: true,
                        fillColor: AppColors.background,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.borderGray),
                        ),
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
                    const SizedBox(height: 24),

                    // Botón Guardar
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final nombre = labelCtrl.text.trim();
                          final direccion = addressCtrl.text.trim();
                          if (nombre.isEmpty || direccion.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Por favor ingresa nombre y dirección.'),
                                backgroundColor: Color(0xFFDC2626),
                              ),
                            );
                            return;
                          }

                          Navigator.of(ctx).pop();

                          setState(() {
                            if (esEdicion && index != null) {
                              _direcciones[index] = {
                                ..._direcciones[index],
                                'label': nombre,
                                'address': direccion,
                                'icon': selectedIcon,
                              };
                            } else {
                              _direcciones.add({
                                'id': DateTime.now().millisecondsSinceEpoch.toString(),
                                'label': nombre,
                                'address': direccion,
                                'icon': selectedIcon,
                                'isDefault': _direcciones.isEmpty,
                              });
                            }
                          });

                          await _guardarDirecciones();

                          // Si es Casa o la primera dirección, sincronizar también con el backend del cliente
                          if ((nombre.toLowerCase() == 'casa' || esEdicion && itemAEditar['isDefault'] == true) && _clienteId != null) {
                            try {
                              await ClienteService.update(_clienteId!, {'direccion': direccion});
                            } catch (_) {}
                          }

                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(esEdicion ? 'Dirección actualizada' : 'Dirección guardada exitosamente'),
                                backgroundColor: const Color(0xFF16A34A),
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.petrolBase,
                          foregroundColor: AppColors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                          elevation: 0,
                        ),
                        child: Text(
                          esEdicion ? 'Actualizar Dirección' : 'Guardar Dirección',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildIconOption({
    required String iconName,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accentOrange : AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? AppColors.accentOrange : AppColors.borderGray,
                width: 1.5,
              ),
            ),
            child: Icon(
              icon,
              color: isSelected ? Colors.white : AppColors.slateGray,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? AppColors.accentOrange : AppColors.slateGray,
            ),
          ),
        ],
      ),
    );
  }

  void _eliminarDireccion(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar Dirección'),
        content: Text('¿Deseas eliminar "${_direcciones[index]['label']}" de tus direcciones favoritas?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              setState(() {
                _direcciones.removeAt(index);
              });
              await _guardarDirecciones();
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Dirección eliminada'),
                    backgroundColor: AppColors.slateGray,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626)),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: const Text(
          'Direcciones Favoritas',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(true),
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.petrolBase),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_direcciones.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              Icon(
                                Icons.location_off_outlined,
                                size: 64,
                                color: AppColors.slateGray.withOpacity(0.5),
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'Aún no tienes direcciones guardadas',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                'Agrega tu casa, oficina o lugares frecuentes.',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.slateGray,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      ...List.generate(_direcciones.length, (index) {
                        final item = _direcciones[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildAddressCard(
                            icon: _getIconData(item['icon']?.toString()),
                            label: item['label']?.toString() ?? 'Dirección',
                            address: item['address']?.toString() ?? 'Sin dirección especificada',
                            onEdit: () => _abrirModalDireccion(itemAEditar: item, index: index),
                            onDelete: () => _eliminarDireccion(index),
                          ),
                        );
                      }),

                    const SizedBox(height: 16),

                    // Add new address button
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _abrirModalDireccion(),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.petrolDark,
                          backgroundColor: AppColors.petrolDark.withOpacity(0.04),
                          side: const BorderSide(color: AppColors.petrolDark, width: 1.5),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        icon: const Icon(Icons.add),
                        label: const Text(
                          'Agregar Dirección',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAddressCard({
    required IconData icon,
    required String label,
    required String address,
    required VoidCallback onEdit,
    required VoidCallback onDelete,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: AppColors.accentOrange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.slateGray,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: AppColors.background,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.edit,
                color: AppColors.slateGray,
                size: 16,
              ),
            ),
            onPressed: onEdit,
            tooltip: 'Editar',
          ),
          IconButton(
            icon: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.delete_outline,
                color: Color(0xFFDC2626),
                size: 16,
              ),
            ),
            onPressed: onDelete,
            tooltip: 'Eliminar',
          ),
        ],
      ),
    );
  }
}
