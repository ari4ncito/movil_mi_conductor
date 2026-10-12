import 'package:flutter/material.dart';
import '../../../../services/auth_service.dart';
import '../../../../services/vehiculo_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app
// Azul petróleo, escalas de azul oscuro, 
// grises y acento en naranja.
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
}

class AddVehicleScreen extends StatefulWidget {
  final dynamic vehicleToEdit;
  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─────────────────────────────────────────────
  // CONTROLADORES: DATOS BÁSICOS
  // ─────────────────────────────────────────────
  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _platesController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();

  String? _vehicleType;

  // ─────────────────────────────────────────────
  // CONTROLADORES: VIGENCIA DE DOCUMENTACIÓN
  // ─────────────────────────────────────────────
  final _soatDateController = TextEditingController();
  final _tecnoDateController = TextEditingController();

  DateTime? _fechaVencimientoSoat;
  DateTime? _fechaVencimientoTecnomecanica;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.vehicleToEdit != null) {
      final v = widget.vehicleToEdit;
      _brandController.text = v['marca'] ?? '';
      _modelController.text = v['modelo'] ?? '';
      _platesController.text = v['placa'] ?? '';
      _colorController.text = v['color'] ?? '';
      _yearController.text = v['anio']?.toString() ?? '';
      _vehicleType = v['tipoVehiculo'];

      // Cargar fecha SOAT
      if (v['fechaVencimientoSoat'] != null) {
        try {
          final dt = DateTime.parse(v['fechaVencimientoSoat']).toLocal();
          _fechaVencimientoSoat = dt;
          _soatDateController.text =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        } catch (_) {}
      }

      // Cargar fecha Tecnomecánica
      final rawTecno = v['fechaVencimientoTecnomecanica'] ?? v['fechaRevisionTecnicoMecanica'];
      if (rawTecno != null) {
        try {
          final dt = DateTime.parse(rawTecno).toLocal();
          _fechaVencimientoTecnomecanica = dt;
          _tecnoDateController.text =
              '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _platesController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _soatDateController.dispose();
    _tecnoDateController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SELECTOR DE FECHAS (BLOQUEA DÍAS PASADOS)
  // ─────────────────────────────────────────────
  Future<void> _selectSoatDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initial = _fechaVencimientoSoat != null && !_fechaVencimientoSoat!.isBefore(today)
        ? _fechaVencimientoSoat!
        : today;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today, // Bloquea fechas anteriores a hoy
      lastDate: DateTime(now.year + 15),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.petrolBase,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaVencimientoSoat = picked;
        _soatDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  Future<void> _selectTecnoDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final initial = _fechaVencimientoTecnomecanica != null && !_fechaVencimientoTecnomecanica!.isBefore(today)
        ? _fechaVencimientoTecnomecanica!
        : today;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today, // Bloquea fechas anteriores a hoy
      lastDate: DateTime(now.year + 15),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.petrolBase,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _fechaVencimientoTecnomecanica = picked;
        _tecnoDateController.text =
            '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
      });
    }
  }

  // ─────────────────────────────────────────────
  // GUARDAR / ACTUALIZAR VEHÍCULO
  // ─────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Validación de fecha SOAT
    if (_fechaVencimientoSoat != null && _fechaVencimientoSoat!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('No se permite registrar con el SOAT vencido.'),
        ),
      );
      return;
    }

    // Validación de fecha Tecnomecánica
    if (_fechaVencimientoTecnomecanica != null && _fechaVencimientoTecnomecanica!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('No se permite registrar con la tecnomecánica vencida.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final usuarioId = await AuthService.obtenerUsuarioId();
      if (usuarioId == null) throw Exception('No hay usuario activo en sesión.');

      final vehiculoData = {
        'cliente': widget.vehicleToEdit?['cliente']?['_id'] ?? widget.vehicleToEdit?['cliente'] ?? usuarioId,
        'marca': _brandController.text.trim(),
        'modelo': _modelController.text.trim().isEmpty ? _brandController.text.trim() : _modelController.text.trim(),
        'placa': _platesController.text.trim().toUpperCase(),
        'color': _colorController.text.trim(),
        'anio': int.tryParse(_yearController.text.trim()) ?? DateTime.now().year,
        'tipoVehiculo': _vehicleType ?? 'Automóvil',
        if (_fechaVencimientoSoat != null)
          'fechaVencimientoSoat': _fechaVencimientoSoat!.toIso8601String(),
        if (_fechaVencimientoTecnomecanica != null) ...{
          'fechaVencimientoTecnomecanica': _fechaVencimientoTecnomecanica!.toIso8601String(),
          'fechaRevisionTecnicoMecanica': _fechaVencimientoTecnomecanica!.toIso8601String(),
        },
        'numeroPuertas': 4,
        'numeroChasis': widget.vehicleToEdit?['numeroChasis'] ?? '00000',
        'tipoCombustible': widget.vehicleToEdit?['tipoCombustible'] ?? 'Gasolina',
        'estadoSeguro': widget.vehicleToEdit?['estadoSeguro'] ?? 'Activo',
        'companiaAseguradora': widget.vehicleToEdit?['companiaAseguradora'] ?? 'N/A',
        'estado': true,
      };

      if (widget.vehicleToEdit != null) {
        final id = widget.vehicleToEdit['_id'] ?? widget.vehicleToEdit['id'];
        await VehiculoService.update(id, vehiculoData);
      } else {
        await VehiculoService.crear(vehiculoData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF16A34A),
            content: Text(widget.vehicleToEdit != null
                ? 'Vehículo actualizado exitosamente.'
                : 'Vehículo registrado exitosamente.'),
          ),
        );
        Navigator.of(context).pop(true);
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

  // ─────────────────────────────────────────────
  // COMPONENTES DE UI
  // ─────────────────────────────────────────────
  Widget _buildSectionHeader(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 3.5,
              height: 18,
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.petrolDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Text(
            subtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateGray,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCardContainer({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String labelText,
    String? hintText,
    required IconData prefixIcon,
  }) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.slateGray, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isEditing = widget.vehicleToEdit != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          isEditing ? 'Editar Vehículo' : 'Registrar Vehículo',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════
                // SECCIÓN 1: DATOS BÁSICOS DEL VEHÍCULO
                // ═══════════════════════════════════════════
                _buildSectionHeader(
                  'Datos Básicos del Vehículo',
                  'Información principal de identificación del vehículo',
                ),
                const SizedBox(height: 12),
                _buildCardContainer(
                  children: [
                    // MARCA
                    TextFormField(
                      controller: _brandController,
                      decoration: _inputDecoration(
                        labelText: 'MARCA',
                        hintText: 'Ej. Toyota, Chevrolet, Mazda',
                        prefixIcon: Icons.directions_car_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa la marca del vehículo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // MODELO
                    TextFormField(
                      controller: _modelController,
                      decoration: _inputDecoration(
                        labelText: 'MODELO',
                        hintText: 'Ej. Corolla, Tracker, Mazda 3',
                        prefixIcon: Icons.car_rental_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el modelo del vehículo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // PLACA
                    TextFormField(
                      controller: _platesController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: _inputDecoration(
                        labelText: 'PLACA',
                        hintText: 'Ej. ABC123',
                        prefixIcon: Icons.confirmation_number_outlined,
                      ),
                      validator: (value) {
                        final val = value?.trim().toUpperCase() ?? '';
                        if (val.isEmpty) {
                          return 'Ingresa la placa del vehículo';
                        }
                        final regex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
                        if (!regex.hasMatch(val)) {
                          return 'Formato inválido: deben ser 3 letras y 3 números (ej. ABC123)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // AÑO
                    TextFormField(
                      controller: _yearController,
                      keyboardType: TextInputType.number,
                      decoration: _inputDecoration(
                        labelText: 'AÑO',
                        hintText: 'Ej. 2024',
                        prefixIcon: Icons.calendar_today_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el año del vehículo';
                        }
                        final year = int.tryParse(value.trim());
                        if (year == null || year < 1980 || year > DateTime.now().year + 1) {
                          return 'Ingresa un año válido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // COLOR
                    TextFormField(
                      controller: _colorController,
                      decoration: _inputDecoration(
                        labelText: 'COLOR',
                        hintText: 'Ej. Blanco, Negro, Gris',
                        prefixIcon: Icons.palette_outlined,
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Ingresa el color del vehículo';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // TIPO DE VEHÍCULO
                    DropdownButtonFormField<String>(
                      value: _vehicleType,
                      decoration: _inputDecoration(
                        labelText: 'TIPO DE VEHÍCULO',
                        hintText: 'Selecciona el tipo',
                        prefixIcon: Icons.commute_outlined,
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Automóvil', child: Text('Automóvil')),
                        DropdownMenuItem(value: 'Sedán', child: Text('Sedán')),
                        DropdownMenuItem(value: 'SUV', child: Text('SUV')),
                        DropdownMenuItem(value: 'Camioneta', child: Text('Camioneta')),
                        DropdownMenuItem(value: 'Hatchback', child: Text('Hatchback')),
                        DropdownMenuItem(value: 'Pickup', child: Text('Pickup')),
                        DropdownMenuItem(value: 'Van', child: Text('Van')),
                        DropdownMenuItem(value: 'Moto', child: Text('Moto')),
                        DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                      ],
                      onChanged: (val) => setState(() => _vehicleType = val),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'Selecciona un tipo de vehículo';
                        }
                        return null;
                      },
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════════
                // SECCIÓN 2: VIGENCIA DE DOCUMENTACIÓN
                // ═══════════════════════════════════════════
                _buildSectionHeader(
                  'Vigencia de Documentación',
                  'Fechas de vencimiento legal del SOAT y de la tecnomecánica',
                ),
                const SizedBox(height: 12),
                _buildCardContainer(
                  children: [
                    // FECHA VENCIMIENTO SOAT
                    GestureDetector(
                      onTap: _selectSoatDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _soatDateController,
                          decoration: _inputDecoration(
                            labelText: 'FECHA VENCIMIENTO DEL SOAT',
                            hintText: 'Seleccionar fecha',
                            prefixIcon: Icons.event_available_outlined,
                          ),
                          validator: (value) {
                            if (_fechaVencimientoSoat != null) {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              if (_fechaVencimientoSoat!.isBefore(today)) {
                                return 'El SOAT no puede estar vencido';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // FECHA VENCIMIENTO TECNOMECÁNICA
                    GestureDetector(
                      onTap: _selectTecnoDate,
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: _tecnoDateController,
                          decoration: _inputDecoration(
                            labelText: 'FECHA VENCIMIENTO TECNOMECÁNICA',
                            hintText: 'Seleccionar fecha',
                            prefixIcon: Icons.event_available_outlined,
                          ),
                          validator: (value) {
                            if (_fechaVencimientoTecnomecanica != null) {
                              final now = DateTime.now();
                              final today = DateTime(now.year, now.month, now.day);
                              if (_fechaVencimientoTecnomecanica!.isBefore(today)) {
                                return 'La tecnomecánica no puede estar vencida';
                              }
                            }
                            return null;
                          },
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // ═══════════════════════════════════════════
                // BOTÓN GUARDAR
                // ═══════════════════════════════════════════
                SizedBox(
                  width: double.infinity,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: const LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: [
                          AppColors.petrolBase,
                          AppColors.petrolDark,
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.petrolDark.withOpacity(0.25),
                          blurRadius: 12,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: AppColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Text(
                              isEditing ? 'Guardar Cambios' : 'Registrar Vehículo',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.3,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}