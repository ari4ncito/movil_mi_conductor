import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../models/solicitud.dart';
import '../../services/cloudinary_service.dart';
import '../../services/invitado_service.dart';
import '../client/services/searching_driver_screen.dart';

// ─────────────────────────────────────────────
// Paleta unificada Mi Conductor
// ─────────────────────────────────────────────
class AppColors {
  static const Color background = Color(0xFFF2F5F6);
  static const Color petrolDark = Color(0xFF0B3B4A);
  static const Color petrolBase = Color(0xFF12566B);
  static const Color petrolLight = Color(0xFF1D7A94);
  static const Color petrolPale = Color(0xFFDCE9EA);
  static const Color slateGray = Color(0xFF5C6B73);
  static const Color borderGray = Color(0xFFE1E7E9);
  static const Color textPrimary = Color(0xFF16262D);
  static const Color textSecondary = Color(0xFF6B7C80);
  static const Color accentOrange = Color(0xFFE8821E);
  static const Color accentOrangeDark = Color(0xFFC96A1B);
  static const Color accentOrangeSoft = Color(0xFFFCEADA);
  static const Color successGreen = Color(0xFF16A34A);
  static const Color successGreenSoft = Color(0xFFDCFCE7);
  static const Color dangerRed = Color(0xFFDC2626);
  static const Color white = Colors.white;
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class GuestRideFormScreen extends StatefulWidget {
  final bool isForThirdParty;

  const GuestRideFormScreen({
    super.key,
    this.isForThirdParty = false,
  });

  @override
  State<GuestRideFormScreen> createState() => _GuestRideFormScreenState();
}

class _GuestRideFormScreenState extends State<GuestRideFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  AutovalidateMode _autoValidateMode = AutovalidateMode.onUserInteraction;

  bool _tarjetaMissing = false;
  bool _soatMissing = false;
  bool _tecnoMissing = false;
  final _imagePicker = ImagePicker();

  final List<String> _tiposDocumento = const ['CC', 'CE', 'TI', 'PPT', 'PAS'];

  // ─────────────────────────────────────────────
  // 1. DATOS DEL BENEFICIARIO (O PROPIOS)
  // ─────────────────────────────────────────────
  String _beneficiarioTipoDoc = 'CC';
  final _beneficiarioDocController = TextEditingController();
  final _beneficiarioNombreController = TextEditingController();
  final _beneficiarioTelefonoController = TextEditingController();
  final _beneficiarioCorreoController = TextEditingController();

  bool _beneficiarioChecking = false;
  bool? _beneficiarioFound;
  String? _beneficiarioStatusMsg;
  String? _beneficiarioLastDoc;
  Timer? _beneficiarioDebounce;

  // Lista de vehículos traídos del backend si el usuario tiene registrados
  List<Map<String, dynamic>> _vehiculosEncontrados = [];
  String? _vehiculoSeleccionadoId;
  bool _vehiculoAutocargado = false;

  // ─────────────────────────────────────────────
  // 2. DATOS DEL SOLICITANTE (SOLO PARA TERCEROS)
  // ─────────────────────────────────────────────
  String _solicitanteTipoDoc = 'CC';
  final _solicitanteDocController = TextEditingController();
  final _solicitanteNombreController = TextEditingController();
  final _solicitanteTelefonoController = TextEditingController();
  final _solicitanteCorreoController = TextEditingController();

  bool _solicitanteChecking = false;
  bool? _solicitanteFound;
  String? _solicitanteStatusMsg;
  String? _solicitanteLastDoc;
  Timer? _solicitanteDebounce;

  // ─────────────────────────────────────────────
  // 3. INFORMACIÓN DEL SERVICIO
  // ─────────────────────────────────────────────
  final _origenController = TextEditingController();
  final _destinoController = TextEditingController();
  final _observacionesController = TextEditingController();
  final DateTime _fechaProgramada = DateTime.now();

  // ─────────────────────────────────────────────
  // 4. DATOS DEL VEHÍCULO
  // ─────────────────────────────────────────────
  final _vehiculoMarcaController = TextEditingController();
  final _vehiculoModeloController = TextEditingController();
  final _vehiculoAnioController = TextEditingController();
  final _vehiculoPlacaController = TextEditingController();
  final _vehiculoColorController = TextEditingController();

  // ─────────────────────────────────────────────
  // 5. DOCUMENTACIÓN DEL VEHÍCULO (3 FOTOS)
  // (Solo necesaria si se registra un vehículo nuevo)
  // ─────────────────────────────────────────────
  Uint8List? _tarjetaBytes;
  String? _tarjetaUrl;
  bool _tarjetaUploading = false;

  Uint8List? _soatBytes;
  String? _soatUrl;
  bool _soatUploading = false;

