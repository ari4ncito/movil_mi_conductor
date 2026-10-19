import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/solicitud.dart';
import '../../../services/servicio_service.dart';
import '../../../services/solicitud_service.dart';
import '../../../widgets/xfile_image_widget.dart';
import 'driver_start_verification_screen.dart';

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
  static const Color successGreen = Color(0xFF2E7D32);
}

class DriverVehicleDeliveryVerification extends StatefulWidget {
  final Solicitud? solicitud;

  const DriverVehicleDeliveryVerification({super.key, this.solicitud});

  @override
  State<DriverVehicleDeliveryVerification> createState() =>
      _DriverVehicleDeliveryVerificationState();
}

class _DriverVehicleDeliveryVerificationState
    extends State<DriverVehicleDeliveryVerification> {
  final Map<String, XFile?> _photos = {
    'front': null,
    'back': null,
    'left': null,
    'right': null,
  };

  final ImagePicker _picker = ImagePicker();
  bool _isFinalizing = false;
  final ServicioService _servicioService = ServicioService();
  final SolicitudService _solicitudService = SolicitudService();

  bool get _allPhotosTaken =>
      _photos['front'] != null &&
      _photos['back'] != null &&
      _photos['left'] != null &&
      _photos['right'] != null;

  int get _photosCount => _photos.values.where((p) => p != null).length;

  /// Abre la cámara del dispositivo móvil directamente
  Future<void> _capturarFotoConCamara(String key) async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _photos[key] = photo;
        });
      }
    } catch (e) {
      if (!mounted) return;
      _mostrarDialogoOpcionesFoto(key);
    }
  }

  void _mostrarDialogoOpcionesFoto(String key) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Seleccionar Foto de Entrega',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentOrange.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt, color: AppColors.accentOrange),
                ),
                title: const Text('Tomar foto con Cámara', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Abre la cámara del celular'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
                    if (photo != null) setState(() => _photos[key] = photo);
                  } catch (e) {
                    _mostrarError('Error con la cámara: $e');
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.petrolBase.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library, color: AppColors.petrolBase),
                ),
                title: const Text('Elegir de Galería', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Seleccionar una imagen ya guardada'),
                onTap: () async {
                  Navigator.pop(ctx);
                  try {
                    final photo = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
                    if (photo != null) setState(() => _photos[key] = photo);
                  } catch (e) {
                    _mostrarError('Error con la galería: $e');
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red),
    );
  }

  void _removePhoto(String key) {
    setState(() {
      _photos[key] = null;
    });
  }

  Future<void> _finalizarServicioConEvidencias() async {
    if (!_allPhotosTaken) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Debes tomar las 4 fotografías de entrega del vehículo para poder finalizar el servicio.',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isFinalizing = true;
    });

    try {
      final solicitudId = widget.solicitud?.id;
      Solicitud? solicitudActualizada = widget.solicitud;
      if (solicitudId != null && solicitudId.isNotEmpty) {
        // 1. Intentar subir las 4 imágenes de entrega a Cloudinary
        try {
          final servicio = await _servicioService.obtenerPorSolicitud(solicitudId);
          final servicioId = (servicio?['_id'] ?? servicio?['id'])?.toString();

          final archivos = _photos.values.whereType<XFile>().toList();
          if (archivos.isNotEmpty) {
            await _servicioService.subirImagenes(
              servicioId: servicioId ?? '',
              archivos: archivos,
              tipo: 'entrega',
            );
          }
        } catch (imgError) {
          debugPrint('Aviso al subir imágenes de entrega a Cloudinary: $imgError');
        }

        // 2. Completar la solicitud en el backend (cambia estado a COMPLETADO)
        solicitudActualizada = await _solicitudService.completar(solicitudId);
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Evidencias de entrega registradas y servicio completado.'),
          backgroundColor: AppColors.successGreen,
        ),
      );

      // 3. Navegar a la pantalla de resumen / calificación
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => DriverStartVerificationScreen(
            solicitud: solicitudActualizada,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al finalizar el servicio: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isFinalizing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final vehiculoData = widget.solicitud?.vehiculoData ?? {};
    final marca = vehiculoData['marca'] ?? 'Vehículo';
    final modelo = vehiculoData['modelo'] ?? '';
    final placa = vehiculoData['placa'] ?? 'Sin placa';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: AppColors.textPrimary, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Verificación de Entrega',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card de vehículo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.borderGray),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppColors.accentOrange.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.verified_outlined,
                        color: AppColors.accentOrange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '$marca $modelo'.trim(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Placa: $placa',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.slateGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _allPhotosTaken
                            ? const Color(0xFFE8F9F0)
                            : const Color(0xFFFFF4E5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$_photosCount / 4 fotos',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: _allPhotosTaken
                              ? AppColors.successGreen
                              : AppColors.accentOrange,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Aviso de regla del negocio
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _allPhotosTaken
                      ? const Color(0xFFE8F9F0)
                      : const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _allPhotosTaken
                        ? AppColors.successGreen.withValues(alpha: 0.3)
                        : Colors.orange.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      _allPhotosTaken
                          ? Icons.check_circle_outline
                          : Icons.camera_alt_outlined,
                      color: _allPhotosTaken
                          ? AppColors.successGreen
                          : Colors.orange[800],
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _allPhotosTaken
                            ? '¡Todo listo! Las 4 fotografías de entrega han sido capturadas. Puedes finalizar el servicio.'
                            : 'Toma las 4 fotos exteriores con la cámara (Frontal, Trasera y ambos Laterales) para certificar el estado en que entregas el vehículo antes de poder finalizar el servicio.',
                        style: TextStyle(
                          fontSize: 13,
                          color: _allPhotosTaken
                              ? AppColors.successGreen
                              : Colors.orange[900],
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Título de la sección
              const Text(
                'Fotos de Entrega del Vehículo',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Toca cada recuadro para abrir la cámara del celular y tomar la foto de entrega.',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGray,
                ),
              ),

              const SizedBox(height: 16),

              // Cuadrícula 2x2 para las fotos de entrega
              GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.0,
                children: [
                  _buildPhotoSlot(
                    label: 'Foto Frontal',
                    subtitle: 'Exterior delantero',
                    keyName: 'front',
                  ),
                  _buildPhotoSlot(
                    label: 'Foto Trasera',
                    subtitle: 'Exterior posterior',
                    keyName: 'back',
                  ),
                  _buildPhotoSlot(
                    label: 'Lateral Izquierdo',
                    subtitle: 'Costado ext. conductor',
                    keyName: 'left',
                  ),
                  _buildPhotoSlot(
                    label: 'Lateral Derecho',
                    subtitle: 'Costado ext. copiloto',
                    keyName: 'right',
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Botón Finalizar Servicio (Condicionado)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: (_allPhotosTaken && !_isFinalizing)
                      ? _finalizarServicioConEvidencias
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.accentOrange,
                    foregroundColor: AppColors.white,
                    disabledBackgroundColor: Colors.grey[300],
                    disabledForegroundColor: Colors.grey[500],
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                    elevation: _allPhotosTaken ? 4 : 0,
                  ),
                  child: _isFinalizing
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Subiendo fotos a Cloudinary y finalizando...',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _allPhotosTaken
                                  ? 'Finalizar Servicio'
                                  : 'Tomar 4 fotos para finalizar',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_allPhotosTaken) ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.check_circle_outline, size: 20),
                            ],
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoSlot({
    required String label,
    required String subtitle,
    required String keyName,
  }) {
    final file = _photos[keyName];
    final hasPhoto = file != null;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasPhoto ? AppColors.accentOrange : AppColors.borderGray,
          width: hasPhoto ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (hasPhoto) ...[
              // Imagen seleccionada
              _buildImageWidget(file),
              // Gradiente protector
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
              // Label inferior
              Positioned(
                bottom: 8,
                left: 8,
                right: 8,
                child: Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              // Botón eliminar / cambiar
              Positioned(
                top: 6,
                right: 6,
                child: GestureDetector(
                  onTap: () => _removePhoto(keyName),
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
              // Indicador check
              Positioned(
                top: 6,
                left: 6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check,
                    color: Colors.white,
                    size: 14,
                  ),
                ),
              ),
            ] else ...[
              // Estado vacío: botón para capturar con cámara
              InkWell(
                onTap: () => _capturarFotoConCamara(keyName),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.accentOrange.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: AppColors.accentOrange,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slateGray,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildImageWidget(XFile file) {
    return XFileImageWidget(
      file: file,
      fit: BoxFit.cover,
    );
  }
}
