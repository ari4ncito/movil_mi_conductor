import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import '/models/vehicle.dart';
import '/widgets/custom_text_field.dart';

// ─────────────────────────────────────────────
// Paleta de la app
// Azul petróleo, escalas de azul oscuro, 
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
  static const Color accentOrangeBg = Color(0xFFFCEADA);
  static const Color white = Colors.white;
}

class AddVehicleScreen extends StatefulWidget {
  const AddVehicleScreen({super.key});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  // ─────────────────────────────────────────────
  // DATOS BÁSICOS
  // ─────────────────────────────────────────────

  final _brandController = TextEditingController();
  final _modelController = TextEditingController();
  final _platesController = TextEditingController();
  final _colorController = TextEditingController();
  final _yearController = TextEditingController();

  // ─────────────────────────────────────────────
  // INFORMACIÓN TÉCNICA
  // ─────────────────────────────────────────────

  final _vinController = TextEditingController();
  final _insuranceCompanyController =
      TextEditingController();
  final _technicalReviewDateController =
      TextEditingController();

  String? _vehicleType;
  String? _fuelType;
  String? _doors;
  String? _insuranceStatus;

  // ─────────────────────────────────────────────
  // SEGURIDAD
  // ─────────────────────────────────────────────

  bool _hasGps = false;
  bool _hasAirbags = false;
  bool _hasAbs = false;
  bool _hasRearCamera = false;
  bool _hasInteriorCamera = false;

  // ─────────────────────────────────────────────
  // DOCUMENTOS
  // ─────────────────────────────────────────────

  final Map<String, bool> _documents = {
    'Tarjeta de Circulación': false,
    'Seguro': false,
    'Verificación': false,
  };

  // Archivos
  PlatformFile? _technicalReviewFile;
  PlatformFile? _soatFile;

  // ─────────────────────────────────────────────
  // DISPOSE
  // ─────────────────────────────────────────────

