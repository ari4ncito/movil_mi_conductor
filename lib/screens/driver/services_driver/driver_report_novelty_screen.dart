import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../models/novedad.dart';
import '../../../services/auth_service.dart';
import '../../../services/cloudinary_service.dart';
import '../../../services/http_client.dart';
import '../../../services/novedad_service.dart';
import '../../../widgets/xfile_image_widget.dart';

class DriverReportNoveltyScreen extends StatefulWidget {
  final String? solicitudId;
  final String? conductorId;
  final String? usuarioId;
  final NovedadService? novedadService;

  const DriverReportNoveltyScreen({
    super.key,
    this.solicitudId,
    this.conductorId,
    this.usuarioId,
    this.novedadService,
  });

  @override
  State<DriverReportNoveltyScreen> createState() =>
      _DriverReportNoveltyScreenState();
}

class _DriverReportNoveltyScreenState extends State<DriverReportNoveltyScreen> {
  String? _selectedNovelty;
  final TextEditingController _detailsController = TextEditingController();
  XFile? _photoFile;
  final ImagePicker _picker = ImagePicker();
  bool _isCreating = false;
  bool _cambiarRuta = false;
  late final NovedadService _novedadService =
      widget.novedadService ?? NovedadService();

  final List<String> _novelties = [
    'Choque / Accidente',
    'Incidente de salud',
    'Tráfico pesado',
    'Problemas mecánicos',
  ];