  Uint8List? _tecnoBytes;
  String? _tecnoUrl;
  bool _tecnoUploading = false;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _beneficiarioDocController.addListener(_onBeneficiarioDocChanged);
    if (widget.isForThirdParty) {
      _solicitanteDocController.addListener(_onSolicitanteDocChanged);
    }
  }

  @override
  void dispose() {
    _beneficiarioDebounce?.cancel();
    _solicitanteDebounce?.cancel();
    _scrollController.dispose();

    _beneficiarioDocController.dispose();
    _beneficiarioNombreController.dispose();
    _beneficiarioTelefonoController.dispose();
    _beneficiarioCorreoController.dispose();

    _solicitanteDocController.dispose();
    _solicitanteNombreController.dispose();
    _solicitanteTelefonoController.dispose();
    _solicitanteCorreoController.dispose();

    _origenController.dispose();
    _destinoController.dispose();
    _observacionesController.dispose();

    _vehiculoMarcaController.dispose();
    _vehiculoModeloController.dispose();
    _vehiculoAnioController.dispose();
    _vehiculoPlacaController.dispose();
    _vehiculoColorController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────
  // LIMPIAR TODOS LOS CAMPOS SI CAMBIA EL DOCUMENTO
  // ─────────────────────────────────────────────
  void _limpiarCamposBeneficiarioYVehiculo() {
    _beneficiarioNombreController.clear();
    _beneficiarioTelefonoController.clear();
    _beneficiarioCorreoController.clear();

    _vehiculoMarcaController.clear();
    _vehiculoModeloController.clear();
    _vehiculoPlacaController.clear();
    _vehiculoAnioController.clear();
    _vehiculoColorController.clear();

    _tarjetaBytes = null;
    _tarjetaUrl = null;

    _soatBytes = null;
    _soatUrl = null;

    _tecnoBytes = null;
    _tecnoUrl = null;

    _tarjetaMissing = false;
    _soatMissing = false;
    _tecnoMissing = false;

    _vehiculosEncontrados = [];
    _vehiculoSeleccionadoId = null;
    _vehiculoAutocargado = false;

    _beneficiarioFound = null;
    _beneficiarioStatusMsg = null;
    _beneficiarioChecking = false;
  }

  void _limpiarCamposSolicitante() {
    _solicitanteNombreController.clear();
    _solicitanteTelefonoController.clear();
    _solicitanteCorreoController.clear();
    _solicitanteFound = null;
    _solicitanteStatusMsg = null;
    _solicitanteChecking = false;

    // Si el vehículo actual se había autocargado desde el solicitante y el beneficiario no aportó vehículo
    if (_beneficiarioFound != true && _vehiculoAutocargado) {
      _vehiculoMarcaController.clear();
      _vehiculoModeloController.clear();
      _vehiculoPlacaController.clear();
      _vehiculoAnioController.clear();
      _vehiculoColorController.clear();
      _tarjetaBytes = null;
      _tarjetaUrl = null;
      _soatBytes = null;
      _soatUrl = null;
      _tecnoBytes = null;
      _tecnoUrl = null;
      _tarjetaMissing = false;
      _soatMissing = false;
      _tecnoMissing = false;
      _vehiculosEncontrados = [];
      _vehiculoSeleccionadoId = null;
      _vehiculoAutocargado = false;
    }
  }

  // ─────────────────────────────────────────────
  // AUTOCOMPLETADO BENEFICIARIO
  // ─────────────────────────────────────────────
  void _onBeneficiarioDocChanged() {
    final doc = _beneficiarioDocController.text.trim();
    _beneficiarioDebounce?.cancel();

    if (doc != _beneficiarioLastDoc) {
      // Si cambia el documento, limpiar todos los campos para evitar residuos
      setState(() {
        _limpiarCamposBeneficiarioYVehiculo();
      });
    }

    if (doc.length < 5) return;

    _beneficiarioDebounce = Timer(const Duration(milliseconds: 600), () async {
      await _consultarBeneficiario(doc);
    });
  }

  Future<void> _consultarBeneficiario(String doc) async {
    setState(() {
      _beneficiarioChecking = true;
      _beneficiarioStatusMsg = 'Verificando documento en el sistema...';
    });

    try {
      final res = await InvitadoService.consultarPorDocumento(
        doc,
        tipoDocumento: _beneficiarioTipoDoc,
      );

      if (!mounted) return;

      _beneficiarioLastDoc = doc;

      if (res['existe'] == true && res['datos'] != null) {
        final d = res['datos'] as Map<String, dynamic>;
        setState(() {
          _beneficiarioChecking = false;
          _beneficiarioFound = true;

          // Autocompletar datos personales
          final nombre = d['nombreCompleto']?.toString() ??
              '${d['nombre'] ?? ''} ${d['apellido'] ?? ''}'.trim();
          if (nombre.isNotEmpty) _beneficiarioNombreController.text = nombre;

          final tel = d['telefono']?.toString() ?? '';
          if (tel.isNotEmpty) _beneficiarioTelefonoController.text = tel;

          final correo = d['correo']?.toString() ?? '';
          if (correo.isNotEmpty) _beneficiarioCorreoController.text = correo;

          final tipo = d['tipoDocumento']?.toString().toUpperCase() ?? '';
          if (_tiposDocumento.contains(tipo)) {
            _beneficiarioTipoDoc = tipo;
          }

          // Cargar vehículos si existen en la respuesta
          final rawVehiculos = d['vehiculos'];
          if (rawVehiculos is List && rawVehiculos.isNotEmpty) {
            _vehiculosEncontrados = rawVehiculos
                .whereType<Map>()
                .map((item) => Map<String, dynamic>.from(item))
                .toList();
          } else if (d['vehiculo'] is Map) {
            _vehiculosEncontrados = [Map<String, dynamic>.from(d['vehiculo'])];
          } else {
            _vehiculosEncontrados = [];
          }

          if (_vehiculosEncontrados.isNotEmpty) {
            _aplicarVehiculo(_vehiculosEncontrados.first);
            _beneficiarioStatusMsg =
                '¡Persona y vehículo encontrados! Datos autocompletados con éxito.';
          } else {
            _beneficiarioStatusMsg =
                '¡Persona registrada! Datos personales cargados automáticamente.';
          }
        });
      } else {
        setState(() {
          _limpiarCamposBeneficiarioYVehiculo();
          _beneficiarioChecking = false;
          _beneficiarioFound = false;
          _beneficiarioStatusMsg =
              'Documento no registrado. Puedes diligenciar los datos manualmente.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _limpiarCamposBeneficiarioYVehiculo();
          _beneficiarioChecking = false;
          _beneficiarioFound = null;
          _beneficiarioStatusMsg =
              'No se pudo verificar en línea. Puedes ingresar los datos manualmente.';
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // APLICAR DATOS DE VEHÍCULO
  // ─────────────────────────────────────────────
  void _aplicarVehiculo(Map<String, dynamic> v) {
    _vehiculoSeleccionadoId = v['id']?.toString() ?? v['_id']?.toString();
    _vehiculoAutocargado = true;

    if (v['marca'] != null && v['marca'].toString().isNotEmpty) {
      _vehiculoMarcaController.text = v['marca'].toString();
    }
    if (v['modelo'] != null && v['modelo'].toString().isNotEmpty) {
      _vehiculoModeloController.text = v['modelo'].toString();
    }
    if (v['placa'] != null && v['placa'].toString().isNotEmpty) {
      _vehiculoPlacaController.text = v['placa']
          .toString()
          .trim()
          .replaceAll(' ', '')
          .replaceAll('-', '')
          .toUpperCase();
    }
    if (v['anio'] != null && v['anio'].toString().isNotEmpty) {
      _vehiculoAnioController.text = v['anio'].toString();
    }
    if (v['color'] != null && v['color'].toString().isNotEmpty) {
      _vehiculoColorController.text = v['color'].toString();
    }

    // Cargar URLs de documentos si existen
    if (v['tarjetaPropiedad'] != null && v['tarjetaPropiedad'].toString().isNotEmpty) {
      _tarjetaUrl = v['tarjetaPropiedad'].toString();
    }
    if (v['soat'] != null && v['soat'].toString().isNotEmpty) {
      _soatUrl = v['soat'].toString();
    }
    if (v['tecnomecanica'] != null && v['tecnomecanica'].toString().isNotEmpty) {
      _tecnoUrl = v['tecnomecanica'].toString();
    }
  }

  // ─────────────────────────────────────────────
  // AUTOCOMPLETADO SOLICITANTE (PARA TERCERO)
  // ─────────────────────────────────────────────
  void _onSolicitanteDocChanged() {
    final doc = _solicitanteDocController.text.trim();
    _solicitanteDebounce?.cancel();

    if (doc != _solicitanteLastDoc) {
      setState(() {
        _limpiarCamposSolicitante();
      });
    }

    if (doc.length < 5) return;

    _solicitanteDebounce = Timer(const Duration(milliseconds: 600), () async {
      await _consultarSolicitante(doc);
    });
  }

  Future<void> _consultarSolicitante(String doc) async {
    setState(() {
      _solicitanteChecking = true;
      _solicitanteStatusMsg = 'Verificando documento en el sistema...';
    });

    try {
      final res = await InvitadoService.consultarPorDocumento(
        doc,
        tipoDocumento: _solicitanteTipoDoc,
      );

      if (!mounted) return;

      _solicitanteLastDoc = doc;

      if (res['existe'] == true && res['datos'] != null) {
        final d = res['datos'] as Map<String, dynamic>;
        setState(() {
          _solicitanteChecking = false;
          _solicitanteFound = true;
          _solicitanteStatusMsg =
              '¡Persona registrada! Datos cargados automáticamente.';

          final nombre = d['nombreCompleto']?.toString() ??
              '${d['nombre'] ?? ''} ${d['apellido'] ?? ''}'.trim();
          if (nombre.isNotEmpty) _solicitanteNombreController.text = nombre;

          final tel = d['telefono']?.toString() ?? '';
          if (tel.isNotEmpty) _solicitanteTelefonoController.text = tel;

          final correo = d['correo']?.toString() ?? '';
          if (correo.isNotEmpty) _solicitanteCorreoController.text = correo;

          final tipo = d['tipoDocumento']?.toString().toUpperCase() ?? '';
          if (_tiposDocumento.contains(tipo)) {
            _solicitanteTipoDoc = tipo;
          }

          // Si el beneficiario no tenía vehículos y el solicitante sí tiene
          if (_vehiculoPlacaController.text.isEmpty && _vehiculosEncontrados.isEmpty) {
            final rawVehiculos = d['vehiculos'];
            if (rawVehiculos is List && rawVehiculos.isNotEmpty) {
              _vehiculosEncontrados = rawVehiculos
                  .whereType<Map>()
                  .map((item) => Map<String, dynamic>.from(item))
                  .toList();
              _aplicarVehiculo(_vehiculosEncontrados.first);
            }
          }
        });
      } else {
        setState(() {
          _limpiarCamposSolicitante();
          _solicitanteChecking = false;
          _solicitanteFound = false;
          _solicitanteStatusMsg =
              'Documento no registrado. Puedes diligenciar los datos manualmente.';
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _limpiarCamposSolicitante();
          _solicitanteChecking = false;
          _solicitanteFound = null;
          _solicitanteStatusMsg =
              'No se pudo verificar en línea. Puedes ingresar los datos manualmente.';
        });
      }
    }
  }

  // ─────────────────────────────────────────────
  // CARGA DE FOTOGRAFÍAS (CLOUDINARY)
  // ─────────────────────────────────────────────
  Future<void> _pickAndUploadImage({
    required ImageSource source,
    required String docKey,
  }) async {
    try {
      final file = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file == null) return;

      final bytes = await file.readAsBytes();

      setState(() {
        if (docKey == 'tarjeta') {
          _tarjetaBytes = bytes;
          _tarjetaUploading = true;
        } else if (docKey == 'soat') {
          _soatBytes = bytes;
          _soatUploading = true;
        } else if (docKey == 'tecno') {
          _tecnoBytes = bytes;
          _tecnoUploading = true;
        }
      });

      final url = await CloudinaryService.subirImagen(
        file,
        folder: 'invitados/documentos',
      );

      if (!mounted) return;

      setState(() {
        if (docKey == 'tarjeta') {
          _tarjetaUrl = url;
          _tarjetaUploading = false;
        } else if (docKey == 'soat') {
          _soatUrl = url;
          _soatUploading = false;
        } else if (docKey == 'tecno') {
          _tecnoUrl = url;
          _tecnoUploading = false;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Documento adjuntado correctamente.'),
          backgroundColor: AppColors.successGreen,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (docKey == 'tarjeta') _tarjetaUploading = false;
        if (docKey == 'soat') _soatUploading = false;
        if (docKey == 'tecno') _tecnoUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al subir el documento: $e'),
          backgroundColor: AppColors.dangerRed,
        ),
      );
    }
  }

  void _showImageSourceDialog(String docKey) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Adjuntar Documento',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.petrolDark,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Selecciona el método de captura de la fotografía:',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.petrolPale,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.camera_alt_rounded,
                    color: AppColors.petrolBase,
                  ),
                ),
                title: const Text(
                  'Tomar Fotografía con la Cámara',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(
                    source: ImageSource.camera,
                    docKey: docKey,
                  );
                },
              ),
              const SizedBox(height: 8),
              ListTile(
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.accentOrangeSoft,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.photo_library_rounded,
                    color: AppColors.accentOrangeDark,
                  ),
                ),
                title: const Text(
                  'Seleccionar desde la Galería',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                onTap: () {
                  Navigator.of(ctx).pop();
                  _pickAndUploadImage(
                    source: ImageSource.gallery,
                    docKey: docKey,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  // ENVÍO DE LA SOLICITUD
  // ─────────────────────────────────────────────
  Future<void> _submitRequest() async {
    setState(() {
      _autoValidateMode = AutovalidateMode.onUserInteraction;
    });

    final formValid = _formKey.currentState!.validate();

    final tieneVehiculoAsociado = _vehiculoAutocargado ||
        _vehiculosEncontrados.isNotEmpty ||
        (_vehiculoSeleccionadoId != null && _vehiculoSeleccionadoId!.isNotEmpty);

    bool missingDocs = false;
    if (!tieneVehiculoAsociado) {
      setState(() {
        _tarjetaMissing = _tarjetaUrl == null || _tarjetaUrl!.isEmpty;
        _soatMissing = _soatUrl == null || _soatUrl!.isEmpty;
        _tecnoMissing = _tecnoUrl == null || _tecnoUrl!.isEmpty;
      });
      if (_tarjetaMissing || _soatMissing || _tecnoMissing) {
        missingDocs = true;
      }
    }

    if (!formValid) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
      _showError('Por favor completa todos los campos requeridos marcados en rojo.');
      return;
    }

    if (missingDocs) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
      _showError('Debes adjuntar las 3 fotografías obligatorias de los documentos del vehículo.');
      return;
    }

    final anioVal = int.tryParse(_vehiculoAnioController.text.trim());
    if (anioVal == null || anioVal < 1970 || anioVal > DateTime.now().year + 2) {
      _showError('El año del vehículo no es válido (ej: 2020).');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final beneficiarioMap = {
        'tipoDocumento': _beneficiarioTipoDoc,
        'documento': _beneficiarioDocController.text.trim(),
        'nombreCompleto': _beneficiarioNombreController.text.trim(),
        'telefono': _beneficiarioTelefonoController.text.trim(),
        'correo': _beneficiarioCorreoController.text.trim().toLowerCase(),
      };

      Map<String, dynamic>? solicitanteMap;
      if (widget.isForThirdParty) {
        solicitanteMap = {
          'tipoDocumento': _solicitanteTipoDoc,
          'documento': _solicitanteDocController.text.trim(),
          'nombreCompleto': _solicitanteNombreController.text.trim(),
          'telefono': _solicitanteTelefonoController.text.trim(),
          'correo': _solicitanteCorreoController.text.trim().toLowerCase(),
        };
      }

      final payload = {
        'esParaTercero': widget.isForThirdParty,
        'beneficiario': beneficiarioMap,
        if (widget.isForThirdParty) 'solicitante': solicitanteMap,
        'origen': _origenController.text.trim(),
        'destino': _destinoController.text.trim(),
        'descripcion': _observacionesController.text.trim().isNotEmpty
            ? _observacionesController.text.trim()
            : 'Solicitud como invitado de ${_origenController.text.trim()} hacia ${_destinoController.text.trim()}',
        'fechaProgramada': _fechaProgramada.toIso8601String(),
        'tipoServicio': 'Transporte Ejecutivo',
        'prioridad': 'MEDIA',
        'vehiculo': {
          'marca': _vehiculoMarcaController.text.trim(),
          'modelo': _vehiculoModeloController.text.trim(),
          'anio': anioVal,
          'placa': _vehiculoPlacaController.text.trim().toUpperCase(),
          'color': _vehiculoColorController.text.trim(),
          'documentos': {
            'tarjetaPropiedad': _tarjetaUrl ?? '',
            'soat': _soatUrl ?? '',
            'tecnomecanica': _tecnoUrl ?? '',
          },
        },
      };

      // Se crea y registra en base de datos vinculando usuario, cliente y vehículo
      final response = await InvitadoService.crearSolicitud(payload);

      if (!mounted) return;

      // Convertir a modelo Solicitud para continuar exactamente en el flujo del cliente
      final solicitudCreada = Solicitud.fromJson(response);

      // Redirigir a SearchingDriverScreen para vivir la misma experiencia del cliente
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => SearchingDriverScreen(solicitud: solicitudCreada),
        ),
      );
    } catch (e) {
      if (mounted) {
        _showError('No fue posible registrar la solicitud: $e');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.dangerRed,
      ),
    );
  }

  // ─────────────────────────────────────────────
  // COMPONENTES DE DISEÑO
  // ─────────────────────────────────────────────
  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Color iconColor = AppColors.petrolBase,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      errorStyle: const TextStyle(
        color: AppColors.dangerRed,
        fontSize: 11.5,
        fontWeight: FontWeight.w600,
      ),
      prefixIcon: Icon(icon, color: iconColor, size: 20),
      suffixIcon: suffix,
      filled: true,
      fillColor: AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.petrolBase, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dangerRed, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  InputDecoration _dropdownDecoration({
    required String label,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13,
      ),
      errorStyle: const TextStyle(
        color: AppColors.dangerRed,
        fontSize: 10,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: AppColors.background,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.borderGray),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.petrolBase, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dangerRed, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.dangerRed, width: 2),
      ),
    );
  }

  Widget _sectionLabel(String text, IconData icon) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.petrolPale,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: AppColors.petrolBase),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12.5,
              color: AppColors.petrolBase,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Divider(
        height: 1,
        thickness: 1,
        color: AppColors.borderGray.withOpacity(0.9),
      ),
    );
  }

  Widget _buildDocStatusBadge({
    required bool isChecking,
    required bool? isFound,
    required String? message,
  }) {
    if (isChecking) {
      return Container(
        margin: const EdgeInsets.only(top: 8, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.petrolPale.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.petrolBase,
              ),
            ),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Consultando registro y vehículos por número de documento...',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.petrolDark,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (message == null || message.isEmpty) return const SizedBox.shrink();

    final isSuccess = isFound == true;
    final bgColor = isSuccess
        ? AppColors.successGreenSoft
        : const Color(0xFFF1F5F9);
    final textColor = isSuccess
        ? AppColors.successGreen
        : AppColors.slateGray;
    final iconData = isSuccess
        ? Icons.check_circle_rounded
        : Icons.info_outline_rounded;

    return Container(
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSuccess
              ? AppColors.successGreen.withOpacity(0.3)
              : AppColors.borderGray,
        ),
      ),
      child: Row(
        children: [
          Icon(iconData, color: textColor, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                color: textColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentUploadTile({
    required String title,
    required String docKey,
    required String? url,
    required Uint8List? bytes,
    required bool isUploading,
    bool hasError = false,
  }) {
    final hasImage = url != null && url.isNotEmpty;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: hasError
            ? AppColors.dangerRed.withOpacity(0.04)
            : (hasImage ? AppColors.petrolPale.withOpacity(0.2) : Colors.white),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: hasError
              ? AppColors.dangerRed
              : (hasImage ? AppColors.petrolBase : AppColors.borderGray),
          width: hasError || hasImage ? 1.5 : 1,
        ),
      ),
      child: Row(
        children: [
          // Thumbnail / Vista Previa
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 58,
              height: 58,
              color: AppColors.background,
              child: hasImage
                  ? (bytes != null
                      ? Image.memory(bytes, fit: BoxFit.cover)
                      : Image.network(
                          url,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => const Icon(
                            Icons.broken_image_outlined,
                            color: AppColors.slateGray,
                            size: 28,
                          ),
                        ))
                  : const Icon(
                      Icons.description_outlined,
                      color: AppColors.slateGray,
                      size: 28,
                    ),
            ),
          ),
          const SizedBox(width: 14),

          // Título y Estado
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                if (isUploading)
                  const Row(
                    children: [
                      SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accentOrange,
                        ),
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Subiendo a Cloudinary...',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else if (hasImage)
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: AppColors.successGreen,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Fotografía adjunta',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  )
                else
                  const Text(
                    'Obligatorio *',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: AppColors.dangerRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),

          // Botones de acción
          if (hasImage)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: 'Reemplazar',
                  icon: const Icon(
                    Icons.replay_rounded,
                    color: AppColors.petrolBase,
                    size: 22,
                  ),
                  onPressed: isUploading
                      ? null
                      : () => _showImageSourceDialog(docKey),
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    color: AppColors.dangerRed,
                    size: 22,
                  ),
                  onPressed: isUploading
                      ? null
                      : () {
                          setState(() {
                            if (docKey == 'tarjeta') {
                              _tarjetaBytes = null;
                              _tarjetaUrl = null;
                            } else if (docKey == 'soat') {
                              _soatBytes = null;
                              _soatUrl = null;
                            } else if (docKey == 'tecno') {
                              _tecnoBytes = null;
                              _tecnoUrl = null;
                            }
                          });
                        },
                ),
              ],
            )
          else
            ElevatedButton.icon(
              onPressed:
                  isUploading ? null : () => _showImageSourceDialog(docKey),
              icon: const Icon(Icons.add_a_photo_outlined, size: 16),
              label: const Text('Adjuntar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.petrolBase,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final modeTitle = widget.isForThirdParty
        ? 'Servicio para un Tercero'
        : 'Servicio a Nombre Propio';

    final modeSubtitle = widget.isForThirdParty
        ? 'Diligencia los datos del beneficiario y de quien realiza la solicitud.'
        : 'Diligencia tus datos personales y los de tu vehículo.';

    final tieneVehiculoAsociado = _vehiculoAutocargado ||
        _vehiculosEncontrados.isNotEmpty ||
        (_vehiculoSeleccionadoId != null && _vehiculoSeleccionadoId!.isNotEmpty);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppColors.petrolDark),
          tooltip: 'Regresar',
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          modeTitle,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.bold,
            color: AppColors.petrolDark,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          child: Form(
            key: _formKey,
            autovalidateMode: _autoValidateMode,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---------------------------------------------
                // HERO BANNER (ESTILO CLIENT HOME)
                // ---------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.petrolDark,
                        AppColors.petrolBase,
                        AppColors.petrolLight,
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withOpacity(0.3),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.25),
                          ),
                        ),
                        child: Icon(
                          widget.isForThirdParty
                              ? Icons.people_alt_rounded
                              : Icons.person_rounded,
                          color: AppColors.accentOrange,
                          size: 26,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              modeTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              modeSubtitle,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 12,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ---------------------------------------------
                // TARJETA PRINCIPAL DEL FORMULARIO
                // ---------------------------------------------
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderGray),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withOpacity(0.06),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // =============================================
                      // SECCIÓN 1: BENEFICIARIO / PROPIOS
                      // =============================================
                      _sectionLabel(
                        widget.isForThirdParty
                            ? '1. DATOS DEL BENEFICIARIO (QUIEN RECIBE EL SERVICIO)'
                            : '1. DATOS PERSONALES',
                        Icons.badge_outlined,
                      ),
                      const SizedBox(height: 16),

                      // Tipo y Número de Documento en fila
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 95,
                            child: DropdownButtonFormField<String>(
                              value: _beneficiarioTipoDoc,
                              isExpanded: true,
                              dropdownColor: Colors.white,
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                              decoration: _dropdownDecoration(
                                label: 'Tipo',
                              ),
                              items: _tiposDocumento.map((tipo) {
                                return DropdownMenuItem<String>(
                                  value: tipo,
                                  child: Text(tipo),
                                );
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) {
                                  setState(() => _beneficiarioTipoDoc = val);
                                  final doc = _beneficiarioDocController.text.trim();
                                  if (doc.length >= 5) {
                                    _consultarBeneficiario(doc);
                                  }
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _beneficiarioDocController,
                              keyboardType: TextInputType.text,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                LengthLimitingTextInputFormatter(15),
                              ],
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDecoration(
                                label: 'Número de Documento',
                                icon: Icons.numbers_rounded,
                                suffix: _beneficiarioChecking
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: Center(
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: AppColors.petrolBase,
                                          ),
                                        ),
                                      )
                                    : null,
                              ),
                              validator: (val) {
                                final doc = val?.trim() ?? '';
                                if (doc.isEmpty) {
                                  return 'Ingresa el número de documento';
                                }
                                if (doc.length < 5 || doc.length > 15) {
                                  return 'Debe tener entre 5 y 15 dígitos';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      // Badge de estado de búsqueda por documento
                      _buildDocStatusBadge(
                        isChecking: _beneficiarioChecking,
                        isFound: _beneficiarioFound,
                        message: _beneficiarioStatusMsg,
                      ),

                      const SizedBox(height: 14),

                      // Nombre Completo
                      TextFormField(
                        controller: _beneficiarioNombreController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Nombre Completo',
                          icon: Icons.person_outline_rounded,
                          iconColor: AppColors.accentOrange,
                        ),
                        validator: (val) {
                          final nombre = val?.trim() ?? '';
                          if (nombre.isEmpty) {
                            return 'Ingresa el nombre completo';
                          }
                          if (nombre.length < 3) {
                            return 'El nombre es muy corto (mín. 3 letras)';
                          }
                          if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombre)) {
                            return 'El nombre solo debe contener letras';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Teléfono
                      TextFormField(
                        controller: _beneficiarioTelefonoController,
                        keyboardType: TextInputType.phone,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(10),
                        ],
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Número de Teléfono (Celular)',
                          icon: Icons.phone_outlined,
                          iconColor: AppColors.accentOrange,
                        ),
                        validator: (val) {
                          final tel = val?.trim() ?? '';
                          if (tel.isEmpty) {
                            return 'Ingresa el número de teléfono';
                          }
                          if (!RegExp(r'^3\d{9}$').hasMatch(tel)) {
                            return 'Ingresa un celular válido de 10 dígitos (ej. 3001234567)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      // Correo Electrónico
                      TextFormField(
                        controller: _beneficiarioCorreoController,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Correo Electrónico',
                          icon: Icons.email_outlined,
                          iconColor: AppColors.accentOrange,
                        ),
                        validator: (val) {
                          final mail = val?.trim() ?? '';
                          if (mail.isEmpty) {
                            return 'Ingresa el correo electrónico';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(mail)) {
                            return 'Correo electrónico no válido';
                          }
                          return null;
                        },
                      ),

                      // =============================================
                      // SECCIÓN 2: SOLICITANTE (SI ES PARA TERCERO)
                      // =============================================
                      if (widget.isForThirdParty) ...[
                        _sectionDivider(),
                        _sectionLabel(
                          '2. DATOS DE QUIEN SOLICITA EL SERVICIO',
                          Icons.contact_phone_outlined,
                        ),
                        const SizedBox(height: 16),

                        // Tipo y Documento
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 95,
                              child: DropdownButtonFormField<String>(
                                value: _solicitanteTipoDoc,
                                isExpanded: true,
                                dropdownColor: Colors.white,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                                decoration: _dropdownDecoration(
                                  label: 'Tipo',
                                ),
                                items: _tiposDocumento.map((tipo) {
                                  return DropdownMenuItem<String>(
                                    value: tipo,
                                    child: Text(tipo),
                                  );
                                }).toList(),
                                onChanged: (val) {
                                  if (val != null) {
                                    setState(() => _solicitanteTipoDoc = val);
                                    final doc = _solicitanteDocController.text.trim();
                                    if (doc.length >= 5) {
                                      _consultarSolicitante(doc);
                                    }
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _solicitanteDocController,
                                keyboardType: TextInputType.text,
                                inputFormatters: [
                                  FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                  LengthLimitingTextInputFormatter(15),
                                ],
                                style: const TextStyle(color: AppColors.textPrimary),
                                decoration: _inputDecoration(
                                  label: 'Número de Documento',
                                  icon: Icons.numbers_rounded,
                                  suffix: _solicitanteChecking
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: Center(
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                              color: AppColors.petrolBase,
                                            ),
                                          ),
                                        )
                                      : null,
                                ),
                                validator: (val) {
                                  final doc = val?.trim() ?? '';
                                  if (doc.isEmpty) {
                                    return 'Ingresa el número de documento';
                                  }
                                  if (doc.length < 5 || doc.length > 15) {
                                    return 'Debe tener entre 5 y 15 dígitos';
                                  }
                                  return null;
                                },
                              ),
                            ),
                          ],
                        ),

                        _buildDocStatusBadge(
                          isChecking: _solicitanteChecking,
                          isFound: _solicitanteFound,
                          message: _solicitanteStatusMsg,
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _solicitanteNombreController,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            label: 'Nombre Completo del Solicitante',
                            icon: Icons.person_outline_rounded,
                            iconColor: AppColors.accentOrange,
                          ),
                          validator: (val) {
                            final nombre = val?.trim() ?? '';
                            if (nombre.isEmpty) {
                              return 'Ingresa el nombre del solicitante';
                            }
                            if (nombre.length < 3) {
                              return 'El nombre es muy corto (mín. 3 letras)';
                            }
                            if (!RegExp(r'^[a-zA-ZáéíóúÁÉÍÓÚñÑ\s]+$').hasMatch(nombre)) {
                              return 'El nombre solo debe contener letras';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _solicitanteTelefonoController,
                          keyboardType: TextInputType.phone,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            label: 'Teléfono del Solicitante (Celular)',
                            icon: Icons.phone_outlined,
                            iconColor: AppColors.accentOrange,
                          ),
                          validator: (val) {
                            final tel = val?.trim() ?? '';
                            if (tel.isEmpty) {
                              return 'Ingresa el teléfono del solicitante';
                            }
                            if (!RegExp(r'^3\d{9}$').hasMatch(tel)) {
                              return 'Ingresa un celular válido de 10 dígitos (ej. 3001234567)';
                            }
                            return null;
                          },
                        ),

                        const SizedBox(height: 14),

                        TextFormField(
                          controller: _solicitanteCorreoController,
                          keyboardType: TextInputType.emailAddress,
                          style: const TextStyle(color: AppColors.textPrimary),
                          decoration: _inputDecoration(
                            label: 'Correo del Solicitante',
                            icon: Icons.email_outlined,
                            iconColor: AppColors.accentOrange,
                          ),
                          validator: (val) {
                            final mail = val?.trim() ?? '';
                            if (mail.isEmpty) {
                              return 'Ingresa el correo del solicitante';
                            }
                            if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                                .hasMatch(mail)) {
                              return 'Correo no válido';
                            }
                            return null;
                          },
                        ),
                      ],

                      _sectionDivider(),

                      // =============================================
                      // SECCIÓN 3: DETALLES DEL VIAJE / SERVICIO
                      // =============================================
                      _sectionLabel(
                        widget.isForThirdParty
                            ? '3. INFORMACIÓN DEL SERVICIO'
                            : '2. INFORMACIÓN DEL SERVICIO',
                        Icons.alt_route_rounded,
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _origenController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Dirección o Punto de Origen',
                          icon: Icons.my_location_rounded,
                          iconColor: AppColors.slateGray,
                        ),
                        validator: (val) {
                          final orig = val?.trim() ?? '';
                          if (orig.isEmpty) {
                            return 'Ingresa la dirección de origen';
                          }
                          if (orig.length < 4) {
                            return 'Dirección de origen demasiado corta (mín. 4 caracteres)';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _destinoController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Dirección o Punto de Destino',
                          icon: Icons.location_on_rounded,
                          iconColor: AppColors.accentOrange,
                        ),
                        validator: (val) {
                          final dest = val?.trim() ?? '';
                          if (dest.isEmpty) {
                            return 'Ingresa la dirección de destino';
                          }
                          if (dest.length < 4) {
                            return 'Dirección de destino demasiado corta (mín. 4 caracteres)';
                          }
                          if (dest.toLowerCase() == _origenController.text.trim().toLowerCase()) {
                            return 'El destino no puede ser igual al origen';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _observacionesController,
                        maxLines: 2,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Descripción u Observaciones (opcional)',
                          icon: Icons.notes_rounded,
                          iconColor: AppColors.slateGray,
                        ),
                      ),

                      _sectionDivider(),

                      // =============================================
                      // SECCIÓN 4: DATOS DEL VEHÍCULO
                      // =============================================
                      _sectionLabel(
                        widget.isForThirdParty
                            ? '4. DATOS DEL VEHÍCULO'
                            : '3. DATOS DEL VEHÍCULO',
                        Icons.directions_car_rounded,
                      ),
                      const SizedBox(height: 10),

                      // Insignia de vehículo cargado automáticamente
                      if (_vehiculoAutocargado)
                        Container(
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.petrolPale.withOpacity(0.4),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.petrolBase.withOpacity(0.3),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.auto_awesome_rounded,
                                color: AppColors.petrolBase,
                                size: 16,
                              ),
                              const SizedBox(width: 8),
                              const Expanded(
                                child: Text(
                                  'Datos del vehículo cargados automáticamente desde el registro.',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.petrolDark,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _vehiculoMarcaController.clear();
                                    _vehiculoModeloController.clear();
                                    _vehiculoPlacaController.clear();
                                    _vehiculoAnioController.clear();
                                    _vehiculoColorController.clear();
                                    _tarjetaUrl = null;
                                    _tarjetaBytes = null;
                                    _soatUrl = null;
                                    _soatBytes = null;
                                    _tecnoUrl = null;
                                    _tecnoBytes = null;
                                    _vehiculoAutocargado = false;
                                    _vehiculosEncontrados = [];
                                    _vehiculoSeleccionadoId = null;
                                  });
                                },
                                child: const Text(
                                  'Limpiar',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: AppColors.accentOrangeDark,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Selector de vehículos si el usuario tiene varios registrados
                      if (_vehiculosEncontrados.length > 1) ...[
                        const Text(
                          'Vehículos registrados disponibles:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _vehiculosEncontrados.map((v) {
                              final placa = v['placa']?.toString() ?? '';
                              final marcaModelo =
                                  '${v['marca'] ?? ''} ${v['modelo'] ?? ''}'.trim();
                              final vId = v['id']?.toString() ?? v['_id']?.toString();
                              final isSelected = _vehiculoSeleccionadoId == vId;

                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  selected: isSelected,
                                  label: Text('$placa ($marcaModelo)'),
                                  labelStyle: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : AppColors.petrolDark,
                                  ),
                                  selectedColor: AppColors.petrolBase,
                                  backgroundColor: AppColors.background,
                                  side: BorderSide(
                                    color: isSelected
                                        ? AppColors.petrolBase
                                        : AppColors.borderGray,
                                  ),
                                  onSelected: (selected) {
                                    if (selected) {
                                      setState(() {
                                        _aplicarVehiculo(v);
                                      });
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehiculoMarcaController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDecoration(
                                label: 'Marca (ej: Mazda)',
                                icon: Icons.car_rental_rounded,
                              ),
                              validator: (val) {
                                final marca = val?.trim() ?? '';
                                if (marca.isEmpty) return 'Ingresa la marca';
                                if (marca.length < 2) return 'Marca muy corta';
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _vehiculoModeloController,
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDecoration(
                                label: 'Modelo (ej: 3 Touring)',
                                icon: Icons.model_training_rounded,
                              ),
                              validator: (val) {
                                final modelo = val?.trim() ?? '';
                                if (modelo.isEmpty) return 'Ingresa el modelo';
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: _vehiculoPlacaController,
                              textCapitalization: TextCapitalization.characters,
                              inputFormatters: [
                                FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z0-9]')),
                                LengthLimitingTextInputFormatter(6),
                              ],
                              style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                              decoration: _inputDecoration(
                                label: 'Placa (ej: abc123)',
                                icon: Icons.credit_card_rounded,
                              ),
                              validator: (val) {
                                final placa = val?.trim() ?? '';
                                if (placa.isEmpty) return 'Ingresa la placa del vehículo';
                                final regex = RegExp(r'^[a-zA-Z]{3}[0-9]{3}$');
                                if (!regex.hasMatch(placa)) {
                                  return 'Debe tener 3 letras y 3 números (ej. abc123)';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextFormField(
                              controller: _vehiculoAnioController,
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(4),
                              ],
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: _inputDecoration(
                                label: 'Año (ej: 2022)',
                                icon: Icons.calendar_today_rounded,
                              ),
                              validator: (val) {
                                final anioStr = val?.trim() ?? '';
                                if (anioStr.isEmpty) return 'Ingresa el año';
                                final anio = int.tryParse(anioStr);
                                final maxAnio = DateTime.now().year + 1;
                                if (anio == null || anio < 1970 || anio > maxAnio) {
                                  return 'Año inválido (1970 - $maxAnio)';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 14),

                      TextFormField(
                        controller: _vehiculoColorController,
                        style: const TextStyle(color: AppColors.textPrimary),
                        decoration: _inputDecoration(
                          label: 'Color (ej: Gris Grafito)',
                          icon: Icons.palette_outlined,
                        ),
                        validator: (val) {
                          final color = val?.trim() ?? '';
                          if (color.isEmpty) return 'Ingresa el color';
                          if (color.length < 3) return 'Color muy corto';
                          return null;
                        },
                      ),

                      // =============================================
                      // SECCIÓN 5: DOCUMENTACIÓN DEL VEHÍCULO
                      // Solo visible si NO tiene vehículo asociado existente
                      // =============================================
                      if (!tieneVehiculoAsociado) ...[
                        _sectionDivider(),
                        _sectionLabel(
                          widget.isForThirdParty
                              ? '5. DOCUMENTACIÓN DEL VEHÍCULO (3 FOTOS)'
                              : '4. DOCUMENTACIÓN DEL VEHÍCULO (3 FOTOS)',
                          Icons.folder_shared_outlined,
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Adjunta fotografías nítidas y legibles de los documentos de tu vehículo:',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Tarjeta de Propiedad
                        _buildDocumentUploadTile(
                          title: '1. Tarjeta de Propiedad',
                          docKey: 'tarjeta',
                          url: _tarjetaUrl,
                          bytes: _tarjetaBytes,
                          isUploading: _tarjetaUploading,
                          hasError: _tarjetaMissing && (_tarjetaUrl == null || _tarjetaUrl!.isEmpty),
                        ),

                        // SOAT
                        _buildDocumentUploadTile(
                          title: '2. SOAT Vigente',
                          docKey: 'soat',
                          url: _soatUrl,
                          bytes: _soatBytes,
                          isUploading: _soatUploading,
                          hasError: _soatMissing && (_soatUrl == null || _soatUrl!.isEmpty),
                        ),

                        // Revisión Técnico-Mecánica
                        _buildDocumentUploadTile(
                          title: '3. Revisión Técnico-Mecánica',
                          docKey: 'tecno',
                          url: _tecnoUrl,
                          bytes: _tecnoBytes,
                          isUploading: _tecnoUploading,
                          hasError: _tecnoMissing && (_tecnoUrl == null || _tecnoUrl!.isEmpty),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Botón Enviar Solicitud
                      SizedBox(
                        width: double.infinity,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            gradient: const LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                AppColors.accentOrange,
                                AppColors.accentOrangeDark,
                              ],
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accentOrange.withOpacity(0.35),
                                blurRadius: 16,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: ElevatedButton(
                            onPressed: (_isSubmitting ||
                                    _tarjetaUploading ||
                                    _soatUploading ||
                                    _tecnoUploading)
                                ? null
                                : _submitRequest,
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
                            child: _isSubmitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.2,
                                    ),
                                  )
                                : const Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.check_circle_outline_rounded,
                                        size: 22,
                                        color: Colors.white,
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        'Confirmar y Enviar Solicitud',
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
              ],
            ),
          ),
        ),
      ),
    );
  }
}
