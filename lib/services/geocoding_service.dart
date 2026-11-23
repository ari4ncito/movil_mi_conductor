import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

/// Estados posibles de una dirección en el pipeline de geocodificación
enum GeocodingState {
  /// Estado inicial o campo vacío
  idle,

  /// Sintaxis local válida (Fase 1), pendiente o en proceso de verificación geográfica
  syntaxValid,

  /// Verificación HTTP en curso
  verifying,

  /// Fase 3 y 4 exitosa: confirmada por ArcGIS con coordenadas reales, ciudad y barrio
  verified,

  /// Sintaxis válida pero no encontrada en la malla vial (Score < 78 o sin candidatos de calle)
  notFound,

  /// Error local de sintaxis o dirección rechazada por lista negra
  syntaxInvalid,

  /// Fallo temporal del proveedor o de conexión (un timeout/error NUNCA se marca como verificado)
  networkError,
}

/// Resultado estructurado del pipeline de validación y geocodificación
class GeocodingResult {
  final String originalAddress;
  final String normalizedAddress;
  final String? matchAddress;
  final double? lat;
  final double? lng;
  final String? neighborhood;
  final String? city;
  final String? region;
  final double? score;
  final String? addrType;
  final GeocodingState state;
  final String? message;

  const GeocodingResult({
    required this.originalAddress,
    required this.normalizedAddress,
    this.matchAddress,
    this.lat,
    this.lng,
    this.neighborhood,
    this.city,
    this.region,
    this.score,
    this.addrType,
    required this.state,
    this.message,
  });

  bool get isVerified => state == GeocodingState.verified && lat != null && lng != null;
  bool get hasCoordinates => lat != null && lng != null;
  LatLng? get latLng => hasCoordinates ? LatLng(lat!, lng!) : null;

  /// Descripción legible para mostrar en la interfaz
  String get displaySubtitle {
    if (isVerified) {
      final parts = <String>[];
      if (neighborhood != null && neighborhood!.trim().isNotEmpty) {
        parts.add('Barrio: ${neighborhood!.trim()}');
      }
      if (city != null && city!.trim().isNotEmpty) {
        parts.add(city!.trim());
      }
      return parts.isNotEmpty ? parts.join(' • ') : (matchAddress ?? 'Ubicación verificada');
    }
    return message ?? '';
  }

  factory GeocodingResult.idle(String address) => GeocodingResult(
        originalAddress: address,
        normalizedAddress: address,
        state: GeocodingState.idle,
      );

  factory GeocodingResult.syntaxInvalid(String address, String reason) =>
      GeocodingResult(
        originalAddress: address,
        normalizedAddress: address,
        state: GeocodingState.syntaxInvalid,
        message: reason,
      );

  factory GeocodingResult.syntaxValid(String address, String normalized) =>
      GeocodingResult(
        originalAddress: address,
        normalizedAddress: normalized,
        state: GeocodingState.syntaxValid,
        message: 'Sintaxis vial colombiana válida',
      );

  factory GeocodingResult.networkError(
    String address,
    String normalized,
    String errorMsg,
  ) =>
      GeocodingResult(
        originalAddress: address,
        normalizedAddress: normalized,
        state: GeocodingState.networkError,
        message: errorMsg,
      );

  factory GeocodingResult.notFound(
    String address,
    String normalized,
    String reason,
  ) =>
      GeocodingResult(
        originalAddress: address,
        normalizedAddress: normalized,
        state: GeocodingState.notFound,
        message: reason,
      );
}

/// Entrada de caché en memoria con TTL de 1 hora
class _CachedGeocodingEntry {
  final GeocodingResult result;
  final DateTime timestamp;

  _CachedGeocodingEntry(this.result) : timestamp = DateTime.now();

  bool get isExpired =>
      DateTime.now().difference(timestamp) > const Duration(hours: 1);
}

/// Servicio centralizado de validación sintáctica y geocodificación híbrida de 4 fases
class GeocodingService {
  GeocodingService._internal();
  static final GeocodingService instance = GeocodingService._internal();

  /// Caché en memoria con TTL de 1 hora
  final Map<String, _CachedGeocodingEntry> _cache = {};

  // ===========================================================================
  // FASE 1: REGLAS DE SINTAXIS VIAL COLOMBIANA Y LISTA NEGRA
  // ===========================================================================

