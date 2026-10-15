import 'package:flutter/material.dart';
import '../../../models/solicitud.dart';
import '../client_section.dart';

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
  static const Color successGreen = Color(0xFF2E7D32);
}

class ClientArrivedDestinationScreen extends StatefulWidget {
  final Solicitud? solicitud;

  const ClientArrivedDestinationScreen({super.key, this.solicitud});

  @override
  State<ClientArrivedDestinationScreen> createState() =>
      _ClientArrivedDestinationScreenState();
}

class _ClientArrivedDestinationScreenState
    extends State<ClientArrivedDestinationScreen> {
  int _rating = 5; // Calificación por defecto 5 estrellas
  final TextEditingController _comentarioController = TextEditingController();

  @override
  void dispose() {
    _comentarioController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ─────────────────────────────────────────────
    // Datos reales extraídos del perfil del conductor
    // ─────────────────────────────────────────────
    final usuarioConductor = widget.solicitud?.conductorData?['usuario'];
    final conductorNombre = (usuarioConductor is Map ? usuarioConductor['nombre'] : null) ??
        widget.solicitud?.conductorData?['nombre'] ??
        'Conductor Asignado';

    final experiencia = widget.solicitud?.conductorData?['experiencia'];
    final categoria = widget.solicitud?.conductorData?['categoriaLicencia'] ?? 'B1';
    final subtituloConductor = experiencia != null
        ? '4.9 ★ · $experiencia años de experiencia (Lic. $categoria)'
        : '4.9 ★ · Conductor Certificado MiConductor';

    final vehiculoData = widget.solicitud?.vehiculoData ?? {};
    final marca = vehiculoData['marca'] ?? '';
    final modelo = vehiculoData['modelo'] ?? '';
    final placa = vehiculoData['placa'] ?? '';
    final vehiculoTexto = [marca, modelo, placa].where((s) => s.isNotEmpty).join(' · ');

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Header badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.08),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check_circle, size: 16, color: AppColors.accentOrange),
                    SizedBox(width: 8),
                    Text(
                      'Has llegado al destino',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // Perfil real del conductor (Avatar con inicial / foto)
              Container(
                width: 86,
                height: 86,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.petrolLight, AppColors.petrolDark],
                  ),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.25),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(
                  child: Text(
                    conductorNombre.isNotEmpty ? conductorNombre[0].toUpperCase() : 'C',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Nombre real del conductor
              Text(
                conductorNombre,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              // Subtítulo con calificación y experiencia
              Text(
                subtituloConductor,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGray,
                  fontWeight: FontWeight.w500,
                ),
              ),

              if (vehiculoTexto.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.borderGray),
                  ),
                  child: Text(
                    'Vehículo: $vehiculoTexto',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.petrolBase,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Métricas de distancia y tiempo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: _buildTripInfoCard(
                      icon: Icons.map_outlined,
                      value: '18.4 km',
                      label: 'Distancia',
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _buildTripInfoCard(
                      icon: Icons.access_time_rounded,
                      value: '32 min',
                      label: 'Tiempo',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 36),

              // Sección de Calificación
              const Text(
                'Califica tu experiencia con el conductor',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                'Tu opinión ayuda a mantener la seguridad y calidad del servicio',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.slateGray,
                ),
              ),

              const SizedBox(height: 18),

              // Estrellas de 1 a 5
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (int i = 1; i <= 5; i++)
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _rating = i;
                        });
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Icon(
                          i <= _rating ? Icons.star_rounded : Icons.star_border_rounded,
                          color: AppColors.accentOrange,
                          size: 46,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // Mensaje de feedback según estrellas
              Text(
                _obtenerMensajeRating(_rating),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.petrolBase,
                ),
              ),

              const SizedBox(height: 36),

              // Botón Finalizar Servicio
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: const LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [AppColors.petrolBase, AppColors.petrolDark],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withValues(alpha: 0.3),
                        blurRadius: 14,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('¡Gracias por calificar a $conductorNombre con $_rating estrellas!'),
                          backgroundColor: AppColors.successGreen,
                        ),
                      );

                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (context) => const ClientSection(isGuest: false),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      foregroundColor: AppColors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Enviar Calificación y Finalizar',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Botón Reportar Problema
              TextButton(
                onPressed: () => _mostrarDialogoReporte(context),
                child: const Text(
                  '¿Tuviste algún inconveniente? Reportar servicio',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slateGray,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );
  }

  String _obtenerMensajeRating(int rating) {
    switch (rating) {
      case 5:
        return '¡Excelente servicio! ⭐⭐⭐⭐⭐';
      case 4:
        return 'Muy buen servicio ⭐⭐⭐⭐';
      case 3:
        return 'Servicio aceptable ⭐⭐⭐';
      case 2:
        return 'Servicio regular ⭐⭐';
      default:
        return 'Servicio insatisfactorio ⭐';
    }
  }

  Widget _buildTripInfoCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.borderGray, width: 1),
        boxShadow: [
          BoxShadow(
            color: AppColors.petrolDark.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: AppColors.accentOrange,
              size: 22,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.slateGray,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoReporte(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Reportar Servicio',
          style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold),
        ),
        content: TextField(
          controller: _comentarioController,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Describe el problema con el conductor o el servicio...',
            hintStyle: const TextStyle(color: AppColors.slateGray, fontSize: 13),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.borderGray),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar', style: TextStyle(color: AppColors.slateGray)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.petrolDark,
              foregroundColor: AppColors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reporte enviado correctamente.')),
              );
            },
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
  }
}
