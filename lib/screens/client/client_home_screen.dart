import 'package:flutter/material.dart';
import '../client/services/searching_driver_screen.dart';
import '../../models/vehicle.dart';
import '../../models/solicitud.dart';
import '../../services/http_client.dart';
import '../../services/solicitud_service.dart';
import '../../services/auth_service.dart';
import '../../services/cliente_service.dart';
import '../../services/vehiculo_service.dart';
import 'vehicles/add_vehicle_screen.dart';

// ============================================================
// PALETA DE COLORES — Azul Petróleo · Gris · Naranja Tenue
// ============================================================
class AppColors {
  static const Color petrol = Color(0xFF0F3D44); // Azul petróleo (principal)
  static const Color petrolDark = Color(0xFF0A2A30); // Azul petróleo oscuro
  static const Color petrolLight = Color(0xFF1B5A63); // Azul petróleo claro
  static const Color petrolPale = Color(
    0xFFDCE9EA,
  ); // Azul petróleo muy tenue (badges/fondos)
  static const Color slate = Color(0xFF334A52); // Azul grisáceo
  static const Color background = Color(0xFFF2F5F6); // Fondo general
  static const Color cardBackground = Colors.white;
  static const Color border = Color(0xFFDDE4E6); // Bordes suaves
  static const Color textPrimary = Color(0xFF1C2B2F); // Texto principal
  static const Color textSecondary = Color(
    0xFF6B7C80,
  ); // Texto secundario / labels
  static const Color accent = Color(0xFFE8862E); // Naranja
  static const Color accentDark = Color(
    0xFFC96A1B,
  ); // Naranja oscuro (gradiente)
  static const Color accentSoft = Color(
    0xFFFBEAD8,
  ); // Naranja muy tenue (badges/fondos)
}

class ClientHomeScreen extends StatefulWidget {
  final String? clienteId;
  final String? codigo;
  final String? correoCliente;
  final String? tipoServicio;
  final String? descripcionSolicitud;
  final DateTime? fechaProgramada;
  final String? prioridad;
  final SolicitudService? solicitudService;

  const ClientHomeScreen({
    super.key,
    this.clienteId,
    this.codigo,
    this.correoCliente,
    this.tipoServicio,
    this.descripcionSolicitud,
    this.fechaProgramada,
    this.prioridad,
    this.solicitudService,
  });

  @override
  State<ClientHomeScreen> createState() => _ClientHomeScreenState();
}