  static final List<RegExp> _blackList = [
    RegExp(r'\bcalle\s+falsa(\s+\d+)?\b', caseSensitive: false),
    RegExp(r'\bcarrera\s+falsa(\s+\d+)?\b', caseSensitive: false),
    RegExp(r'^\s*\d+\s*#\s*\d+\s*$', caseSensitive: false),
    RegExp(r'^\s*0\s*#\s*0\s*$', caseSensitive: false),
    RegExp(r'\basdf\b', caseSensitive: false),
    RegExp(r'\bqwerty\b', caseSensitive: false),
    RegExp(r'\bsin\s+direcci[oó]n\b', caseSensitive: false),
    RegExp(r'\bningun[ao]\b', caseSensitive: false),
    RegExp(r'\bcasa\s+de\s+mi\s+mam[aá]\b', caseSensitive: false),
    RegExp(r'\bcasa\s+m[ií]a\b', caseSensitive: false),
    RegExp(r'\bprueba(\s+\d+)?\b', caseSensitive: false),
    RegExp(r'\btest(\s+\d+)?\b', caseSensitive: false),
  ];

  /// Estructura de dirección vial colombiana:
  /// 1. Vía urbana: Prefijo + identificador + cruce (#, No, Nro, -) + placa
  /// 2. Rural / Vía / Km / Variante / Vereda
  static final RegExp _roadStructureRegex = RegExp(
    r'^(?:'
    r'(?:Calle|Cll|Cl|Carrera|Cra|Cr|Kr|K|Circular|Cir|Cq|Diagonal|Diag|Dg|Transversal|Transv|Tv|Tr|Avenida|Avda|Av|Autopista)\.?\s+'
    r'[A-Za-z0-9\s\u00C0-\u017F]+?\s*(?:#|No\.?|Nro\.?|-)\s*\d+[A-Za-z0-9\s\-\#,.\u00C0-\u017F]*'
    r'|'
    r'(?:Km|Kil[oó]metro)\.?\s+\d+[\w\s,.\u00C0-\u017F-]*'
    r'|'
    r'(?:Autopista|V[ií]a|Variante|Camino|Vereda)\.?\s+[A-Za-z0-9\s,.\u00C0-\u017F-]{3,}'
    r')$',
    caseSensitive: false,
  );

  // ===========================================================================
  // FASE 2: NORMALIZACIÓN INTELIGENTE
  // ===========================================================================

  static final List<RegExp> _horizontalProperties = [
    RegExp(
      r'\b(?:apto|apartamento|int|interior|torre|bloque|piso|local|oficina|casa|manzana|bodega|lote|etapa|consultorio|porter[ií]a)\b[\s\w#-]*',
      caseSensitive: false,
    ),
  ];

  static const List<MapEntry<String, String>> _prefixAbbreviations = [
    MapEntry(r'\b(?:cr|cra|kr|k)\.?\b', 'Carrera'),
    MapEntry(r'\b(?:cl|cll)\.?\b', 'Calle'),
    MapEntry(r'\b(?:cq|cir)\.?\b', 'Circular'),
    MapEntry(r'\b(?:dg|diag)\.?\b', 'Diagonal'),
    MapEntry(r'\b(?:tv|tr|transv)\.?\b', 'Transversal'),
    MapEntry(r'\b(?:av|avda)\.?\b', 'Avenida'),
    MapEntry(r'\bkm\.?\b', 'Kilómetro'),
  ];

  static const List<String> _valleAburraOriente = [
    'medellin', 'medellín', 'envigado', 'itagui', 'itagüí', 'bello',
    'sabaneta', 'la estrella', 'copacabana', 'girardota', 'caldas',
    'barbosa', 'rionegro', 'marinilla', 'guarne', 'el retiro',
    'la ceja', 'carmen de viboral'
  ];

  static const List<String> _otherColombianCities = [
    'bogota', 'bogotá', 'cali', 'barranquilla', 'bucaramanga', 'cartagena',
    'pereira', 'manizales', 'cucuta', 'cúcuta', 'santa marta', 'ibague',
    'ibagué', 'villavicencio', 'pasto', 'monteria', 'montería', 'armenia',
    'popayan', 'popayán', 'valledupar', 'sincelejo', 'tunja', 'neiva'
  ];

  static const String extentValleAburra = '-75.80,5.95,-75.20,6.50';
  static const String extentColombia = '-79.10,-4.30,-66.80,12.60';

  // ===========================================================================
  // FASE 1: VALIDACIÓN SINTÁCTICA VIAL (0 MS LOCAL)
  // ===========================================================================

  /// Valida la sintaxis local de la dirección. Retorna null si es válida, o mensaje de error.
  String? validateSyntax(String? rawAddress) {
    if (rawAddress == null) return 'Ingresa una dirección válida';
    final trimmed = rawAddress.trim();

    if (trimmed.length < 8) {
      return 'Dirección demasiado corta (mínimo 8 caracteres)';
    }

    final lower = trimmed.toLowerCase();
    for (final pattern in _blackList) {
      if (pattern.hasMatch(lower)) {
        return 'Dirección no válida o no permitida';
      }
    }

    if (!_roadStructureRegex.hasMatch(trimmed)) {
      return 'Usa nomenclatura vial colombiana (ej. Cl. 10 # 43E-15, Cra 43A # 1-50)';
    }

    return null;
  }

