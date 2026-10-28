import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../models/novedad.dart';
import '../services/auth_service.dart';
import '../services/cloudinary_service.dart';
import '../services/http_client.dart';
import '../services/novedad_service.dart';
import 'xfile_image_widget.dart';

/// Función auxiliar para desplegar el modal de reporte de novedades directamente
/// sobre la pantalla de viaje o navegación sin perder el contexto.
/// Retorna un mapa con el resultado: {'success': bool, 'cambioRuta': bool, 'motivo': String, ...}
Future<Map<String, dynamic>?> showReportNoveltyModal(
  BuildContext context, {
  String? solicitudId,
  String? conductorId,
  String? usuarioId,
}) {
  return showModalBottomSheet<Map<String, dynamic>>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) => ReportNoveltyModal(
      solicitudId: solicitudId,
      conductorId: conductorId,
      usuarioId: usuarioId,
    ),
  );
}

class ReportNoveltyModal extends StatefulWidget {
  final String? solicitudId;
  final String? conductorId;
  final String? usuarioId;

  const ReportNoveltyModal({
    super.key,
    this.solicitudId,
    this.conductorId,
    this.usuarioId,
  });

  @override
  State<ReportNoveltyModal> createState() => _ReportNoveltyModalState();
}

class _ReportNoveltyModalState extends State<ReportNoveltyModal> {
  final NovedadService _novedadService = NovedadService();
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _detailsController = TextEditingController();

  // Novedades normalizadas (incidentes puros)
  String _selectedKey = 'choque';
  bool _cambiarRuta = false; // Toggle para desviar o recalcular ruta
  XFile? _photoFile;
  bool _isSubmitting = false;