class _ClientHomeScreenState extends State<ClientHomeScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _originController = TextEditingController();
  final _destinationController = TextEditingController();

  List<Vehicle> _vehicles = [];
  Vehicle? _selectedVehicle;

  bool _isLoading = true;
  bool _isCreatingSolicitud = false;
  String? _errorMessage;

  String? _clienteId;
  String? _correoCliente;

  late final SolicitudService _solicitudService =
      widget.solicitudService ?? SolicitudService();

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos({String? selectVehicleId}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 1. Obtener datos del usuario autenticado guardados en sesión
      final usuario = await AuthService.obtenerUsuario();
      if (usuario != null) {
        final nombreUsuario =
            '${usuario['nombre'] ?? ''} ${usuario['apellido'] ?? ''}'.trim();
        if (nombreUsuario.isNotEmpty) {
          _nameController.text = nombreUsuario;
        }
        if (usuario['correo'] != null) {
          _correoCliente = usuario['correo'].toString();
        }
        if (usuario['telefono'] != null &&
            usuario['telefono'].toString().isNotEmpty) {
          _phoneController.text = usuario['telefono'].toString();
        }
      }

      // 2. Obtener datos completos del cliente autenticado desde la API
      final cliente = await ClienteService.obtenerClienteActual();
      if (cliente != null) {
        _clienteId = cliente['_id']?.toString();
        final u = cliente['usuario'];
        if (u is Map) {
          final nombreCompleto =
              '${u['nombre'] ?? ''} ${u['apellido'] ?? ''}'.trim();
          if (nombreCompleto.isNotEmpty) {
            _nameController.text = nombreCompleto;
          }
          if (u['telefono'] != null && u['telefono'].toString().isNotEmpty) {
            _phoneController.text = u['telefono'].toString();
          }
          if (u['correo'] != null) {
            _correoCliente = u['correo'].toString();
          }
        }
      } else if (widget.clienteId != null && widget.clienteId!.isNotEmpty) {
        _clienteId = widget.clienteId;
      }

      // 3. Obtener ÚNICAMENTE los vehículos asociados al cliente autenticado
      if (_clienteId != null && _clienteId!.isNotEmpty) {
        final vehiculosRaw =
            await VehiculoService.obtenerPorCliente(_clienteId!);
        _vehicles = vehiculosRaw
            .whereType<Map>()
            .map((item) => Vehicle.fromJson(Map<String, dynamic>.from(item)))
            .toList();

        if (_vehicles.isNotEmpty) {
          if (selectVehicleId != null) {
            _selectedVehicle = _vehicles.firstWhere(
              (v) => v.id == selectVehicleId,
              orElse: () => _vehicles.first,
            );
          } else if (_selectedVehicle != null) {
            final match = _vehicles.where((v) => v.id == _selectedVehicle!.id);
            _selectedVehicle =
                match.isNotEmpty ? match.first : _vehicles.first;
          } else {
            _selectedVehicle = _vehicles.first;
          }
        } else {
          _selectedVehicle = null;
        }
      } else {
        _vehicles = [];
        _selectedVehicle = null;
      }
    } catch (e) {
      _errorMessage =
          'No se pudieron cargar los vehículos. Por favor intenta de nuevo.';
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _registrarVehiculo() async {
    final resultado = await Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const AddVehicleScreen()),
    );

    if (resultado != null && resultado != false && mounted) {
      String? nuevoId;
      if (resultado is Map && resultado['_id'] != null) {
        nuevoId = resultado['_id'].toString();
      } else if (resultado is Vehicle) {
        nuevoId = resultado.id;
      }
      await _cargarDatos(selectVehicleId: nuevoId);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _originController.dispose();
    _destinationController.dispose();
    super.dispose();
  }

  Future<void> _createSolicitud() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final origin = _originController.text.trim();
    final destination = _destinationController.text.trim();

    if (name.isEmpty) {
      _showMessage('Por favor ingresa tu nombre completo');
      return;
    }

    if (phone.isEmpty) {
      _showMessage('Por favor ingresa tu número telefónico');
      return;
    }

    if (_vehicles.isEmpty) {
      _showMessage(
        'No tienes vehículos registrados. Por favor registra uno antes de continuar.',
      );
      return;
    }

    if (_selectedVehicle == null) {
      _showMessage('Por favor selecciona un vehículo');
      return;
    }

    if (origin.isEmpty) {
      _showMessage('Por favor ingresa el lugar de origen');
      return;
    }

    if (destination.isEmpty) {
      _showMessage('Por favor ingresa el lugar de destino');
      return;
    }

    final clienteId = _clienteId ?? widget.clienteId?.trim();
    if (clienteId == null || clienteId.isEmpty) {
      _showMessage(
        'No se puede solicitar el viaje: no se encontró la sesión de cliente válida.',
      );
      return;
    }

    setState(() => _isCreatingSolicitud = true);

    try {
      final now = DateTime.now();
      final codigoGenerado =
          'SOL-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-${now.millisecondsSinceEpoch.toString().substring(7)}';

      final solicitud = await _solicitudService.crearSolicitud(
        Solicitud(
          cliente: clienteId,
          codigo: widget.codigo ?? codigoGenerado,
          correoCliente:
              _correoCliente ?? widget.correoCliente ?? 'cliente@miconductor.com',
          vehiculo: _selectedVehicle!.id,
          tipoServicio: widget.tipoServicio ?? 'Transporte Ejecutivo',
          descripcion:
              widget.descripcionSolicitud ??
              'Solicitud de viaje: $origin hacia $destination',
          origen: origin,
          destino: destination,
          fechaProgramada: widget.fechaProgramada ?? now,
          prioridad: widget.prioridad ?? 'MEDIA',
        ),
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SearchingDriverScreen(solicitud: solicitud),
        ),
      );
    } on ApiException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (e) {
      if (mounted) {
        _showMessage('No se pudo crear la solicitud. Intenta nuevamente.');
      }
    } finally {
      if (mounted) setState(() => _isCreatingSolicitud = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  // Estilo reutilizable para los inputs (mantiene la lógica intacta,
  // solo centraliza el theming visual)
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Color iconColor = AppColors.petrol,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.petrol, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Encabezado de sección reutilizable, con insignia circular a la izquierda
  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.petrolPale,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.petrol),
        ),
        const SizedBox(width: 10),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.petrol,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // Divisor sutil entre secciones del formulario
  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.border.withValues(alpha: 0.8),
      ),
    );
  }

  // Pequeño chip informativo decorativo (confianza / valor agregado)
  Widget _trustChip(IconData icon, String label) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.petrolPale.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.petrol),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColors.slate,
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
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.petrolDark),
          tooltip: 'Regresar',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
        ),
        title: const Text(
          'Solicitar Servicio',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.petrolDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ---------------------------------------------
              // HERO — Encabezado de bienvenida con gradiente
              // ---------------------------------------------
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.petrolDark,
                      AppColors.petrol,
                      AppColors.petrolLight,
                    ],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.35),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                        ),
                      ),
                      child: const Icon(
                        Icons.local_taxi_rounded,
                        color: AppColors.accent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '¡Bienvenido de nuevo!',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.2,
                            ),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Solicita tu viaje en unos segundos',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 12.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            decoration: const BoxDecoration(
                              color: AppColors.accent,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'En línea',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // Título de sección
              const Text(
                'Información del Viaje',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petrolDark,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Completa los datos para solicitar tu viaje',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Mensaje de error si la carga falla
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDE8E8),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFF8B4B4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFC81E1E),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Color(0xFFC81E1E),
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: _cargarDatos,
                        child: const Text(
                          'Reintentar',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFC81E1E),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Formulario
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(22),
                decoration: BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.07),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nombre y Apellidos
                    _sectionLabel('DATOS PERSONALES', Icons.badge_outlined),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Nombre Completo',
                        icon: Icons.person_outline,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Número Telefónico',
                        icon: Icons.phone_outlined,
                        iconColor: AppColors.accent,
                      ),
                    ),

                    _sectionDivider(),

                    // Selección de Vehículo
                    _sectionLabel(
                      'SELECCIONAR VEHÍCULO',
                      Icons.directions_car_filled_outlined,
                    ),
                    const SizedBox(height: 16),

                    if (_isLoading)
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: const Center(
                          child: CircularProgressIndicator(
                            color: AppColors.petrol,
                            strokeWidth: 2.5,
                          ),
                        ),
                      )
                    else if (_vehicles.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: AppColors.petrolPale,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: const Icon(
                                Icons.directions_car_outlined,
                                color: AppColors.petrol,
                                size: 26,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'No tienes vehículos registrados',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Registra tu vehículo para solicitar el viaje.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _registrarVehiculo,
                                icon: const Icon(
                                  Icons.add_rounded,
                                  size: 20,
                                  color: AppColors.petrol,
                                ),
                                label: const Text(
                                  'Registrar vehículo',
                                  style: TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.petrol,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  side: const BorderSide(
                                    color: AppColors.petrol,
                                    width: 1.5,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          DropdownButtonFormField<Vehicle>(
                            initialValue: _selectedVehicle,
                            style: const TextStyle(color: AppColors.textPrimary),
                            dropdownColor: AppColors.cardBackground,
                            icon: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColors.petrol,
                            ),
                            decoration: _inputDecoration(
                              label: 'Vehículo',
                              icon: Icons.directions_car_outlined,
                              iconColor: AppColors.petrol,
                            ),
                            items: _vehicles.map((vehicle) {
                              final label = vehicle.model.isNotEmpty
                                  ? '${vehicle.brand} ${vehicle.model}'
                                  : vehicle.brand;
                              return DropdownMenuItem<Vehicle>(
                                value: vehicle,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppColors.petrolPale,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        vehicle.plates,
                                        style: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.petrol,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedVehicle = value;
                              });
                            },
                            hint: const Text(
                              'Selecciona tu vehículo',
                              style: TextStyle(color: AppColors.textSecondary),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: _registrarVehiculo,
                              icon: const Icon(
                                Icons.add_circle_outline,
                                size: 16,
                                color: AppColors.petrol,
                              ),
                              label: const Text(
                                'Registrar otro vehículo',
                                style: TextStyle(
                                  color: AppColors.petrol,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                    _sectionDivider(),

                    // Origen y Destino
                    _sectionLabel(
                      'DETALLES DEL VIAJE',
                      Icons.alt_route_outlined,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _originController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Lugar de Origen',
                        icon: Icons.my_location,
                        iconColor: AppColors.slate,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _destinationController,
                      style: const TextStyle(color: AppColors.textPrimary),
                      decoration: _inputDecoration(
                        label: 'Lugar de Destino',
                        icon: Icons.location_pin,
                        iconColor: AppColors.accent,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Botón Solicitar Viaje — acento naranja para destacar la acción principal
                    SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                          gradient: const LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [AppColors.accent, AppColors.accentDark],
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.35),
                              blurRadius: 16,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: ElevatedButton(
                          onPressed: _isCreatingSolicitud
                              ? null
                              : _createSolicitud,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 18),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: _isCreatingSolicitud
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.send_rounded,
                                      size: 20,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      'Solicitar Viaje',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
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

              const SizedBox(height: 18),

              // ---------------------------------------------
              // Franja de confianza — detalle decorativo extra
              // ---------------------------------------------
              Row(
                children: [
                  _trustChip(Icons.shield_outlined, 'Pago\nSeguro'),
                  const SizedBox(width: 10),
                  _trustChip(
                    Icons.verified_outlined,
                    'Conductor\nVerificado',
                  ),
                  const SizedBox(width: 10),
                  _trustChip(Icons.bolt_outlined, 'Llegada\nRápida'),
                ],
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