  // ===========================================================================
  // FASE 2: NORMALIZACIÓN INTELIGENTE
  // ===========================================================================

  /// Normaliza la consulta eliminando propiedad horizontal, expandiendo prefijos
  /// y ajustando la cobertura geográfica y searchExtent.
  Map<String, String> normalizeAddress(String rawAddress) {
    var cleaned = rawAddress.trim();

    // 1. Eliminar detalles de propiedad horizontal
    for (final hp in _horizontalProperties) {
      cleaned = cleaned.replaceAll(hp, '');
    }
    cleaned = cleaned.replaceAll(RegExp(r'[\s,]+$'), '').trim();

    // 2. Expandir abreviaturas viales
    for (final entry in _prefixAbbreviations) {
      final reg = RegExp(entry.key, caseSensitive: false);
      cleaned = cleaned.replaceAllMapped(reg, (match) => entry.value);
    }
    cleaned = cleaned.replaceAll(RegExp(r'\s+'), ' ').trim();

    // 3. Adaptar cobertura geográfica
    var extent = extentValleAburra;
    var hasMuni = false;
    final lower = cleaned.toLowerCase();

    for (final muni in _valleAburraOriente) {
      if (lower.contains(muni)) {
        hasMuni = true;
        extent = extentValleAburra;
        if (!lower.contains('antioquia')) {
          cleaned = '$cleaned, Antioquia';
        }
        if (!lower.contains('colombia')) {
          cleaned = '$cleaned, Colombia';
        }
        break;
      }
    }

    if (!hasMuni) {
      for (final city in _otherColombianCities) {
        if (lower.contains(city)) {
          hasMuni = true;
          extent = extentColombia;
          if (!lower.contains('colombia')) {
            cleaned = '$cleaned, Colombia';
          }
          break;
        }
      }
    }

    if (!hasMuni) {
      // Si no especifica municipio, usar por defecto Medellín, Antioquia, Colombia
      cleaned = '$cleaned, Medellín, Antioquia, Colombia';
      extent = extentValleAburra;
    }

    return {
      'query': cleaned,
      'extent': extent,
    };
  }

  // ===========================================================================
  // FASES 3 Y 4: GEOCODIFICACIÓN ARCGIS + ENRIQUECIMIENTO NOMINATIM REVERSE
  // ===========================================================================

