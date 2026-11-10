import 'dart:async';
import 'package:flutter/material.dart';

import '../../../../services/auth_service.dart';
import '../../../../services/vehiculo_service.dart';
import 'add_vehicle_screen.dart';

// ─────────────────────────────────────────────
// Paleta de colores oficial de la app
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
  static const Color accentOrangeBg = Color(0xFFFCEADA);
  static const Color white = Colors.white;
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEE2E2);
  static const Color success = Color(0xFF16A34A);
  static const Color successBg = Color(0xFFDCFCE7);
  static const Color purple = Color(0xFF9333EA);
  static const Color purpleBg = Color(0xFFF3E8FF);
}

// ─────────────────────────────────────────────
// Pantalla principal de Mis Vehículos
// ─────────────────────────────────────────────
class MyVehiclesScreen extends StatefulWidget {
  const MyVehiclesScreen({super.key});

  @override
  State<MyVehiclesScreen> createState() => _MyVehiclesScreenState();
}

class _MyVehiclesScreenState extends State<MyVehiclesScreen> {
  List<dynamic> _vehicles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarVehiculos();
  }

  // Carga los vehículos del cliente y excluye los que estén en estado 'vendido' (igual que la web)
  Future<void> _cargarVehiculos() async {
    setState(() => _isLoading = true);
    try {
      final usuarioId = await AuthService.obtenerUsuarioId();
      if (usuarioId != null) {
        final vehiculos = await VehiculoService.obtenerPorCliente(usuarioId);
        // Filtrar vehículos vendidos
        final listables = vehiculos.where((v) {
          final estado = (v['estadoVehiculo'] ?? (v['estado'] == false ? 'inactivo' : 'activo'))
              .toString()
              .toLowerCase();
          return estado != 'vendido';
        }).toList();

        if (mounted) {
          setState(() {
            _vehicles = listables;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addVehicle() async {
    final vehiculoCreado = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AddVehicleScreen()),
    );

    if (vehiculoCreado == true && mounted) {
      _cargarVehiculos();
    }
  }

  Future<void> _editVehicle(dynamic vehicle) async {
    final actualizado = await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AddVehicleScreen(vehicleToEdit: vehicle)),
    );
    if (actualizado == true && mounted) {
      _cargarVehiculos();
    }
  }

  Future<void> _removeVehicle(dynamic vehicle) async {
    final id = (vehicle['_id'] ?? vehicle['id'])?.toString();
    if (id == null) return;

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 28),
            SizedBox(width: 8),
            Expanded(
              child: Text('Eliminar vehículo', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            ),
          ],
        ),
        content: Text(
          '¿Estás seguro de que deseas eliminar el vehículo ${vehicle['marca'] ?? ''} (${vehicle['placa'] ?? ''})? Esta acción no se puede deshacer.',
          style: const TextStyle(color: AppColors.slateGray, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      setState(() => _isLoading = true);
      await VehiculoService.delete(id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.success,
            content: Text('Vehículo eliminado exitosamente.'),
          ),
        );
        _cargarVehiculos();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.danger,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
        setState(() => _isLoading = false);
      }
    }
  }

  // ─────────────────────────────────────────────
  // MODAL DE CAMBIO DE ESTADO (IGUAL QUE EN LA WEB)
  // ─────────────────────────────────────────────
  void _mostrarModalCambioEstado(dynamic vehicle) {
    final id = (vehicle['_id'] ?? vehicle['id'])?.toString();
    if (id == null) return;

    final estadoActual = (vehicle['estadoVehiculo'] ?? (vehicle['estado'] == false ? 'inactivo' : 'activo'))
        .toString()
        .toLowerCase();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ChangeVehicleStatusModalSheet(
        vehicle: vehicle,
        initialStatus: estadoActual,
        onStatusChanged: (nuevoEstado, motivo) async {
          await VehiculoService.cambiarEstado(
            id,
            estadoVehiculo: nuevoEstado,
            motivo: motivo,
          );
          if (mounted) {
            final msg = nuevoEstado == 'vendido'
                ? 'Vehículo marcado como VENDIDO. Ha sido desvinculado de tus vehículos activos.'
                : 'Estado del vehículo actualizado a ${_getEstadoLabel(nuevoEstado)}.';
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: nuevoEstado == 'vendido' ? AppColors.purple : AppColors.success,
                content: Text(msg),
              ),
            );
            _cargarVehiculos();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabecera
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 12, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Mis vehículos',
                          style: TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _vehicles.isEmpty
                              ? 'Administra los vehículos asociados a tu cuenta.'
                              : '${_vehicles.length} ${_vehicles.length == 1 ? "vehículo activo" : "vehículos activos"}',
                          style: const TextStyle(color: AppColors.slateGray, fontSize: 13),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Actualizar lista',
                    onPressed: _cargarVehiculos,
                    icon: const Icon(Icons.refresh_rounded, color: AppColors.petrolBase),
                  ),
                ],
              ),
            ),

            // Contenido: Grid adaptable sin espacios vacíos excesivos
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.petrolBase),
                    )
                  : _vehicles.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          color: AppColors.petrolBase,
                          onRefresh: _cargarVehiculos,
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              final width = constraints.maxWidth;
                              // 2 columnas en móvil, 3 o 4 en pantallas más anchas
                              final crossAxisCount = width > 800 ? 4 : (width > 550 ? 3 : 2);
                              const spacing = 12.0;
                              final itemWidth = (width - 32 - (spacing * (crossAxisCount - 1))) / crossAxisCount;
                              
                              // Altura ideal de la tarjeta: ~215-225 px
                              // Esto elimina por completo el espacio vacío vertical
                              const idealHeight = 242.0;
                              final childAspectRatio = (itemWidth / idealHeight).clamp(0.72, 1.25);

                              return GridView.builder(
                                padding: const EdgeInsets.fromLTRB(16, 6, 16, 20),
                                physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
                                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: crossAxisCount,
                                  crossAxisSpacing: spacing,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: childAspectRatio,
                                ),
                                itemCount: _vehicles.length,
                                itemBuilder: (context, index) {
                                  return _buildVehicleGridCard(_vehicles[index]);
                                },
                              );
                            },
                          ),
                        ),
            ),

            // Botón inferior para agregar vehículo
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _addVehicle,
                  icon: const Icon(Icons.add_rounded, size: 22),
                  label: const Text(
                    'Agregar vehículo',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.petrolBase,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: AppColors.petrolBase.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.directions_car_outlined,
                size: 56,
                color: AppColors.petrolBase,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Aún no tienes vehículos registrados',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Registra tu vehículo con su tarjeta de propiedad y fotos para solicitar servicios en la plataforma.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.slateGray,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // CARD DE VEHÍCULO (2 POR FILA, IMAGEN ARRIBA, DATOS DEBAJO)
  // ─────────────────────────────────────────────
   Widget _buildVehicleGridCard(dynamic vehicle) {
    final images = _extractVehicleImages(vehicle);
    final estado = (vehicle['estadoVehiculo'] ?? (vehicle['estado'] == false ? 'inactivo' : 'activo'))
        .toString()
        .toLowerCase();

    final statusStyle = _getStatusStyle(estado);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderGray.withOpacity(0.8), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => _showVehicleDetails(vehicle),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. IMAGEN / CARRUSEL (Reducido ligeramente a 105 de alto para dar espacio)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                child: SizedBox(
                  height: 105, 
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: VehicleCardImageCarousel(
                          images: images,
                          tipoVehiculo: vehicle['tipoVehiculo']?.toString() ?? 'Automóvil',
                        ),
                      ),
                      // Badge de estado flotante en la foto
                      Positioned(
                        top: 8,
                        left: 8,
                        child: GestureDetector(
                          onTap: () => _mostrarModalCambioEstado(vehicle),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: statusStyle['bg'] as Color,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: (statusStyle['border'] as Color), width: 0.8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.12),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: statusStyle['color'] as Color,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  statusStyle['label'] as String,
                                  style: TextStyle(
                                    color: statusStyle['color'] as Color,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // 2. DATOS DEL VEHÍCULO
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Marca y Modelo
                      Text(
                        '${vehicle['marca'] ?? ''} ${vehicle['modelo'] ?? ''}'.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 14, // Un poco más grande
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 6),

                      // Placa + Color
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFF7D6),
                              borderRadius: BorderRadius.circular(5),
                              border: Border.all(color: const Color(0xFFE6CA65), width: 1),
                            ),
                            child: Text(
                              (vehicle['placa'] ?? '').toString().toUpperCase(),
                              style: const TextStyle(
                                color: Color(0xFF2B2003),
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                fontFamily: 'monospace',
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              vehicle['color'] ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.slateGray,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      
                      // Año y tipo (Oculto si el espacio es muy reducido)
                      const Spacer(),

                      // Barra de acciones compacta
                      Container(
                        padding: const EdgeInsets.only(top: 8),
                        decoration: BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.borderGray.withOpacity(0.6))),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Botón Estado
                            Flexible(
                              child: InkWell(
                                onTap: () => _mostrarModalCambioEstado(vehicle),
                                borderRadius: BorderRadius.circular(6),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: (statusStyle['bg'] as Color),
                                    borderRadius: BorderRadius.circular(6),
                                    border: Border.all(color: (statusStyle['border'] as Color).withOpacity(0.8), width: 0.8),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.swap_horiz_rounded,
                                        size: 13,
                                        color: statusStyle['color'] as Color,
                                      ),
                                      const SizedBox(width: 2),
                                      Flexible(
                                        child: Text(
                                          'Estado',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(
                                            fontSize: 9.5,
                                            fontWeight: FontWeight.w700,
                                            color: statusStyle['color'] as Color,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),

                            // Botones editar y eliminar
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () => _editVehicle(vehicle),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.petrolBase.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.edit_outlined,
                                      size: 15,
                                      color: AppColors.petrolBase,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 5),
                                InkWell(
                                  onTap: () => _removeVehicle(vehicle),
                                  borderRadius: BorderRadius.circular(6),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentOrange.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: const Icon(
                                      Icons.delete_outline_rounded,
                                      size: 15,
                                      color: AppColors.accentOrange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // MODAL DE DETALLES DEL VEHÍCULO
  // ─────────────────────────────────────────────
  void _showVehicleDetails(dynamic vehicle) {
    final images = _extractVehicleImages(vehicle);
    final estado = (vehicle['estadoVehiculo'] ?? (vehicle['estado'] == false ? 'inactivo' : 'activo'))
        .toString()
        .toLowerCase();
    final statusStyle = _getStatusStyle(estado);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
            top: 14,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Barra indicadora superior
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderGray,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Cabecera del modal
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${vehicle['marca'] ?? ''} ${vehicle['modelo'] ?? ''}'.trim(),
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF7D6),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFE6CA65), width: 1),
                              ),
                              child: Text(
                                (vehicle['placa'] ?? '').toString().toUpperCase(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusStyle['bg'] as Color,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusStyle['border'] as Color),
                              ),
                              child: Text(
                                statusStyle['label'] as String,
                                style: TextStyle(
                                  color: statusStyle['color'] as Color,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(Icons.close_rounded, color: AppColors.slateGray),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Carrusel de imágenes amplio si existen fotos
              if (images.isNotEmpty) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: SizedBox(
                    height: 170,
                    width: double.infinity,
                    child: VehicleCardImageCarousel(
                      images: images,
                      tipoVehiculo: vehicle['tipoVehiculo']?.toString() ?? 'Automóvil',
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Si tiene motivo de cambio de estado
              if (vehicle['motivoCambioEstado'] != null &&
                  vehicle['motivoCambioEstado'].toString().trim().isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (statusStyle['bg'] as Color).withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: (statusStyle['border'] as Color).withOpacity(0.8)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Motivo de estado actual:',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: statusStyle['color'] as Color,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        vehicle['motivoCambioEstado'].toString(),
                        style: const TextStyle(
                          fontSize: 12.5,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Tarjetas de especificaciones
              _detailRow('Tipo de vehículo', vehicle['tipoVehiculo'] ?? 'Automóvil'),
              _detailRow('Año', vehicle['anio']?.toString() ?? 'N/A'),
              _detailRow('Color', vehicle['color'] ?? 'N/A'),
              _detailRow('Vencimiento SOAT', _formatDate(vehicle['fechaVencimientoSoat'])),
              _detailRow(
                'Vencimiento Tecnomecánica',
                _formatDate(vehicle['fechaVencimientoTecnomecanica'] ?? vehicle['fechaRevisionTecnicoMecanica']),
              ),

              const SizedBox(height: 20),

              // Botones de acción en el modal
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _mostrarModalCambioEstado(vehicle);
                      },
                      icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                      label: const Text('Cambiar estado'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.petrolBase,
                        side: const BorderSide(color: AppColors.petrolBase, width: 1.2),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(ctx);
                        _editVehicle(vehicle);
                      },
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: const Text('Editar datos'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accentOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.slateGray, fontSize: 13)),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'No registrada';
    try {
      final dt = DateTime.parse(dateStr.toString()).toLocal();
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final target = DateTime(dt.year, dt.month, dt.day);
      final formatted =
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
      if (target.isBefore(today)) {
        return '$formatted (Vencido)';
      }
      return formatted;
    } catch (_) {
      return dateStr.toString();
    }
  }

  // ─────────────────────────────────────────────
  // HELPERS DE ESTADO Y ESTILOS
  // ─────────────────────────────────────────────
  static String _getEstadoLabel(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return 'Activo';
      case 'en_mantenimiento':
        return 'En mantenimiento';
      case 'vendido':
        return 'Vendido';
      case 'inactivo':
        return 'Inactivo';
      default:
        return 'Activo';
    }
  }

  static Map<String, dynamic> _getStatusStyle(String estado) {
    switch (estado.toLowerCase()) {
      case 'activo':
        return {
          'label': 'Activo',
          'color': const Color(0xFF16A34A),
          'bg': const Color(0xFFDCFCE7),
          'border': const Color(0xFFBBF7D0),
        };
      case 'en_mantenimiento':
        return {
          'label': 'Mantenimiento',
          'color': const Color(0xFFD97706),
          'bg': const Color(0xFFFEF3C7),
          'border': const Color(0xFFFDE68A),
        };
      case 'vendido':
        return {
          'label': 'Vendido',
          'color': const Color(0xFF9333EA),
          'bg': const Color(0xFFF3E8FF),
          'border': const Color(0xFFE9D5FF),
        };
      case 'inactivo':
      default:
        return {
          'label': 'Inactivo',
          'color': const Color(0xFF4B5563),
          'bg': const Color(0xFFF3F4F6),
          'border': const Color(0xFFE5E7EB),
        };
    }
  }

  static List<String> _extractVehicleImages(dynamic vehicle) {
    if (vehicle == null) return [];
    final Set<String> images = {};

    if (vehicle['fotos'] is List) {
      for (var f in vehicle['fotos']) {
        if (f != null && f.toString().trim().isNotEmpty && f.toString().startsWith('http')) {
          images.add(f.toString().trim());
        }
      }
    }

    for (var key in ['foto1', 'foto2', 'foto3', 'foto']) {
      final val = vehicle[key]?.toString().trim();
      if (val != null && val.isNotEmpty && val.startsWith('http')) {
        images.add(val);
      }
    }

    return images.toList();
  }
}

// ─────────────────────────────────────────────
// WIDGET DE IMAGEN / CARRUSEL AUTOMÁTICO
// ─────────────────────────────────────────────
class VehicleCardImageCarousel extends StatefulWidget {
  final List<String> images;
  final String tipoVehiculo;

  const VehicleCardImageCarousel({
    super.key,
    required this.images,
    required this.tipoVehiculo,
  });

  @override
  State<VehicleCardImageCarousel> createState() => _VehicleCardImageCarouselState();
}

class _VehicleCardImageCarouselState extends State<VehicleCardImageCarousel> {
  late PageController _pageController;
  int _currentPage = 0;
  Timer? _carouselTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    // Solo si tiene MÁS de 1 imagen se activa la rotación automática
    if (widget.images.length > 1) {
      _startAutoCarousel();
    }
  }

  void _startAutoCarousel() {
    _carouselTimer?.cancel();
    _carouselTimer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (!mounted || widget.images.length <= 1) {
        timer.cancel();
        return;
      }
      final nextPage = (_currentPage + 1) % widget.images.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void didUpdateWidget(covariant VehicleCardImageCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.images.length != oldWidget.images.length) {
      _carouselTimer?.cancel();
      if (widget.images.length > 1) {
        _startAutoCarousel();
      }
    }
  }

  @override
  void dispose() {
    _carouselTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  IconData _getVehicleIcon() {
    final t = widget.tipoVehiculo.toLowerCase();
    if (t.contains('moto')) return Icons.two_wheeler_rounded;
    if (t.contains('camion') || t.contains('carga')) return Icons.local_shipping_rounded;
    if (t.contains('camioneta') || t.contains('suv')) return Icons.directions_car_filled_rounded;
    return Icons.directions_car_rounded;
  }

  @override
  Widget build(BuildContext context) {
    // Caso 1: Sin imágenes -> Placeholder elegante con icono del vehículo
    if (widget.images.isEmpty) {
      return Container(
        color: const Color(0xFFE9F1F3),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _getVehicleIcon(),
                size: 38,
                color: AppColors.petrolBase.withOpacity(0.4),
              ),
              const SizedBox(height: 4),
              Text(
                'Sin fotos',
                style: TextStyle(
                  color: AppColors.slateGray.withOpacity(0.7),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Caso 2: Solo 1 imagen -> Imagen fija (sin carrusel ni rotación)
    if (widget.images.length == 1) {
      return Image.network(
        widget.images.first,
        fit: BoxFit.cover,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            color: const Color(0xFFECEFF1),
            child: const Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.petrolBase),
              ),
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) => Container(
          color: const Color(0xFFECEFF1),
          child: const Center(
            child: Icon(Icons.broken_image_rounded, color: AppColors.slateGray, size: 30),
          ),
        ),
      );
    }

    // Caso 3: Más de 1 imagen -> Carrusel automático con PageView e indicadores
    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          itemCount: widget.images.length,
          onPageChanged: (idx) {
            setState(() {
              _currentPage = idx;
            });
          },
          itemBuilder: (context, index) {
            return Image.network(
              widget.images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: const Color(0xFFECEFF1),
                  child: const Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.petrolBase),
                    ),
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFFECEFF1),
                child: const Center(
                  child: Icon(Icons.broken_image_rounded, color: AppColors.slateGray, size: 30),
                ),
              ),
            );
          },
        ),

        // Contador de fotos (ej: 1/3) en la esquina superior derecha
        Positioned(
          top: 8,
          right: 8,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.55),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.photo_library_outlined, color: Colors.white, size: 10),
                const SizedBox(width: 3),
                Text(
                  '${_currentPage + 1}/${widget.images.length}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Puntos de paginación (dots) en la parte inferior de la imagen
        Positioned(
          bottom: 6,
          left: 0,
          right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              widget.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 2.5),
                width: _currentPage == i ? 14 : 5,
                height: 4,
                decoration: BoxDecoration(
                  color: _currentPage == i ? Colors.white : Colors.white.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 2,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
// MODAL DE CAMBIO DE ESTADO (IDÉNTICO A LA VERSIÓN WEB)
// ─────────────────────────────────────────────
class _ChangeVehicleStatusModalSheet extends StatefulWidget {
  final dynamic vehicle;
  final String initialStatus;
  final Future<void> Function(String nuevoEstado, String? motivo) onStatusChanged;

  const _ChangeVehicleStatusModalSheet({
    required this.vehicle,
    required this.initialStatus,
    required this.onStatusChanged,
  });

  @override
  State<_ChangeVehicleStatusModalSheet> createState() => _ChangeVehicleStatusModalSheetState();
}

class _ChangeVehicleStatusModalSheetState extends State<_ChangeVehicleStatusModalSheet> {
  late String _selectedStatus;
  late TextEditingController _motivoController;
  bool _isSubmitting = false;
  String? _errorMsg;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'id': 'activo',
      'label': 'Activo',
      'desc': 'Disponible para asignación y solicitudes de servicio.',
      'color': const Color(0xFF16A34A),
      'bg': const Color(0xFFDCFCE7),
      'border': const Color(0xFFBBF7D0),
      'requiresMotivo': false,
    },
    {
      'id': 'en_mantenimiento',
      'label': 'En Mantenimiento',
      'desc': 'En revisión o taller mecánico. No apto para nuevos servicios.',
      'color': const Color(0xFFD97706),
      'bg': const Color(0xFFFEF3C7),
      'border': const Color(0xFFFDE68A),
      'requiresMotivo': true,
      'hint': 'Ej: Falla en motor, cambio de frenos, mantenimiento preventivo...',
    },
    {
      'id': 'vendido',
      'label': 'Vendido',
      'desc': 'Vehículo vendido o traspasado. Ya no se listará en tus vehículos activos.',
      'color': const Color(0xFF9333EA),
      'bg': const Color(0xFFF3E8FF),
      'border': const Color(0xFFE9D5FF),
      'requiresMotivo': true,
      'hint': 'Ej: Vendido a nuevo dueño, traspaso en proceso...',
    },
    {
      'id': 'inactivo',
      'label': 'Inactivo',
      'desc': 'Desactivado temporalmente o suspendido.',
      'color': const Color(0xFF4B5563),
      'bg': const Color(0xFFF3F4F6),
      'border': const Color(0xFFE5E7EB),
      'requiresMotivo': true,
      'hint': 'Indica la razón por la que se desactiva el vehículo...',
    },
  ];

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.initialStatus;
    _motivoController = TextEditingController(
      text: widget.vehicle['motivoCambioEstado']?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _errorMsg = null);

    final currentOption = _statusOptions.firstWhere((o) => o['id'] == _selectedStatus);
    final bool requiresMotivo = currentOption['requiresMotivo'] == true;
    final motivo = _motivoController.text.trim();

    if (requiresMotivo && motivo.length < 3) {
      setState(() {
        _errorMsg = 'El motivo del cambio es obligatorio (mínimo 3 caracteres).';
      });
      return;
    }

    try {
      setState(() => _isSubmitting = true);
      await widget.onStatusChanged(_selectedStatus, motivo.isEmpty ? null : motivo);
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll('Exception: ', '');
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentOption = _statusOptions.firstWhere((o) => o['id'] == _selectedStatus);
    final bool requiresMotivo = currentOption['requiresMotivo'] == true;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: EdgeInsets.only(
        top: 14,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Indicador superior
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderGray,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Título
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cambiar estado del vehículo',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.vehicle['marca'] ?? ''} ${widget.vehicle['modelo'] ?? ''} · ${widget.vehicle['placa'] ?? ''}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.slateGray),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: AppColors.slateGray),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Opciones de estado (Cards seleccionables)
            ..._statusOptions.map((opt) {
              final isSelected = _selectedStatus == opt['id'];
              final color = opt['color'] as Color;
              final bg = opt['bg'] as Color;

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  color: isSelected ? bg.withOpacity(0.7) : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? color : AppColors.borderGray,
                    width: isSelected ? 1.8 : 1,
                  ),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () {
                    setState(() {
                      _selectedStatus = opt['id'] as String;
                      _errorMsg = null;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 18,
                          height: 18,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? color : AppColors.slateGray,
                              width: 2,
                            ),
                            color: isSelected ? color : Colors.transparent,
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 12, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                opt['label'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 14,
                                  color: isSelected ? color : AppColors.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                opt['desc'] as String,
                                style: const TextStyle(
                                  fontSize: 11.5,
                                  color: AppColors.slateGray,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),

            // Alerta especial si selecciona "Vendido" (igual que en la web)
            if (_selectedStatus == 'vendido') ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.purpleBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.purple.withOpacity(0.4)),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.purple, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Al marcar como VENDIDO, el vehículo se desvinculará de tu lista activa y no volverá a listarse aquí.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF6B21A8),
                          height: 1.3,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Campo para justificación / motivo (obligatorio si no es activo)
            if (requiresMotivo) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Text(
                    'Motivo del cambio de estado',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const Text(' *', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _motivoController,
                maxLines: 2,
                decoration: InputDecoration(
                  hintText: currentOption['hint'] ?? 'Escribe la justificación...',
                  hintStyle: TextStyle(color: AppColors.slateGray.withOpacity(0.6), fontSize: 12.5),
                  contentPadding: const EdgeInsets.all(12),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
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
            ],

            // Mensaje de error
            if (_errorMsg != null) ...[
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.dangerBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMsg!,
                        style: const TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 18),

            // Botones de acción
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      side: const BorderSide(color: AppColors.borderGray),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancelar', style: TextStyle(color: AppColors.slateGray)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedStatus == 'vendido'
                          ? AppColors.purple
                          : AppColors.petrolBase,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Actualizar estado',
                            style: TextStyle(fontWeight: FontWeight.w700),
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
}