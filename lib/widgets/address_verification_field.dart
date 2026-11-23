import 'dart:async';
import 'package:flutter/material.dart';
import '../services/geocoding_service.dart';

/// Campo de texto especializado para direcciones colombianas con:
/// - Validación sintáctica vial en 0 ms
/// - Debounce de 400 ms
/// - Cancelación de peticiones en vuelo
/// - Retroalimentación visual de los 3 estados (Sintaxis válida, Verificada geográficamente, Error de red)
class AddressVerificationField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;
  final IconData icon;
  final Color iconColor;
  final ValueChanged<GeocodingResult>? onResultChanged;
  final String? Function(String?)? validator;
  final bool enabled;
  final FocusNode? focusNode;
  final TextInputAction textInputAction;
  final void Function(String)? onFieldSubmitted;

  const AddressVerificationField({
    super.key,
    required this.controller,
    required this.label,
    this.hint,
    this.icon = Icons.location_on_rounded,
    this.iconColor = const Color(0xFF0B3B4A),
    this.onResultChanged,
    this.validator,
    this.enabled = true,
    this.focusNode,
    this.textInputAction = TextInputAction.next,
    this.onFieldSubmitted,
  });

  @override
  State<AddressVerificationField> createState() => _AddressVerificationFieldState();
}

class _AddressVerificationFieldState extends State<AddressVerificationField> {
  Timer? _debounceTimer;
  int _activeRequestId = 0;
  GeocodingResult? _currentResult;
  bool _isEvaluating = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
    if (widget.controller.text.trim().isNotEmpty) {
      _evaluateAddress(widget.controller.text, immediate: true);
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    widget.controller.removeListener(_onTextChanged);
    super.dispose();
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    _evaluateAddress(text, immediate: false);
  }