  /// Ejecuta el pipeline completo de validación y geocodificación
  Future<GeocodingResult> geocodeAddress(String rawAddress) async {
    final trimmed = rawAddress.trim();
    if (trimmed.isEmpty) {
      return GeocodingResult.idle(rawAddress);
    }

    // Fase 1: Validación sintáctica
    final syntaxError = validateSyntax(trimmed);
    if (syntaxError != null) {
      return GeocodingResult.syntaxInvalid(trimmed, syntaxError);
    }

    // Fase 2: Normalización
    final normData = normalizeAddress(trimmed);
    final normalizedQuery = normData['query']!;
    final extent = normData['extent']!;

    // Verificación en caché (TTL 1h)
    final cacheKey = normalizedQuery.toLowerCase();
    final cached = _cache[cacheKey];
    if (cached != null && !cached.isExpired) {
      debugPrint('[GeocodingService] Cache hit para: $cacheKey');
      return cached.result;
    }

    try {
      // Fase 3: ArcGIS REST World Geocoder
      final arcGisUri = Uri.parse(
        'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates',
      ).replace(
        queryParameters: {
          'SingleLine': normalizedQuery,
          'countryCode': 'COL',
          'searchExtent': extent,
          'maxLocations': '3',
          'outFields': 'Addr_type,Match_addr,Nbrhd,District,City,Region,Score',
          'f': 'json',
        },
      );

      final arcGisResponse = await http
          .get(
            arcGisUri,
            headers: {
              'User-Agent': 'MiConductorApp/1.0',
              'Accept': 'application/json',
            },
          )
          .timeout(const Duration(seconds: 5));

      if (arcGisResponse.statusCode != 200) {
        return GeocodingResult.networkError(
          trimmed,
          normalizedQuery,
          'Error del servicio de mapas (${arcGisResponse.statusCode})',
        );
      }

      final Map<String, dynamic> data = jsonDecode(arcGisResponse.body);
      final List candidates = (data['candidates'] as List?) ?? [];

      const validAddrTypes = {
        'PointAddress',
        'StreetAddress',
        'Subaddress',
        'StreetInt',
        'StreetName',
      };
      const double minScore = 78.0;

      // Parsing del bbox searchExtent (xmin, ymin, xmax, ymax)
      final extentParts =
          extent.split(',').map((p) => double.tryParse(p.trim()) ?? 0.0).toList();
      final xmin = extentParts[0];
      final ymin = extentParts[1];
      final xmax = extentParts[2];
      final ymax = extentParts[3];

      Map<String, dynamic>? selectedCandidate;

      for (final c in candidates) {
        if (c is! Map) continue;
        final attrs = c['attributes'] as Map? ?? {};
        final addrType = attrs['Addr_type']?.toString();
        final score = (c['score'] as num?)?.toDouble() ?? 0.0;
        final loc = c['location'] as Map? ?? {};
        final x = (loc['x'] as num?)?.toDouble() ?? 0.0;
        final y = (loc['y'] as num?)?.toDouble() ?? 0.0;

        if (validAddrTypes.contains(addrType) && score >= minScore) {
          if (x >= xmin && x <= xmax && y >= ymin && y <= ymax) {
            selectedCandidate = Map<String, dynamic>.from(c);
            break;
          }
        }
      }

      if (selectedCandidate == null) {
        return GeocodingResult.notFound(
          trimmed,
          normalizedQuery,
          'Dirección no localizada en la malla vial oficial',
        );
      }

      final attrs = Map<String, dynamic>.from(selectedCandidate['attributes'] as Map);
      final loc = Map<String, dynamic>.from(selectedCandidate['location'] as Map);
      final lat = (loc['y'] as num).toDouble();
      final lng = (loc['x'] as num).toDouble();
      final score = (selectedCandidate['score'] as num).toDouble();
      final matchAddr = attrs['Match_addr']?.toString();
      final addrType = attrs['Addr_type']?.toString();
      var nbrhd = attrs['Nbrhd'] != null ? '${attrs['Nbrhd']}'.trim() : '';
      final city = attrs['City'] != null ? '${attrs['City']}'.trim() : null;
      final region = attrs['Region'] != null ? '${attrs['Region']}'.trim() : null;

      // Fase 4: Enriquecimiento de barrio con Nominatim Reverse si Nbrhd viene vacío
      if (nbrhd.isEmpty) {
        try {
          final nomUri = Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lng&zoom=16',
          );
          final nomResponse = await http
              .get(
                nomUri,
                headers: {
                  'User-Agent': 'MiConductorApp/1.0',
                  'Accept': 'application/json',
                },
              )
              .timeout(const Duration(milliseconds: 2500));

          if (nomResponse.statusCode == 200) {
            final Map<String, dynamic> nomData = jsonDecode(nomResponse.body);
            final nomAddr = nomData['address'] as Map? ?? {};
            nbrhd = nomAddr['suburb']?.toString() ??
                nomAddr['neighbourhood']?.toString() ??
                nomAddr['quarter']?.toString() ??
                nomAddr['residential']?.toString() ??
                nomAddr['city_district']?.toString() ??
                '';
          }
        } catch (e) {
          debugPrint('[GeocodingService] Aviso en Fase 4 Nominatim Reverse: $e');
          // No bloquea la verificación si ArcGIS ya dio coordenadas válidas
        }
      }

      final result = GeocodingResult(
        originalAddress: trimmed,
        normalizedAddress: normalizedQuery,
        matchAddress: matchAddr,
        lat: lat,
        lng: lng,
        neighborhood: nbrhd.isNotEmpty ? nbrhd : null,
        city: city,
        region: region,
        score: score,
        addrType: addrType,
        state: GeocodingState.verified,
        message: 'Dirección geográficamente verificada',
      );

      // Guardar en caché con TTL de 1 hora
      _cache[cacheKey] = _CachedGeocodingEntry(result);

      return result;
    } on SocketException catch (_) {
      return GeocodingResult.networkError(
        trimmed,
        normalizedQuery,
        'Sin conexión a internet para verificar la dirección',
      );
    } on TimeoutException catch (_) {
      return GeocodingResult.networkError(
        trimmed,
        normalizedQuery,
        'Tiempo de espera agotado al verificar la dirección',
      );
    } catch (e) {
      debugPrint('[GeocodingService] Error inesperado en geocodificación: $e');
      return GeocodingResult.networkError(
        trimmed,
        normalizedQuery,
        'Fallo temporal del proveedor de mapas',
      );
    }
  }

  /// Limpia la caché en memoria (por ejemplo al cerrar sesión o en tests)
  void clearCache() {
    _cache.clear();
  }
}
