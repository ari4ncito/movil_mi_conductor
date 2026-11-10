import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../../services/auth_service.dart';
import '../../../services/vehiculo_service.dart';
import '../../../services/cloudinary_service.dart';

// ─────────────────────────────────────────────
// Paleta de la app
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
  static const Color success = Color(0xFF16A34A);
}

class AddVehicleScreen extends StatefulWidget {
  final dynamic vehicleToEdit;
  const AddVehicleScreen({super.key, this.vehicleToEdit});

  @override
  State<AddVehicleScreen> createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final _imagePicker = ImagePicker();

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
  String? _uploadStatus;

  // ─────────────────────────────────────────────
  // VERIFICACIÓN DE PLACA
  // ─────────────────────────────────────────────
  bool _plateVerifying = false;
  String? _plateError;
  bool _plateAvailable = false;
  Timer? _plateDebounce;
  String? _plateAlertMessage;

  // ─────────────────────────────────────────────
  // IMÁGENES: TARJETA DE PROPIEDAD + 3 FOTOS
  // ─────────────────────────────────────────────
  XFile? _tarjetaPropiedadFile;
  String? _tarjetaPropiedadUrl;

  final List<XFile?> _photoFiles = [null, null, null];
  final List<String?> _photoUrls = [null, null, null];

  @override
  void initState() {
    super.initState();
    _platesController.addListener(_onPlateChanged);

    if (widget.vehicleToEdit != null) {
      _loadEditData();
    }
  }

  void _loadEditData() {
    final v = widget.vehicleToEdit;
    _brandController.text = v['marca'] ?? '';
    _modelController.text = v['modelo'] ?? '';
    _platesController.text = v['placa'] ?? '';
    _colorController.text = v['color'] ?? '';
    _yearController.text = v['anio']?.toString() ?? '';

    const validTypes = [
      'Automóvil', 'Sedán', 'SUV', 'Camioneta',
      'Hatchback', 'Pickup', 'Van', 'Moto', 'Otro'
    ];
    final rawType = v['tipoVehiculo']?.toString();
    if (rawType != null) {
      try {
        _vehicleType = validTypes.firstWhere(
          (t) => t.toLowerCase() == rawType.toLowerCase(),
        );
      } catch (_) {
        _vehicleType = 'Automóvil';
      }
    } else {
      _vehicleType = 'Automóvil';
    }

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

    // Cargar URLs de imágenes existentes
    if (v['tarjetaPropiedad'] != null && v['tarjetaPropiedad'].toString().isNotEmpty) {
      _tarjetaPropiedadUrl = v['tarjetaPropiedad'].toString();
    }

    final fotos = v['fotos'];
    if (fotos is List) {
      for (int i = 0; i < fotos.length && i < 3; i++) {
        if (fotos[i] != null && fotos[i].toString().isNotEmpty) {
          _photoUrls[i] = fotos[i].toString();
        }
      }
    }

    // En modo edición, la placa ya existe así que no necesitamos verificar
    if (_platesController.text.isNotEmpty) {
      _plateAvailable = true;
    }
  }

  @override
  void dispose() {
    _platesController.removeListener(_onPlateChanged);
    _brandController.dispose();
    _modelController.dispose();
    _platesController.dispose();
    _colorController.dispose();
    _yearController.dispose();
    _soatDateController.dispose();
    _tecnoDateController.dispose();
    _plateDebounce?.cancel();
    super.dispose();
  }