  static const Map<String, Map<String, String>> _noveltyConfig = {
    'Choque / Accidente': {
      'tipo': 'VIAL',
      'severidad': 'CRITICA',
      'titulo': 'Choque vehicular en la ruta',
      'defaultDesc': 'Se presentó una colisión o choque vehicular durante el trayecto.',
    },
    'Incidente de salud': {
      'tipo': 'SALUD',
      'severidad': 'CRITICA',
      'titulo': 'Incidente de salud o emergencia',
      'defaultDesc': 'Se presentó una eventualidad o emergencia médica que requiere atención.',
    },
    'Tráfico pesado': {
      'tipo': 'VIAL',
      'severidad': 'MEDIA',
      'titulo': 'Tráfico pesado o congestión',
      'defaultDesc': 'Tráfico pesado y congestión vial que genera demoras en el servicio.',
    },
    'Problemas mecánicos': {
      'tipo': 'MECANICA',
      'severidad': 'ALTA',
      'titulo': 'Falla o problema mecánico',
      'defaultDesc': 'El vehículo presenta fallas o averías mecánicas imprevistas.',
    },
    'Cambio de ruta': {
      'tipo': 'VIAL',
      'severidad': 'MEDIA',
      'titulo': 'Aviso de cambio de ruta o desvío',
      'defaultDesc': 'El conductor toma un desvío o ruta alternativa por imprevistos en la vía.',
    },
  };

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (photo != null) {
        setState(() {
          _photoFile = photo;
        });
      }
    } catch (e) {
      debugPrint('No se pudo acceder a la cámara directa: $e');
      // Intentar galería como respaldo en caso de emulador o permisos
      try {
        final XFile? galleryPhoto = await _picker.pickImage(
          source: ImageSource.gallery,
          imageQuality: 85,
        );
        if (galleryPhoto != null) {
          setState(() {
            _photoFile = galleryPhoto;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _createNovedad() async {
    final rawUsuarioId = widget.usuarioId?.trim() ??
        (await AuthService.obtenerUsuarioId())?.trim();
    if (!mounted) return;

    bool isValidObjectId(String? id) =>
        id != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id.trim());

    if (rawUsuarioId == null || !isValidObjectId(rawUsuarioId)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No se puede crear la novedad: falta el ID del usuario válido.',
          ),
        ),
      );
      return;
    }

    final usuarioId = rawUsuarioId.trim();
    final solId = isValidObjectId(widget.solicitudId)
        ? widget.solicitudId!.trim()
        : null;
    final condId = isValidObjectId(widget.conductorId)
        ? widget.conductorId!.trim()
        : null;

    final config = _noveltyConfig[_selectedNovelty] ?? {
      'tipo': 'OTROS',
      'severidad': 'BAJA',
      'titulo': 'Novedad general en el servicio',
      'defaultDesc': 'Reporte de novedad imprevista por parte del conductor.',
    };

    final userText = _detailsController.text.trim();
    String finalDesc;
    if (userText.isEmpty) {
      finalDesc = config['defaultDesc']!;
    } else if (userText.length < 10) {
      finalDesc = '${config['defaultDesc']!} - Detalle: $userText';
    } else {
      finalDesc = userText;
    }

    if (finalDesc.length > 1000) {
      finalDesc = finalDesc.substring(0, 1000);
    }

    String titulo = config['titulo']!;
    if (_cambiarRuta) {
      titulo = '$titulo (Con cambio de ruta)';
      finalDesc = '$finalDesc\n[AVISO DE DESVÍO]: El conductor toma una ruta alternativa debido a este incidente.';
    }
    final tipo = config['tipo']!;
    final severidad = config['severidad']!;

    setState(() => _isCreating = true);
    try {
      String? fotoEvidenciaUrl;
      if (_photoFile != null) {
        try {
          fotoEvidenciaUrl = await CloudinaryService.subirImagen(
            _photoFile!,
            folder: 'novedades',
          );
        } catch (uploadErr) {
          debugPrint('Aviso al subir imagen de novedad a Cloudinary: $uploadErr');
        }
      }

      await _novedadService.crearNovedad(
        Novedad(
          titulo: titulo,
          descripcion: finalDesc,
          tipo: tipo,
          severidad: severidad,
          solicitudId: solId,
          conductorId: condId,
          usuarioRegistroId: usuarioId,
          evidenciaUrl: fotoEvidenciaUrl,
          estadoNovedad: 'PENDIENTE',
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Novedad reportada exitosamente.')),
      );
      Navigator.pop(context, {'cambioRuta': _cambiarRuta, 'motivo': _selectedNovelty});
    } on ApiException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reportar la novedad: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F8),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_rounded,
                        color: Colors.black,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Reportar Novedad',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              const Text(
                'Tipo de Novedad',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Novelties list
              ..._novelties.map((novelty) {
                final isSelected = _selectedNovelty == novelty;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedNovelty = novelty;
                      });
                    },
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFFF8A00)
                              : Colors.grey[300]!,
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              novelty,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w500,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFFF8A00)
                                  : Colors.white,
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFFF8A00)
                                    : Colors.grey[300]!,
                                width: 2,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: isSelected
                                ? const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 18,
                                  )
                                : null,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 8),

              // Tarjeta interactiva de cambio de ruta
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: _cambiarRuta ? const Color(0xFFEBF7F2) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _cambiarRuta ? const Color(0xFF2E7D5B) : Colors.grey[300]!,
                    width: _cambiarRuta ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: _cambiarRuta ? const Color(0xFF2E7D5B) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.alt_route_rounded,
                        color: _cambiarRuta ? Colors.white : Colors.grey[700],
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '¿Requiere cambio de ruta?',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _cambiarRuta
                                ? 'Se avisará al cliente y se trazará una ruta alterna.'
                                : 'Activa si este incidente obliga a tomar un desvío.',
                            style: TextStyle(
                              fontSize: 12,
                              color: _cambiarRuta ? const Color(0xFF1B5E20) : Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: _cambiarRuta,
                      activeColor: const Color(0xFF2E7D5B),
                      onChanged: (val) {
                        setState(() => _cambiarRuta = val);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Details
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Detalles Adicionales',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _detailsController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'Describe la novedad...',
                        hintStyle: TextStyle(color: Colors.grey[500]),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: const Color(0xFFF8F9FA),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Evidence photo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Evidencia Fotográfica',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_photoFile != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: XFileImageWidget(
                              file: _photoFile!,
                              width: double.infinity,
                              height: 180,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: () {
                                setState(() {
                                  _photoFile = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _takePhoto,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.camera_alt,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Cambiar foto',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      GestureDetector(
                        onTap: _takePhoto,
                        child: Container(
                          width: double.infinity,
                          height: 140,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF8F9FA),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color(0xFFFF8A00),
                              width: 1.5,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.camera_alt_rounded,
                                color: Color(0xFFFF8A00),
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tomar Foto con la Cámara',
                                style: TextStyle(
                                  color: Color(0xFFFF8A00),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Toca para abrir la cámara del dispositivo',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Report button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _selectedNovelty != null && !_isCreating
                      ? _createNovedad
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF8A00),
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: _isCreating
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Reportar Novedad',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
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
}
