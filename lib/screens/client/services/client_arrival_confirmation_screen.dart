import 'package:flutter/material.dart';
import '../../../models/solicitud.dart';
import '../../../services/novedad_service.dart';
import 'client_arrived_destination_screen.dart';

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

class ClientArrivalConfirmationScreen extends StatefulWidget {
  final Solicitud? solicitud;

  const ClientArrivalConfirmationScreen({super.key, this.solicitud});

  @override
  State<ClientArrivalConfirmationScreen> createState() =>
      _ClientArrivalConfirmationScreenState();
}

class _ClientArrivalConfirmationScreenState
    extends State<ClientArrivalConfirmationScreen> {
  final NovedadService _novedadService = NovedadService();

  bool _hayCambioDeRuta = false;
  String _destinoInicial = '';
  String _destinoFinal = '';
  String _motivoCambio = '';

  @override
  void initState() {
    super.initState();
    _procesarRutaYCambios();
  }

  Future<void> _procesarRutaYCambios() async {
    final sol = widget.solicitud;
    final destinoActual = sol?.destino ?? 'Destino';
    final destinoIni = sol?.destinoInicial;

    if (destinoIni != null &&
        destinoIni.isNotEmpty &&
        destinoIni.trim().toLowerCase() != destinoActual.trim().toLowerCase()) {
      setState(() {
        _hayCambioDeRuta = true;
        _destinoInicial = destinoIni;
        _destinoFinal = destinoActual;
        _motivoCambio = sol?.cambioRuta?['motivo']?.toString() ??
            'Cambio de ruta reportado durante el viaje';
      });
      return;
    }

    // Si en el modelo no venía explícito, consultar novedades asociadas a la solicitud
    if (sol?.id != null && sol!.id!.isNotEmpty) {
      try {
        final novedades =
            await _novedadService.obtenerNovedadesPorSolicitud(sol.id!);
        for (final nov in novedades) {
          final esCambio = (nov.tipo ?? '').toUpperCase() == 'CAMBIO_RUTA' ||
              (nov.descripcion ?? '').contains('[NUEVA DIRECCIÓN / DESTINO]') ||
              (nov.titulo ?? '').toLowerCase().contains('cambio de ruta') ||
              (nov.titulo ?? '').toLowerCase().contains('desvío');

          if (esCambio) {
            String nuevo = destinoActual;
            final desc = nov.descripcion ?? '';
            if (desc.contains('[NUEVA DIRECCIÓN / DESTINO]:')) {
              final partes = desc.split('[NUEVA DIRECCIÓN / DESTINO]:');
              if (partes.length > 1) {
                nuevo = partes[1].trim();
              }
            }

            if (mounted) {
              setState(() {
                _hayCambioDeRuta = true;
                _destinoInicial = sol.destinoInicial ??
                    (destinoActual != nuevo ? destinoActual : 'Destino inicial programado');
                _destinoFinal = nuevo.isNotEmpty ? nuevo : destinoActual;
                _motivoCambio = nov.titulo ??
                    nov.observaciones ??
                    'Incidente reportado en la vía';
              });
            }
            break;
          }
        }
      } catch (e) {
        debugPrint('Aviso al consultar novedades de la solicitud: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final solicitud = widget.solicitud;

    // Extracción de datos reales de la solicitud
    final usuarioConductor = solicitud?.conductorData?['usuario'];
    final conductorNombre = (usuarioConductor is Map
            ? usuarioConductor['nombre']
            : null) ??
        solicitud?.conductorData?['nombre'] ??
        'Conductor Asignado';

    final vehiculoData = solicitud?.vehiculoData ?? {};
    final marca = vehiculoData['marca'] ?? '';
    final modelo = vehiculoData['modelo'] ?? '';
    final placa = vehiculoData['placa'] ?? '';
    final vehiculoTexto =
        [marca, modelo, placa].where((s) => s.isNotEmpty).join(' · ');

    final origen = solicitud?.origen ?? 'Origen';
    final destino = solicitud?.destino ?? 'Destino';

    final destInicialMostrar =
        _destinoInicial.isNotEmpty ? _destinoInicial : origen;
    final destFinalMostrar =
        _destinoFinal.isNotEmpty ? _destinoFinal : destino;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),

              // Icono principal de llegada con halo elegante
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [AppColors.petrolLight, AppColors.petrolDark],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withValues(alpha: 0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.location_on_rounded,
                    color: AppColors.white,
                    size: 48,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Título y mensaje de confirmación
              const Text(
                '¡Has Llegado!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Tu conductor ha completado el recorrido y entregado el vehículo en tu destino con éxito.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.slateGray,
                  height: 1.4,
                ),
              ),

              const SizedBox(height: 32),

              // Tarjeta de Ruta: Origen, Destino Inicial y Cambio de Ruta (Registro)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: AppColors.borderGray, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.petrolDark.withValues(alpha: 0.05),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ORIGEN
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          margin: const EdgeInsets.only(top: 2),
                          width: 14,
                          height: 14,
                          decoration: const BoxDecoration(
                            color: AppColors.successGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'ORIGEN',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.slateGray,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                origen,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Línea divisoria
                    Padding(
                      padding: const EdgeInsets.only(left: 6),
                      child: Container(
                        height: 22,
                        width: 2,
                        color: AppColors.borderGray,
                      ),
                    ),

                    // CONDICIONAL: SI HUBO CAMBIO DE RUTA
                    if (_hayCambioDeRuta) ...[
                      // DESTINO INICIAL (Ruta programada original)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 14,
                            height: 14,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade400,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'DESTINO INICIAL',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.slateGray,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.grey.shade200,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: const Text(
                                        'Ruta inicial',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black54,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destInicialMostrar,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade600,
                                    decoration: TextDecoration.lineThrough,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      // Línea divisoria de cambio de ruta
                      Padding(
                        padding: const EdgeInsets.only(left: 6),
                        child: Container(
                          height: 22,
                          width: 2,
                          color: AppColors.accentOrange.withOpacity(0.6),
                        ),
                      ),

                      // NUEVO DESTINO (Destino final tras el cambio)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Text(
                                      'DESTINO FINAL (MODIFICADO)',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.accentOrange,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.accentOrange
                                            .withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'CAMBIO REGISTRADO',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.accentOrange,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destFinalMostrar,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // TARJETA DE REGISTRO FORMAL DEL CAMBIO DE RUTA
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFEDD5)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.alt_route_rounded,
                              size: 20,
                              color: AppColors.accentOrange,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Registro de Cambio de Ruta',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF9A3412),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _motivoCambio.isNotEmpty
                                        ? 'Motivo registrado: $_motivoCambio'
                                        : 'Se registró una novedad que obligó a desviar o cambiar la dirección del destino.',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFC2410C),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      // DESTINO NORMAL
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            margin: const EdgeInsets.only(top: 2),
                            width: 14,
                            height: 14,
                            decoration: const BoxDecoration(
                              color: AppColors.accentOrange,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'DESTINO',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.slateGray,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  destino,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 18),

              // Tarjeta del vehículo (si está disponible) - SIN DURACIÓN NI DISTANCIA
              if (vehiculoTexto.isNotEmpty) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: AppColors.borderGray, width: 1),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.petrolDark.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.petrolBase.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.directions_car,
                          size: 20,
                          color: AppColors.petrolBase,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Vehículo entregado',
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.slateGray,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              vehiculoTexto,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F9F0),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Inspeccionado',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.successGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
              ],

              // Tarjeta del Conductor
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.borderGray),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppColors.petrolLight, AppColors.petrolDark],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          conductorNombre.isNotEmpty
                              ? conductorNombre[0].toUpperCase()
                              : 'C',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Conductor asignado',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.slateGray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            conductorNombre,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.check_circle,
                      color: AppColors.successGreen,
                      size: 24,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 36),

              // Botón Principal hacia Calificación
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(30),
                  gradient: const LinearGradient(
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
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (context) => ClientArrivedDestinationScreen(
                          solicitud: solicitud,
                        ),
                      ),
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
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Calificar Servicio',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 20),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