  // ─────────────────────────────────────────────
  // VERIFICACIÓN DE PLACA EN TIEMPO REAL
  // ─────────────────────────────────────────────
  void _onPlateChanged() {
    final placa = _platesController.text.trim().toUpperCase();
    final isEditing = widget.vehicleToEdit != null;

    // Si estamos editando y la placa no cambió, no verificar
    if (isEditing) {
      final originalPlaca = (widget.vehicleToEdit['placa'] ?? '').toString().trim().toUpperCase();
      if (placa == originalPlaca) {
        setState(() {
          _plateError = null;
          _plateAvailable = true;
          _plateVerifying = false;
          _plateAlertMessage = null;
        });
        return;
      }
    }

    if (placa.length < 6) {
      setState(() {
        _plateError = null;
        _plateAvailable = false;
        _plateVerifying = false;
        _plateAlertMessage = null;
      });
      return;
    }

    final plateRegex = RegExp(r'^[A-Z]{3}[0-9]{3}$');
    if (!plateRegex.hasMatch(placa)) {
      setState(() {
        _plateError = 'Debe tener 3 letras y 3 números (ej. ABC123)';
        _plateAvailable = false;
        _plateVerifying = false;
        _plateAlertMessage = _plateError;
      });
      return;
    }

    setState(() {
      _plateVerifying = true;
      _plateError = null;
      _plateAvailable = false;
      _plateAlertMessage = null;
    });

    _plateDebounce?.cancel();
    _plateDebounce = Timer(const Duration(milliseconds: 500), () async {
      try {
        final result = await VehiculoService.verificarPlaca(placa);
        if (!mounted) return;
        final existe = result['existe'] == true;
        final permitido = result['permitido'] == true;

        if (existe && !permitido) {
          setState(() {
            _plateError = result['mensaje'] ?? 'Esta placa ya está registrada.';
            _plateAvailable = false;
            _plateAlertMessage = _plateError;
          });
        } else if (existe && permitido) {
          // Vehículo vendido, se puede reusar
          setState(() {
            _plateError = null;
            _plateAvailable = true;
            _plateAlertMessage = result['mensaje'];
          });
        } else {
          setState(() {
            _plateError = null;
            _plateAvailable = true;
            _plateAlertMessage = null;
          });
        }
      } catch (e) {
        if (!mounted) return;
        debugPrint('Error verificando placa: $e');
      } finally {
        if (mounted) {
          setState(() => _plateVerifying = false);
        }
      }
    });
  }