  void _evaluateAddress(String text, {required bool immediate}) {
    final trimmed = text.trim();
    _debounceTimer?.cancel();
    final requestId = ++_activeRequestId;

    if (trimmed.isEmpty) {
      final res = GeocodingResult.idle('');
      if (mounted) {
        setState(() {
          _currentResult = res;
          _isEvaluating = false;
        });
      }
      widget.onResultChanged?.call(res);
      return;
    }

    // FASE 1: Validación sintáctica local inmediata (0 ms)
    final syntaxErr = GeocodingService.instance.validateSyntax(trimmed);
    if (syntaxErr != null) {
      final res = GeocodingResult.syntaxInvalid(trimmed, syntaxErr);
      if (mounted) {
        setState(() {
          _currentResult = res;
          _isEvaluating = false;
        });
      }
      widget.onResultChanged?.call(res);
      return;
    }

    // Sintaxis local válida
    final normData = GeocodingService.instance.normalizeAddress(trimmed);
    final prelimResult = GeocodingResult.syntaxValid(trimmed, normData['query']!);
    if (mounted) {
      setState(() {
        _currentResult = prelimResult;
        _isEvaluating = true;
      });
    }
    widget.onResultChanged?.call(prelimResult);

    // FASE 2, 3 y 4: Geocodificación con Debounce de 400 ms
    void runGeocoding() async {
      try {
        final result = await GeocodingService.instance.geocodeAddress(trimmed);
        if (_activeRequestId == requestId && mounted) {
          setState(() {
            _currentResult = result;
            _isEvaluating = false;
          });
          widget.onResultChanged?.call(result);
        }
      } catch (e) {
        if (_activeRequestId == requestId && mounted) {
          final errResult = GeocodingResult.networkError(
            trimmed,
            trimmed,
            'Fallo temporal del proveedor de mapas',
          );
          setState(() {
            _currentResult = errResult;
            _isEvaluating = false;
          });
          widget.onResultChanged?.call(errResult);
        }
      }
    }

    if (immediate) {
      runGeocoding();
    } else {
      _debounceTimer = Timer(const Duration(milliseconds: 400), runGeocoding);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = _currentResult?.state ?? GeocodingState.idle;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        TextFormField(
          controller: widget.controller,
          enabled: widget.enabled,
          focusNode: widget.focusNode,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF1F2937),
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: widget.label,
            hintText: widget.hint ?? 'Ej: Cra. 43A # 1-50, Poblado',
            hintStyle: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.normal,
            ),
            labelStyle: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
            floatingLabelStyle: TextStyle(
              fontSize: 14,
              color: widget.iconColor,
              fontWeight: FontWeight.w600,
            ),
            prefixIcon: Icon(widget.icon, color: widget.iconColor, size: 22),
            suffixIcon: _buildSuffixIcon(state),
            filled: true,
            fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: _getBorderColor(state)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: widget.iconColor, width: 1.8),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade600, width: 1.8),
            ),
          ),
          validator: (val) {
            final syntaxError = GeocodingService.instance.validateSyntax(val);
            if (syntaxError != null) return syntaxError;
            if (widget.validator != null) {
              return widget.validator!(val);
            }
            return null;
          },
        ),
        if (_currentResult != null && state != GeocodingState.idle) ...[
          const SizedBox(height: 6),
          _buildStatusFeedback(_currentResult!),
        ],
      ],
    );
  }

  Color _getBorderColor(GeocodingState state) {
    switch (state) {
      case GeocodingState.verified:
        return Colors.green.shade400;
      case GeocodingState.syntaxValid:
      case GeocodingState.verifying:
        return const Color(0xFF12566B).withValues(alpha: 0.5);
      case GeocodingState.networkError:
        return Colors.amber.shade700;
      case GeocodingState.notFound:
      case GeocodingState.syntaxInvalid:
        return Colors.red.shade300;
      case GeocodingState.idle:
        return Colors.grey.shade300;
    }
  }

  Widget? _buildSuffixIcon(GeocodingState state) {
    if (_isEvaluating || state == GeocodingState.verifying) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0B3B4A)),
          ),
        ),
      );
    }

    switch (state) {
      case GeocodingState.verified:
        return const Tooltip(
          message: 'Dirección geográficamente verificada',
          child: Icon(Icons.check_circle_rounded, color: Colors.green, size: 22),
        );
      case GeocodingState.syntaxValid:
      case GeocodingState.verifying:
        return const Tooltip(
          message: 'Sintaxis vial válida',
          child: Icon(Icons.done_rounded, color: Color(0xFF12566B), size: 20),
        );
      case GeocodingState.networkError:
        return Tooltip(
          message: 'Fallo temporal de conexión con el proveedor de mapas',
          child: Icon(Icons.cloud_off_rounded, color: Colors.amber.shade800, size: 22),
        );
      case GeocodingState.notFound:
        return const Tooltip(
          message: 'Dirección no encontrada en la malla vial',
          child: Icon(Icons.help_outline_rounded, color: Colors.redAccent, size: 22),
        );
      case GeocodingState.syntaxInvalid:
        return const Tooltip(
          message: 'Sintaxis vial incompleta o inválida',
          child: Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 22),
        );
      case GeocodingState.idle:
        return null;
    }
  }

  Widget _buildStatusFeedback(GeocodingResult result) {
    Color bg;
    Color border;
    Color textColor;
    IconData icon;
    String title;
    String subtitle;

    switch (result.state) {
      case GeocodingState.verified:
        bg = const Color(0xFFE8F5E9);
        border = const Color(0xFF81C784);
        textColor = const Color(0xFF2E7D32);
        icon = Icons.verified_rounded;
        title = 'Ubicación verificada en malla vial';
        subtitle = result.displaySubtitle;
        break;

      case GeocodingState.syntaxValid:
      case GeocodingState.verifying:
        bg = const Color(0xFFE0F2F1);
        border = const Color(0xFF80CBC4);
        textColor = const Color(0xFF00695C);
        icon = Icons.check_circle_outline_rounded;
        title = 'Sintaxis vial colombiana válida';
        subtitle = _isEvaluating
            ? 'Verificando con ArcGIS World Geocoder...'
            : 'Formato correcto (${result.normalizedAddress})';
        break;

      case GeocodingState.networkError:
        bg = const Color(0xFFFFF8E1);
        border = const Color(0xFFFFD54F);
        textColor = const Color(0xFFE65100);
        icon = Icons.wifi_off_rounded;
        title = 'Fallo temporal del proveedor / red';
        subtitle =
            '${result.message ?? "No fue posible verificar en vivo"}. Tu solicitud conservará la dirección con validación local.';
        break;

      case GeocodingState.notFound:
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFEF9A9A);
        textColor = const Color(0xFFC62828);
        icon = Icons.location_off_rounded;
        title = 'Dirección no localizada';
        subtitle = 'No se encontró en la malla vial oficial. Verifica calle, carrera y número.';
        break;

      case GeocodingState.syntaxInvalid:
        bg = const Color(0xFFFFEBEE);
        border = const Color(0xFFEF9A9A);
        textColor = const Color(0xFFC62828);
        icon = Icons.info_outline_rounded;
        title = 'Sintaxis vial no válida';
        subtitle = result.message ?? 'Verifica la estructura de nomenclatura vial.';
        break;

      case GeocodingState.idle:
        return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 1, right: 8),
            child: Icon(icon, size: 16, color: textColor),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.9),
                      height: 1.25,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