  final List<Map<String, dynamic>> _noveltyOptions = [
    {
      'key': 'choque',
      'label': 'Choque / Accidente',
      'icon': Icons.car_crash_rounded,
      'tipo': 'VIAL',
      'severidad': 'CRITICA',
      'titulo': 'Choque o colisión en la ruta',
      'defaultDesc': 'Se presentó una colisión o choque vehicular durante el trayecto.',
    },
    {
      'key': 'salud',
      'label': 'Incidente de salud',
      'icon': Icons.medical_services_rounded,
      'tipo': 'SALUD',
      'severidad': 'CRITICA',
      'titulo': 'Incidente de salud o emergencia',
      'defaultDesc': 'Se presentó una eventualidad o emergencia médica que requiere atención.',
    },
    {
      'key': 'trafico',
      'label': 'Tráfico pesado',
      'icon': Icons.traffic_rounded,
      'tipo': 'VIAL',
      'severidad': 'MEDIA',
      'titulo': 'Tráfico pesado o congestión',
      'defaultDesc': 'Tráfico pesado y congestión vial que genera demoras en el servicio.',
    },
    {
      'key': 'mecanica',
      'label': 'Problemas mecánicos',
      'icon': Icons.build_rounded,
      'tipo': 'MECANICA',
      'severidad': 'ALTA',
      'titulo': 'Falla o problema mecánico',
      'defaultDesc': 'El vehículo presenta fallas o averías mecánicas imprevistas.',
    },
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _takePhotoWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );
      if (photo != null && mounted) {
        setState(() => _photoFile = photo);
      }
    } catch (e) {
      debugPrint('Error al abrir la cámara directa: $e');
      _showSourcePicker();
    }
  }

  void _showSourcePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFFE8821E)),
              title: const Text('Tomar foto con cámara'),
              onTap: () async {
                Navigator.pop(ctx);
                final photo = await _picker.pickImage(
                  source: ImageSource.camera,
                  imageQuality: 85,
                );
                if (photo != null && mounted) {
                  setState(() => _photoFile = photo);
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF12566B)),
              title: const Text('Elegir de galería'),
              onTap: () async {
                Navigator.pop(ctx);
                final photo = await _picker.pickImage(
                  source: ImageSource.gallery,
                  imageQuality: 85,
                );
                if (photo != null && mounted) {
                  setState(() => _photoFile = photo);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    final rawUsuarioId = widget.usuarioId?.trim() ??
        (await AuthService.obtenerUsuarioId())?.trim();

    bool isValidObjectId(String? id) =>
        id != null && RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(id.trim());

    if (rawUsuarioId == null || !isValidObjectId(rawUsuarioId)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: No se encontró la sesión del usuario.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final selectedConfig = _noveltyOptions.firstWhere(
      (opt) => opt['key'] == _selectedKey,
      orElse: () => _noveltyOptions.first,
    );

    final userNotes = _detailsController.text.trim();
    String finalDescription = userNotes.isNotEmpty
        ? userNotes
        : selectedConfig['defaultDesc'] as String;

    String finalTitle = selectedConfig['titulo'] as String;
    if (_cambiarRuta) {
      finalTitle = '$finalTitle (Con cambio de ruta)';
      finalDescription =
          '$finalDescription\n[AVISO DE DESVÍO]: El conductor toma una ruta alternativa debido a este incidente.';
    }

    final solId = isValidObjectId(widget.solicitudId)
        ? widget.solicitudId!.trim()
        : null;
    final condId = isValidObjectId(widget.conductorId)
        ? widget.conductorId!.trim()
        : null;

    setState(() => _isSubmitting = true);

    try {
      String? fotoEvidenciaUrl;
      if (_photoFile != null) {
        try {
          fotoEvidenciaUrl = await CloudinaryService.subirImagen(
            _photoFile!,
            folder: 'novedades',
          );
        } catch (uploadErr) {
          debugPrint('Aviso al subir imagen a Cloudinary: $uploadErr');
        }
      }

      await _novedadService.crearNovedad(
        Novedad(
          titulo: finalTitle,
          descripcion: finalDescription,
          tipo: selectedConfig['tipo'] as String,
          severidad: selectedConfig['severidad'] as String,
          solicitudId: solId,
          conductorId: condId,
          usuarioRegistroId: rawUsuarioId,
          evidenciaUrl: fotoEvidenciaUrl,
          estadoNovedad: 'PENDIENTE',
        ),
      );

      if (!mounted) return;

      Navigator.of(context).pop<Map<String, dynamic>>({
        'success': true,
        'cambioRuta': _cambiarRuta,
        'motivo': selectedConfig['label'] as String,
        'novedadKey': _selectedKey,
      });

      final mensajeExito = _cambiarRuta
          ? 'Novedad reportada. Se activó el cambio de ruta y se notificó al cliente.'
          : 'Novedad reportada al centro de control exitosamente.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 10),
              Expanded(
                child: Text(mensajeExito),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF12566B),
          duration: const Duration(seconds: 4),
        ),
      );
    } on ApiException catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(err.message),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('No se pudo enviar el reporte: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x33000000),
            blurRadius: 20,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + bottomInset),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tirador superior (drag handle)
            Center(
              child: Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Encabezado
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reportar Novedad',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0B3B4A),
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Informa cualquier eventualidad en el servicio',
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.grey),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Opciones de novedad normalizadas (Incidentes)
            const Text(
              'TIPO DE INCIDENTE',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF5C6B73),
              ),
            ),
            const SizedBox(height: 10),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _noveltyOptions.map((opt) {
                final isSelected = _selectedKey == opt['key'];
                return ChoiceChip(
                  avatar: Icon(
                    opt['icon'] as IconData,
                    size: 17,
                    color: isSelected ? Colors.white : const Color(0xFF12566B),
                  ),
                  label: Text(opt['label'] as String),
                  selected: isSelected,
                  selectedColor: const Color(0xFFE8821E),
                  backgroundColor: const Color(0xFFF2F5F6),
                  labelStyle: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF16262D),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(
                      color: isSelected ? const Color(0xFFE8821E) : const Color(0xFFE1E7E9),
                      width: isSelected ? 1.5 : 1.0,
                    ),
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _selectedKey = opt['key'] as String);
                    }
                  },
                );
              }).toList(),
            ),

            const SizedBox(height: 16),

            // TARJETA INTERACTIVA DE CAMBIO / DESVÍO DE RUTA
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _cambiarRuta ? const Color(0xFFEBF7F2) : const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _cambiarRuta ? const Color(0xFF2E7D5B) : const Color(0xFFE5E7EB),
                  width: _cambiarRuta ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: _cambiarRuta ? const Color(0xFF2E7D5B) : const Color(0xFFE1E7E9),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.alt_route_rounded,
                      color: _cambiarRuta ? Colors.white : const Color(0xFF5C6B73),
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
                            fontSize: 13.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0B3B4A),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _cambiarRuta
                              ? 'Se recalculará la ruta en tu mapa y se notificará el desvío al cliente.'
                              : 'Activa si este incidente obliga a tomar un desvío o ruta alternativa.',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: _cambiarRuta ? const Color(0xFF1B5E20) : Colors.grey[600],
                            fontWeight: _cambiarRuta ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _cambiarRuta,
                    activeTrackColor: const Color(0xFF2E7D5B),
                    activeColor: const Color(0xFF2E7D5B),
                    onChanged: (val) {
                      setState(() => _cambiarRuta = val);
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // Campo de notas opcional
            const Text(
              'DETALLES (OPCIONAL)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF5C6B73),
              ),
            ),
            const SizedBox(height: 8),

            TextField(
              controller: _detailsController,
              maxLines: 2,
              decoration: InputDecoration(
                hintText: _cambiarRuta
                    ? 'Ej: Vía cerrada por este incidente, tomando calle alterna...'
                    : 'Detalles adicionales sobre lo sucedido...',
                hintStyle: TextStyle(color: Colors.grey[400], fontSize: 13.5),
                filled: true,
                fillColor: const Color(0xFFF9FAFB),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFFE8821E), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Evidencia fotográfica (compacta)
            const Text(
              'EVIDENCIA FOTOGRÁFICA (OPCIONAL)',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: Color(0xFF5C6B73),
              ),
            ),
            const SizedBox(height: 8),

            if (_photoFile != null) ...[
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F5F6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFE1E7E9)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: XFileImageWidget(
                        file: _photoFile!,
                        width: 58,
                        height: 58,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Foto adjunta',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _photoFile!.name,
                            style: const TextStyle(fontSize: 11, color: Colors.grey),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded, color: Color(0xFF12566B)),
                      tooltip: 'Cambiar foto',
                      onPressed: _takePhotoWithCamera,
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
                      tooltip: 'Eliminar foto',
                      onPressed: () => setState(() => _photoFile = null),
                    ),
                  ],
                ),
              ),
            ] else ...[
              InkWell(
                onTap: _takePhotoWithCamera,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFFE5E7EB),
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt_rounded, color: Color(0xFFE8821E), size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Tomar foto con la cámara',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0B3B4A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            const SizedBox(height: 24),

            // Botón de enviar reporte
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _cambiarRuta
                      ? const Color(0xFF2E7D5B)
                      : const Color(0xFFE8821E),
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: const Color(0xFFE0E0E0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
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
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _cambiarRuta ? Icons.alt_route_rounded : Icons.send_rounded,
                            size: 19,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _cambiarRuta
                                ? 'Reportar Novedad y Cambiar Ruta'
                                : 'Enviar Reporte',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