  // ─────────────────────────────────────────────
  // SELECTOR DE IMÁGENES (CÁMARA / GALERÍA)
  // ─────────────────────────────────────────────
  Future<void> _pickImage({
    required String title,
    required Function(XFile) onPicked,
  }) async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderGray,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _imageSourceButton(
                    icon: Icons.camera_alt_rounded,
                    label: 'Cámara',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await _imagePicker.pickImage(
                        source: ImageSource.camera,
                        imageQuality: 80,
                        maxWidth: 1200,
                      );
                      if (file != null) onPicked(file);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _imageSourceButton(
                    icon: Icons.photo_library_rounded,
                    label: 'Galería',
                    onTap: () async {
                      Navigator.pop(ctx);
                      final file = await _imagePicker.pickImage(
                        source: ImageSource.gallery,
                        imageQuality: 80,
                        maxWidth: 1200,
                      );
                      if (file != null) onPicked(file);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _imageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.borderGray),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: AppColors.petrolBase),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // SELECTOR DE FECHAS
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
      firstDate: today,
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
      firstDate: today,
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

    // Verificar que la placa esté disponible
    if (_plateError != null && _plateError!.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(_plateError!),
        ),
      );
      return;
    }

    if (_plateVerifying) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.accentOrange,
          content: Text('Espera mientras se verifica la placa...'),
        ),
      );
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isEditing = widget.vehicleToEdit != null;

    if (!isEditing && _fechaVencimientoSoat != null && _fechaVencimientoSoat!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('No se permite registrar con el SOAT vencido.'),
        ),
      );
      return;
    }

    if (!isEditing && _fechaVencimientoTecnomecanica != null && _fechaVencimientoTecnomecanica!.isBefore(today)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('No se permite registrar con la tecnomecánica vencida.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _uploadStatus = 'Preparando...';
    });

    try {
      final usuarioId = await AuthService.obtenerUsuarioId();
      if (usuarioId == null) throw Exception('No hay usuario activo en sesión.');

      // Extracción segura del clienteId
      String? clienteId;
      if (isEditing) {
        final c = widget.vehicleToEdit['cliente'];
        if (c is Map) {
          clienteId = (c['_id'] ?? c['id'])?.toString();
        } else if (c != null) {
          clienteId = c.toString();
        }
      }
      clienteId ??= usuarioId;

      // ── SUBIR IMÁGENES A CLOUDINARY ──
      String? tarjetaPropiedadFinalUrl = _tarjetaPropiedadUrl;
      List<String> fotosFinalUrls = List.from(_photoUrls.map((u) => u ?? ''));

      // Tarjeta de propiedad
      if (_tarjetaPropiedadFile != null) {
        setState(() => _uploadStatus = 'Subiendo tarjeta de propiedad...');
        tarjetaPropiedadFinalUrl = await CloudinaryService.subirImagen(
          _tarjetaPropiedadFile!,
          folder: 'vehiculos/tarjetas',
        );
      }

      // Fotos del vehículo
      for (int i = 0; i < 3; i++) {
        if (_photoFiles[i] != null) {
          setState(() => _uploadStatus = 'Subiendo foto ${i + 1} de 3...');
          fotosFinalUrls[i] = await CloudinaryService.subirImagen(
            _photoFiles[i]!,
            folder: 'vehiculos/fotos',
          );
        }
      }

      setState(() => _uploadStatus = 'Guardando vehículo...');

      final vehiculoData = <String, dynamic>{
        'cliente': clienteId,
        'marca': _brandController.text.trim(),
        'modelo': _modelController.text.trim().isEmpty
            ? _brandController.text.trim()
            : _modelController.text.trim(),
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
        'numeroPuertas': widget.vehicleToEdit?['numeroPuertas'] ?? 4,
        'tipoCombustible': widget.vehicleToEdit?['tipoCombustible'] ?? 'Gasolina',
        'estadoSeguro': widget.vehicleToEdit?['estadoSeguro'] ?? 'Activo',
        'companiaAseguradora': widget.vehicleToEdit?['companiaAseguradora'] ?? 'N/A',
        'estado': true,
      };

      // Agregar imágenes al payload exactamente igual que la versión web
      if (tarjetaPropiedadFinalUrl != null && tarjetaPropiedadFinalUrl.isNotEmpty) {
        vehiculoData['tarjetaPropiedad'] = tarjetaPropiedadFinalUrl;
      }

      final fotosNoVacias = fotosFinalUrls.where((u) => u.isNotEmpty).toList();
      if (fotosNoVacias.isNotEmpty) {
        vehiculoData['fotos'] = fotosNoVacias;
        vehiculoData['foto'] = fotosNoVacias.first;
      }
      if (fotosFinalUrls.isNotEmpty && fotosFinalUrls[0].isNotEmpty) {
        vehiculoData['foto1'] = fotosFinalUrls[0];
      }
      if (fotosFinalUrls.length > 1 && fotosFinalUrls[1].isNotEmpty) {
        vehiculoData['foto2'] = fotosFinalUrls[1];
      }
      if (fotosFinalUrls.length > 2 && fotosFinalUrls[2].isNotEmpty) {
        vehiculoData['foto3'] = fotosFinalUrls[2];
      }

      // Si existe un número de chasis real en el vehículo a editar, preservarlo; de lo contrario generar VIN como en la web
      final chasisExistente = widget.vehicleToEdit?['numeroChasis']?.toString();
      if (chasisExistente != null && chasisExistente.isNotEmpty && chasisExistente != '00000') {
        vehiculoData['numeroChasis'] = chasisExistente;
      } else {
        vehiculoData['numeroChasis'] = 'VIN-${DateTime.now().millisecondsSinceEpoch}';
      }

      if (isEditing) {
        final id = (widget.vehicleToEdit['_id'] ?? widget.vehicleToEdit['id'])?.toString();
        if (id == null || id.isEmpty) {
          throw Exception('No se encontró el identificador del vehículo a editar.');
        }
        await VehiculoService.update(id, vehiculoData);
      } else {
        await VehiculoService.crear(vehiculoData);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.success,
            content: Text(isEditing
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
        setState(() {
          _isLoading = false;
          _uploadStatus = null;
        });
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
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petrolDark,
                ),
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
    bool isRequired = true,
    Widget? suffixIcon,
  }) {
    final label = isRequired
        ? RichText(
            text: TextSpan(
              text: labelText,
              style: const TextStyle(fontSize: 14, color: AppColors.slateGray),
              children: const [
                TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        : null;

    return InputDecoration(
      labelText: isRequired ? null : labelText,
      label: label,
      hintText: hintText,
      prefixIcon: Icon(prefixIcon, color: AppColors.slateGray, size: 20),
      suffixIcon: suffixIcon,
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

  // ─────────────────────────────────────────────
  // WIDGET DE IMAGEN (TARJETA / FOTOS)
  // ─────────────────────────────────────────────
  Widget _buildImagePicker({
    required String label,
    XFile? file,
    String? url,
    required VoidCallback onTap,
    VoidCallback? onRemove,
    bool isRequired = false,
  }) {
    final hasImage = file != null || (url != null && url.isNotEmpty);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasImage ? AppColors.success.withOpacity(0.5) : AppColors.borderGray,
            width: hasImage ? 2 : 1,
          ),
        ),
        child: hasImage
            ? Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: file != null
                        ? FutureBuilder<List<int>>(
                            future: file.readAsBytes(),
                            builder: (ctx, snap) {
                              if (snap.hasData) {
                                return Image.memory(
                                  snap.data! as dynamic,
                                  fit: BoxFit.cover,
                                );
                              }
                              return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                            },
                          )
                        : Image.network(
                            url!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(Icons.broken_image, color: AppColors.slateGray, size: 36),
                            ),
                          ),
                  ),
                  if (onRemove != null)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: AppColors.danger,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.close, color: Colors.white, size: 16),
                        ),
                      ),
                    ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.black.withOpacity(0.6),
                            Colors.transparent,
                          ],
                        ),
                        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(15)),
                      ),
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.success, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_a_photo_rounded,
                    size: 30,
                    color: AppColors.slateGray.withOpacity(0.5),
                  ),
                  const SizedBox(height: 8),
                  RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      text: label,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slateGray.withOpacity(0.7),
                      ),
                      children: isRequired
                          ? const [
                              TextSpan(
                                text: ' *',
                                style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.bold),
                              ),
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Toca para subir',
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.slateGray.withOpacity(0.5),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // PLATE STATUS INDICATOR
  // ─────────────────────────────────────────────
  Widget? _buildPlateStatus() {
    if (_plateVerifying) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOrange),
            ),
            SizedBox(width: 8),
            Text(
              'Verificando placa...',
              style: TextStyle(fontSize: 12, color: AppColors.accentOrange, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    if (_plateError != null && _plateError!.isNotEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.error_outline, size: 14, color: AppColors.danger),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _plateError!,
                style: const TextStyle(fontSize: 12, color: AppColors.danger, fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
    }

    if (_plateAvailable && _platesController.text.trim().length >= 6) {
      return const Padding(
        padding: EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(Icons.check_circle, size: 14, color: AppColors.success),
            SizedBox(width: 6),
            Text(
              'Placa disponible ✓',
              style: TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      );
    }

    return null;
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
        child: Stack(
          children: [
            SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ═══════════════════════════════════════════
                    // ALERTA DE PLACA DUPLICADA
                    // ═══════════════════════════════════════════
                    if (_plateAlertMessage != null && _plateAlertMessage!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: _plateError != null ? const Color(0xFFFEF2F2) : const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _plateError != null ? const Color(0xFFFECACA) : const Color(0xFFFDE68A),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              _plateError != null ? Icons.warning_amber_rounded : Icons.info_outline_rounded,
                              color: _plateError != null ? AppColors.danger : AppColors.accentOrange,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _plateAlertMessage!,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: _plateError != null ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                                ),
                              ),
                            ),
                            GestureDetector(
                              onTap: () => setState(() => _plateAlertMessage = null),
                              child: Icon(
                                Icons.close,
                                size: 18,
                                color: _plateError != null ? const Color(0xFF991B1B) : const Color(0xFF92400E),
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Indicador de campos obligatorios
                    const Padding(
                      padding: EdgeInsets.only(bottom: 14),
                      child: Row(
                        children: [
                          Text(
                            'Los campos marcados con ',
                            style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                          ),
                          Text(
                            '*',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.danger,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            ' son obligatorios.',
                            style: TextStyle(fontSize: 12, color: AppColors.slateGray),
                          ),
                        ],
                      ),
                    ),

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
                        // 1. TIPO DE VEHÍCULO (PRIMERO)
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
                        const SizedBox(height: 14),

                        // 2. PLACA (SEGUNDO - CON VERIFICACIÓN)
                        TextFormField(
                          controller: _platesController,
                          textCapitalization: TextCapitalization.characters,
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                            LengthLimitingTextInputFormatter(6),
                          ],
                          decoration: _inputDecoration(
                            labelText: 'PLACA',
                            hintText: 'Ej. abc123',
                            prefixIcon: Icons.confirmation_number_outlined,
                            suffixIcon: _plateVerifying
                                ? const Padding(
                                    padding: EdgeInsets.all(12),
                                    child: SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentOrange),
                                    ),
                                  )
                                : _plateAvailable && _platesController.text.trim().length >= 6
                                    ? const Icon(Icons.check_circle, color: AppColors.success, size: 22)
                                    : _plateError != null
                                        ? const Icon(Icons.cancel, color: AppColors.danger, size: 22)
                                        : null,
                          ),
                          validator: (value) {
                            final val = value?.trim() ?? '';
                            if (val.isEmpty) {
                              return 'Ingresa la placa del vehículo';
                            }
                            final regex = RegExp(r'^[a-zA-Z]{3}[0-9]{3}$');
                            if (!regex.hasMatch(val)) {
                              return 'Debe tener 3 letras y 3 números (ej. abc123)';
                            }
                            return null;
                          },
                        ),
                        // Plate verification status
                        if (_buildPlateStatus() != null) _buildPlateStatus()!,
                        const SizedBox(height: 14),

                        // 3. MARCA
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

                        // 4. MODELO
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

                        // 5. AÑO
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

                        // 6. COLOR
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
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════
                    // SECCIÓN 2: TARJETA DE PROPIEDAD
                    // ═══════════════════════════════════════════
                    _buildSectionHeader(
                      'Tarjeta de Propiedad',
                      'Documento de tránsito obligatorio del vehículo',
                    ),
                    const SizedBox(height: 12),
                    _buildCardContainer(
                      children: [
                        _buildImagePicker(
                          label: 'Tarjeta de Propiedad',
                          file: _tarjetaPropiedadFile,
                          url: _tarjetaPropiedadUrl,
                          isRequired: true,
                          onTap: () => _pickImage(
                            title: 'Subir Tarjeta de Propiedad',
                            onPicked: (file) {
                              setState(() {
                                _tarjetaPropiedadFile = file;
                                _tarjetaPropiedadUrl = null;
                              });
                            },
                          ),
                          onRemove: (_tarjetaPropiedadFile != null || _tarjetaPropiedadUrl != null)
                              ? () => setState(() {
                                    _tarjetaPropiedadFile = null;
                                    _tarjetaPropiedadUrl = null;
                                  })
                              : null,
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════
                    // SECCIÓN 3: FOTOS DEL VEHÍCULO
                    // ═══════════════════════════════════════════
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: _buildSectionHeader(
                            'Fotos del Vehículo',
                            'Sube hasta 3 fotos para verificar el estado físico',
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrangeBg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${_photoFiles.where((f) => f != null).length + _photoUrls.where((u) => u != null && u.isNotEmpty && !_photoFiles.asMap().entries.any((e) => e.value != null && _photoUrls.indexOf(u) == e.key)).length}/3',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.accentOrange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _buildCardContainer(
                      children: [
                        Row(
                          children: List.generate(3, (i) {
                            return Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: i == 0 ? 0 : 6,
                                  right: i == 2 ? 0 : 6,
                                ),
                                child: _buildImagePicker(
                                  label: 'Foto ${i + 1}',
                                  file: _photoFiles[i],
                                  url: _photoUrls[i],
                                  onTap: () => _pickImage(
                                    title: 'Subir Foto ${i + 1}',
                                    onPicked: (file) {
                                      setState(() {
                                        _photoFiles[i] = file;
                                        _photoUrls[i] = null;
                                      });
                                    },
                                  ),
                                  onRemove: (_photoFiles[i] != null || (_photoUrls[i] != null && _photoUrls[i]!.isNotEmpty))
                                      ? () => setState(() {
                                            _photoFiles[i] = null;
                                            _photoUrls[i] = null;
                                          })
                                      : null,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ═══════════════════════════════════════════
                    // SECCIÓN 4: VIGENCIA DE DOCUMENTACIÓN
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
                                isRequired: false,
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
                                isRequired: false,
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
                          onPressed: (_isLoading || _plateVerifying || (_plateError != null && _plateError!.isNotEmpty))
                              ? null
                              : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: AppColors.white,
                            disabledBackgroundColor: Colors.transparent,
                            disabledForegroundColor: Colors.white70,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isLoading
                              ? Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const SizedBox(
                                      height: 22,
                                      width: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.2,
                                      ),
                                    ),
                                    if (_uploadStatus != null) ...[
                                      const SizedBox(height: 6),
                                      Text(
                                        _uploadStatus!,
                                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                                      ),
                                    ],
                                  ],
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

            // ── OVERLAY DE CARGA ──
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(color: AppColors.petrolBase),
                        const SizedBox(height: 16),
                        Text(
                          _uploadStatus ?? 'Procesando...',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}