  @override
  void dispose() {
    _brandController.dispose();
    _modelController.dispose();
    _platesController.dispose();
    _colorController.dispose();
    _yearController.dispose();

    _vinController.dispose();
    _insuranceCompanyController.dispose();
    _technicalReviewDateController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // SELECCIONAR ARCHIVO
  // ─────────────────────────────────────────────

  Future<void> _pickTechnicalReviewFile() async {
    final result = await FilePicker.platform.pickFiles (
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _technicalReviewFile = result.files.first;
      });
    }
  }

  Future<void> _pickSoatFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: [
        'pdf',
        'jpg',
        'jpeg',
        'png',
      ],
      allowMultiple: false,
    );

    if (result != null && result.files.isNotEmpty) {
      setState(() {
        _soatFile = result.files.first;
      });
    }
  }

  void _removeTechnicalReviewFile() {
    setState(() {
      _technicalReviewFile = null;
    });
  }

  void _removeSoatFile() {
    setState(() {
      _soatFile = null;
    });
  }

  // ─────────────────────────────────────────────
  // GUARDAR VEHÍCULO
  // ─────────────────────────────────────────────

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final newVehicle = Vehicle(
        id: DateTime.now()
            .millisecondsSinceEpoch
            .toString(),

        brand: _brandController.text.trim(),

        plates: _platesController.text
            .trim()
            .toUpperCase(),

        color: _colorController.text.trim(),

        year: _yearController.text.trim(),

        icon: Icons.directions_car_outlined,

        iconColor: AppColors.slateGray,
      );

      Navigator.of(context).pop(newVehicle);
    }
  }

  // ─────────────────────────────────────────────
  // TARJETAS DE DOCUMENTOS
  // ─────────────────────────────────────────────

  Widget _buildDocumentCard(String title) {
    final bool isSelected = _documents[title]!;

    return GestureDetector(
      onTap: () {
        setState(() {
          _documents[title] = !isSelected;
        });
      },

      child: AnimatedContainer(
        duration:
            const Duration(milliseconds: 200),

        width: 110,

        padding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 8,
        ),

        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accentOrangeBg
              : AppColors.white,

          borderRadius:
              BorderRadius.circular(16),

          border: Border.all(
            color: isSelected
                ? AppColors.accentOrange
                : AppColors.borderGray,

            width: isSelected ? 2 : 1,
          ),

          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors
                        .accentOrange
                        .withOpacity(0.18),

                    blurRadius: 10,

                    offset:
                        const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: AppColors
                        .petrolDark
                        .withOpacity(0.04),

                    blurRadius: 8,

                    offset:
                        const Offset(0, 2),
                  ),
                ],
        ),

        child: Column(
          children: [
            Container(
              width: 50,
              height: 50,

              decoration: BoxDecoration(
                gradient: isSelected
                    ? const LinearGradient(
                        begin:
                            Alignment.topLeft,
                        end:
                            Alignment.bottomRight,

                        colors: [
                          AppColors
                              .accentOrange,
                          Color(0xFFD46A0A),
                        ],
                      )
                    : null,

                color: isSelected
                    ? null
                    : AppColors.background,

                shape: BoxShape.circle,

                border: isSelected
                    ? null
                    : Border.all(
                        color:
                            AppColors.borderGray,
                        width: 1,
                      ),
              ),

              child: Icon(
                isSelected
                    ? Icons.check_circle
                    : Icons
                        .camera_alt_outlined,

                color: isSelected
                    ? AppColors.white
                    : AppColors.slateGray,

                size: 26,
              ),
            ),

            const SizedBox(height: 12),

            Text(
              title,

              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 12,
                fontWeight:
                    FontWeight.w600,

                color: isSelected
                    ? AppColors
                        .accentOrange
                    : AppColors.slateGray,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TÍTULO DE SECCIÓN
  // ─────────────────────────────────────────────

  Widget _buildSectionTitle(String title) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,

          decoration: BoxDecoration(
            color:
                AppColors.accentOrange,

            borderRadius:
                BorderRadius.circular(2),
          ),
        ),

        const SizedBox(width: 8),

        Text(
          title,

          style: const TextStyle(
            fontSize: 13,
            fontWeight:
                FontWeight.bold,

            color:
                AppColors.petrolDark,

            letterSpacing: 1.1,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // DROPDOWN
  // ─────────────────────────────────────────────

  Widget _buildDropdown({
    required String label,
    required String hint,
    required IconData icon,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,

      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.slateGray,
      ),

      decoration: InputDecoration(
        labelText: label,
        hintText: hint,

        prefixIcon: Icon(
          icon,
          color: AppColors.slateGray,
        ),

        filled: true,

        fillColor:
            AppColors.white,

        contentPadding:
            const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),

        border: OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide:
              const BorderSide(
            color:
                AppColors.borderGray,
          ),
        ),

        enabledBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide:
              const BorderSide(
            color:
                AppColors.borderGray,
          ),
        ),

        focusedBorder:
            OutlineInputBorder(
          borderRadius:
              BorderRadius.circular(12),

          borderSide:
              const BorderSide(
            color:
                AppColors.petrolBase,
            width: 1.5,
          ),
        ),
      ),

      items: items.map((item) {
        return DropdownMenuItem<String>(
          value: item,
          child: Text(item),
        );
      }).toList(),

      onChanged: onChanged,

      validator: (value) {
        if (value == null ||
            value.isEmpty) {
          return 'Selecciona una opción';
        }

        return null;
      },
    );
  }

  // ─────────────────────────────────────────────
  // INTERRUPTOR DE SEGURIDAD
  // ─────────────────────────────────────────────

  Widget _buildSecurityOption({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin:
          const EdgeInsets.only(bottom: 10),

      padding:
          const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 10,
      ),

      decoration: BoxDecoration(
        color: AppColors.white,

        borderRadius:
            BorderRadius.circular(14),

        border: Border.all(
          color: value
              ? AppColors.accentOrange
              : AppColors.borderGray,

          width: value ? 1.5 : 1,
        ),
      ),

      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,

            decoration: BoxDecoration(
              color: value
                  ? AppColors
                      .accentOrangeBg
                  : AppColors.background,

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              icon,

              color: value
                  ? AppColors
                      .accentOrange
                  : AppColors.slateGray,

              size: 22,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors
                            .textPrimary,
                  ),
                ),

                const SizedBox(height: 2),

                Text(
                  subtitle,

                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppColors
                            .slateGray,
                  ),
                ),
              ],
            ),
          ),

          Switch(
            value: value,

            activeThumbColor:
                AppColors
                    .accentOrange,

            activeTrackColor:
                AppColors
                    .accentOrangeBg,

            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // TARJETA PARA ARCHIVOS
  // ─────────────────────────────────────────────

  Widget _buildFileUploadCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required PlatformFile? file,
    required VoidCallback onPick,
    required VoidCallback onRemove,
  }) {
    final bool hasFile = file != null;

    return Container(
      width: double.infinity,

      padding:
          const EdgeInsets.all(16),

      decoration: BoxDecoration(
        color: hasFile
            ? AppColors.accentOrangeBg
            : AppColors.white,

        borderRadius:
            BorderRadius.circular(16),

        border: Border.all(
          color: hasFile
              ? AppColors.accentOrange
              : AppColors.borderGray,

          width: hasFile ? 1.5 : 1,
        ),

        boxShadow: [
          BoxShadow(
            color: AppColors
                .petrolDark
                .withOpacity(0.04),

            blurRadius: 8,

            offset:
                const Offset(0, 2),
          ),
        ],
      ),

      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,

            decoration: BoxDecoration(
              color: hasFile
                  ? AppColors
                      .accentOrange
                  : AppColors.background,

              shape:
                  BoxShape.circle,
            ),

            child: Icon(
              hasFile
                  ? Icons
                      .check_circle_outline
                  : icon,

              color: hasFile
                  ? AppColors.white
                  : AppColors.slateGray,

              size: 24,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                Text(
                  title,

                  style:
                      const TextStyle(
                    fontSize: 14,
                    fontWeight:
                        FontWeight.w600,
                    color:
                        AppColors
                            .textPrimary,
                  ),
                ),

                const SizedBox(height: 4),

                if (hasFile)
                  Text(
                    file.name,

                    maxLines: 1,

                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          AppColors
                              .accentOrange,

                      fontWeight:
                          FontWeight.w600,
                    ),
                  )
                else
                  Text(
                    subtitle,

                    style:
                        const TextStyle(
                      fontSize: 11,
                      color:
                          AppColors
                              .slateGray,
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          if (hasFile)
            IconButton(
              onPressed: onRemove,

              icon: const Icon(
                Icons.close_rounded,
                color:
                    AppColors.slateGray,
              ),

              tooltip:
                  'Eliminar archivo',
            )
          else
            OutlinedButton.icon(
              onPressed: onPick,

              icon: const Icon(
                Icons.attach_file_rounded,
                size: 18,
              ),

              label: const Text(
                'Adjuntar',
              ),

              style:
                  OutlinedButton.styleFrom(
                foregroundColor:
                    AppColors
                        .petrolBase,

                side:
                    const BorderSide(
                  color:
                      AppColors
                          .petrolBase,
                ),

                shape:
                    RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular(
                          20),
                ),

                padding:
                    const EdgeInsets
                        .symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  // FECHA DE REVISIÓN
  // ─────────────────────────────────────────────

  Future<void>
      _selectTechnicalReviewDate() async {
    final DateTime? picked =
        await showDatePicker(
      context: context,

      initialDate:
          DateTime.now(),

      firstDate:
          DateTime(2000),

      lastDate:
          DateTime(2100),

      builder:
          (context, child) {
        return Theme(
          data: Theme.of(context)
              .copyWith(
            colorScheme:
                const ColorScheme.light(
              primary:
                  AppColors.petrolBase,

              onPrimary:
                  AppColors.white,

              surface:
                  AppColors.white,

              onSurface:
                  AppColors
                      .textPrimary,
            ),
          ),

          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _technicalReviewDateController
                .text =
            '${picked.day.toString().padLeft(2, '0')}/'
            '${picked.month.toString().padLeft(2, '0')}/'
            '${picked.year}';
      });
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppColors.background,

      appBar: AppBar(
        backgroundColor:
            AppColors.white,

        elevation: 0,

        title: const Text(
          'Agregar Vehículo',

          style: TextStyle(
            fontSize: 20,
            fontWeight:
                FontWeight.bold,

            color:
                AppColors.textPrimary,
          ),
        ),

        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color:
                AppColors.textPrimary,
          ),

          onPressed: () =>
              Navigator.of(context)
                  .pop(),
        ),
      ),

      body: SafeArea(
        child:
            SingleChildScrollView(
          padding:
              const EdgeInsets
                  .symmetric(
            horizontal: 16,
            vertical: 20,
          ),

          child: Form(
            key: _formKey,

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment
                      .start,

              children: [

                // ═══════════════════════════════════
                // DATOS BÁSICOS
                // ═══════════════════════════════════

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.white,

                    borderRadius:
                        BorderRadius
                            .circular(20),

                    border:
                        Border.all(
                      color:
                          AppColors
                              .borderGray,
                      width: 1,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: AppColors
                            .petrolDark
                            .withOpacity(
                                0.06),

                        blurRadius: 12,

                        offset:
                            const Offset(
                                0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [

                      const Text(
                        'Datos básicos del vehículo',

                        style:
                            TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight
                                  .w600,

                          color:
                              AppColors
                                  .textPrimary,
                        ),
                      ),

                      const SizedBox(
                          height: 6),

                      const Text(
                        'Ingresa la información principal del vehículo',

                        style:
                            TextStyle(
                          fontSize: 12,

                          color:
                              AppColors
                                  .slateGray,
                        ),
                      ),

                      const SizedBox(
                          height: 20),

                      // MARCA
                      CustomTextField(
                        labelText:
                            'MARCA',

                        hintText:
                            'Ej: Toyota',

                        prefixIcon:
                            Icons
                                .directions_car_outlined,

                        controller:
                            _brandController,
                      ),

                      const SizedBox(
                          height: 16),

                      // MODELO
                      CustomTextField(
                        labelText:
                            'MODELO',

                        hintText:
                            'Ej: Corolla',

                        prefixIcon:
                            Icons
                                .car_rental_outlined,

                        controller:
                            _modelController,
                      ),

                      const SizedBox(
                          height: 16),

                      // AÑO
                      CustomTextField(
                        labelText:
                            'AÑO',

                        hintText:
                            'Ej: 2023',

                        prefixIcon:
                            Icons
                                .calendar_today_outlined,

                        keyboardType:
                            TextInputType
                                .number,

                        controller:
                            _yearController,
                      ),

                      const SizedBox(
                          height: 16),

                      // COLOR
                      CustomTextField(
                        labelText:
                            'COLOR',

                        hintText:
                            'Ej: Rojo',

                        prefixIcon:
                            Icons
                                .palette_outlined,

                        controller:
                            _colorController,
                      ),

                      const SizedBox(
                          height: 16),

                      // PLACA
                      CustomTextField(
                        labelText:
                            'PLACA',

                        hintText:
                            'Ej: ABC 123',

                        prefixIcon:
                            Icons
                                .confirmation_number_outlined,

                        controller:
                            _platesController,
                      ),

                      const SizedBox(
                          height: 16),

                      // TIPO
                      _buildDropdown(
                        label:
                            'TIPO DE VEHÍCULO',

                        hint:
                            'Selecciona el tipo',

                        icon:
                            Icons
                                .directions_car_outlined,

                        value:
                            _vehicleType,

                        items: const [
                          'Sedán',
                          'SUV',
                          'Camioneta',
                          'Hatchback',
                          'Pickup',
                          'Van',
                          'Moto',
                          'Otro',
                        ],

                        onChanged:
                            (value) {
                          setState(() {
                            _vehicleType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                          height: 16),

                      // PUERTAS
                      _buildDropdown(
                        label:
                            'NÚMERO DE PUERTAS',

                        hint:
                            'Selecciona',

                        icon:
                            Icons
                                .sensor_door_outlined,

                        value:
                            _doors,

                        items: const [
                          '2 puertas',
                          '3 puertas',
                          '4 puertas',
                          '5 puertas',
                        ],

                        onChanged:
                            (value) {
                          setState(() {
                            _doors =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 28),

                // ═══════════════════════════════════
                // INFORMACIÓN TÉCNICA
                // ═══════════════════════════════════

                _buildSectionTitle(
                  'INFORMACIÓN TÉCNICA Y DE SEGURIDAD',
                ),

                const SizedBox(
                    height: 16),

                Container(
                  width:
                      double.infinity,

                  padding:
                      const EdgeInsets
                          .all(20),

                  decoration:
                      BoxDecoration(
                    color:
                        AppColors.white,

                    borderRadius:
                        BorderRadius
                            .circular(20),

                    border:
                        Border.all(
                      color:
                          AppColors
                              .borderGray,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color: AppColors
                            .petrolDark
                            .withOpacity(
                                0.06),

                        blurRadius: 12,

                        offset:
                            const Offset(
                                0, 4),
                      ),
                    ],
                  ),

                  child: Column(
                    children: [

                      // VIN
                      CustomTextField(
                        labelText:
                            'NÚMERO DE CHASIS / VIN',

                        hintText:
                            'Ej: 1HGCM82633A123456',

                        prefixIcon:
                            Icons
                                .fingerprint_outlined,

                        controller:
                            _vinController,
                      ),

                      const SizedBox(
                          height: 16),

                      // COMBUSTIBLE
                      _buildDropdown(
                        label:
                            'TIPO DE COMBUSTIBLE',

                        hint:
                            'Selecciona el combustible',

                        icon:
                            Icons
                                .local_gas_station_outlined,

                        value:
                            _fuelType,

                        items: const [
                          'Gasolina',
                          'Diésel',
                          'Eléctrico',
                          'Híbrido',
                        ],

                        onChanged:
                            (value) {
                          setState(() {
                            _fuelType =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                          height: 16),

                      // ESTADO SEGURO
                      _buildDropdown(
                        label:
                            'ESTADO DEL SEGURO',

                        hint:
                            'Selecciona el estado',

                        icon:
                            Icons
                                .verified_user_outlined,

                        value:
                            _insuranceStatus,

                        items: const [
                          'Vigente',
                          'Vencido',
                        ],

                        onChanged:
                            (value) {
                          setState(() {
                            _insuranceStatus =
                                value;
                          });
                        },
                      ),

                      const SizedBox(
                          height: 16),

                      // ASEGURADORA
                      CustomTextField(
                        labelText:
                            'COMPAÑÍA ASEGURADORA',

                        hintText:
                            'Ej: SURA',

                        prefixIcon:
                            Icons
                                .business_outlined,

                        controller:
                            _insuranceCompanyController,
                      ),

                      const SizedBox(
                          height: 16),

                      // FECHA
                      GestureDetector(
                        onTap:
                            _selectTechnicalReviewDate,

                        child:
                            AbsorbPointer(
                          child:
                              CustomTextField(
                            labelText:
                                'FECHA DE REVISIÓN TÉCNICO-MECÁNICA',

                            hintText:
                                'Selecciona una fecha',

                            prefixIcon:
                                Icons
                                    .event_available_outlined,

                            controller:
                                _technicalReviewDateController,
                          ),
                        ),
                      ),

                      const SizedBox(
                          height: 22),

                      // GPS
                      _buildSecurityOption(
                        title:
                            'GPS / Rastreo',

                        subtitle:
                            'El vehículo cuenta con sistema de rastreo',

                        icon:
                            Icons.gps_fixed,

                        value:
                            _hasGps,

                        onChanged:
                            (value) {
                          setState(() {
                            _hasGps =
                                value;
                          });
                        },
                      ),

                      // AIRBAGS
                      _buildSecurityOption(
                        title:
                            'Airbags',

                        subtitle:
                            'Cuenta con sistema de airbags',

                        icon: Icons
                            .airline_seat_recline_normal,

                        value:
                            _hasAirbags,

                        onChanged:
                            (value) {
                          setState(() {
                            _hasAirbags =
                                value;
                          });
                        },
                      ),

                      // ABS
                      _buildSecurityOption(
                        title:
                            'Frenos ABS',

                        subtitle:
                            'Cuenta con sistema de frenos ABS',

                        icon:
                            Icons.speed_outlined,

                        value:
                            _hasAbs,

                        onChanged:
                            (value) {
                          setState(() {
                            _hasAbs =
                                value;
                          });
                        },
                      ),

                      // CÁMARA TRASERA
                      _buildSecurityOption(
                        title:
                            'Cámara trasera',

                        subtitle:
                            'Cuenta con cámara de reversa',

                        icon:
                            Icons
                                .camera_rear_outlined,

                        value:
                            _hasRearCamera,

                        onChanged:
                            (value) {
                          setState(() {
                            _hasRearCamera =
                                value;
                          });
                        },
                      ),

                      // CÁMARA INTERIOR
                      _buildSecurityOption(
                        title:
                            'Cámara interior',

                        subtitle:
                            'Cuenta con cámara dentro del vehículo',

                        icon:
                            Icons
                                .videocam_outlined,

                        value:
                            _hasInteriorCamera,

                        onChanged:
                            (value) {
                          setState(() {
                            _hasInteriorCamera =
                                value;
                          });
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(
                    height: 28),

                // ═══════════════════════════════════
                // DOCUMENTOS
                // ═══════════════════════════════════

                _buildSectionTitle(
                  'DOCUMENTOS DEL VEHÍCULO',
                ),

                const SizedBox(
                    height: 16),

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment
                          .spaceBetween,

                  children: [
                    _buildDocumentCard(
                      'Tarjeta de Circulación',
                    ),

                    _buildDocumentCard(
                      'Seguro',
                    ),

                    _buildDocumentCard(
                      'Verificación',
                    ),
                  ],
                ),

                const SizedBox(
                    height: 16),

                // TÉCNICO-MECÁNICA
                _buildFileUploadCard(
                  title:
                      'Certificado técnico-mecánica',

                  subtitle:
                      'PDF, JPG o PNG',

                  icon:
                      Icons.description_outlined,

                  file:
                      _technicalReviewFile,

                  onPick:
                      _pickTechnicalReviewFile,

                  onRemove:
                      _removeTechnicalReviewFile,
                ),

                const SizedBox(
                    height: 12),

                // SOAT
                _buildFileUploadCard(
                  title:
                      'Certificado SOAT',

                  subtitle:
                      'PDF, JPG o PNG',

                  icon:
                      Icons.verified_user_outlined,

                  file:
                      _soatFile,

                  onPick:
                      _pickSoatFile,

                  onRemove:
                      _removeSoatFile,
                ),

                const SizedBox(
                    height: 32),

                // ═══════════════════════════════════
                // BOTÓN GUARDAR
                // ═══════════════════════════════════

                SizedBox(
                  width:
                      double.infinity,

                  child:
                      DecoratedBox(
                    decoration:
                        BoxDecoration(
                      borderRadius:
                          BorderRadius
                              .circular(30),

                      gradient:
                          const LinearGradient(
                        begin:
                            Alignment.centerLeft,

                        end:
                            Alignment.centerRight,

                        colors: [
                          AppColors
                              .petrolBase,
                          AppColors
                              .petrolDark,
                        ],
                      ),

                      boxShadow: [
                        BoxShadow(
                          color: AppColors
                              .petrolDark
                              .withOpacity(
                                  0.3),

                          blurRadius: 14,

                          offset:
                              const Offset(
                                  0, 6),
                        ),
                      ],
                    ),

                    child:
                        ElevatedButton(
                      onPressed:
                          _submit,

                      style:
                          ElevatedButton
                              .styleFrom(
                        backgroundColor:
                            Colors
                                .transparent,

                        shadowColor:
                            Colors
                                .transparent,

                        foregroundColor:
                            AppColors
                                .white,

                        padding:
                            const EdgeInsets
                                .symmetric(
                          vertical: 16,
                        ),

                        elevation: 0,

                        shape:
                            RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius
                                  .circular(
                                      30),
                        ),
                      ),

                      child:
                          const Text(
                        'Guardar Vehículo',

                        style:
                            TextStyle(
                          fontSize: 16,

                          fontWeight:
                              FontWeight
                                  .bold,

                          letterSpacing:
                              0.3,
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(
                    height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}