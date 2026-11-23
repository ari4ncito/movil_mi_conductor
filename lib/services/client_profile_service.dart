import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'cliente_service.dart';

class ClientProfile {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? fotoUrl;
  final Uint8List? localImageBytes;

  const ClientProfile({
    this.id = '',
    this.name = 'Juan Pérez',
    this.email = 'juan.perez@email.com',
    this.phone = '+57 300 123 4567',
    this.fotoUrl,
    this.localImageBytes,
  });

  ClientProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? phone,
    String? fotoUrl,
    Uint8List? localImageBytes,
    bool clearLocalBytes = false,
  }) {
    return ClientProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      fotoUrl: fotoUrl ?? this.fotoUrl,
      localImageBytes: clearLocalBytes ? null : (localImageBytes ?? this.localImageBytes),
    );
  }
}

class ClientProfileService {
  ClientProfileService._();
  static final ClientProfileService instance = ClientProfileService._();

  // Cloudinary: direct unsigned upload
  static const String cloudinaryCloudName = 'tsovzwez';
  static const String cloudinaryUploadPreset = 'reportes';
  static const String cloudinaryFolder = 'clientes/perfiles';

  static String get backendBaseUrl => ApiConfig.baseUrl;

  final ValueNotifier<ClientProfile> profileNotifier = ValueNotifier<ClientProfile>(
    const ClientProfile(),
  );

  ClientProfile get currentProfile => profileNotifier.value;

  void updateProfileData({String? id, String? name, String? email, String? phone, String? fotoUrl}) {
    profileNotifier.value = profileNotifier.value.copyWith(
      id: id,
      name: name,
      email: email,
      phone: phone,
      fotoUrl: fotoUrl,
    );
  }

  void setPhotoUrl(String fotoUrl, {String? clientId}) {
    profileNotifier.value = profileNotifier.value.copyWith(
      id: clientId,
      fotoUrl: fotoUrl,
    );
  }

  void setLocalPhotoPreview(Uint8List bytes) {
    profileNotifier.value = profileNotifier.value.copyWith(
      localImageBytes: bytes,
    );
  }

  /// Sube la imagen a Cloudinary y sincroniza la foto con el backend (módulo Cliente)
  Future<String?> uploadProfilePhoto(
    Uint8List bytes, {
    String? clientId,
    String? usuarioId,
    String? filename,
  }) async {
    try {
      // 1. Guardar localmente para visualización instantánea en la app
      setLocalPhotoPreview(bytes);

      // 2. Subir directamente a Cloudinary mediante MultipartRequest
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = cloudinaryUploadPreset;
      request.fields['folder'] = cloudinaryFolder;

      final safeName = (filename != null && filename.isNotEmpty)
          ? filename
          : 'perfil_cliente_${DateTime.now().millisecondsSinceEpoch}.jpg';

      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: safeName,
        ),
      );

      final streamedResponse = await request.send().timeout(const Duration(seconds: 40));
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse =
            jsonDecode(response.body) as Map<String, dynamic>;
        final String? secureUrl = (jsonResponse['secure_url'] ?? jsonResponse['url']) as String?;

        if (secureUrl != null && secureUrl.isNotEmpty) {
          profileNotifier.value = profileNotifier.value.copyWith(
            id: clientId ?? profileNotifier.value.id,
            fotoUrl: secureUrl,
          );

          // 3. Sincronizar con el backend y con la sesión local
          await _syncPhotoWithBackend(
            secureUrl,
            clientId: clientId,
            usuarioId: usuarioId,
          );

          return secureUrl;
        }
      } else {
        debugPrint('[ClientProfileService] Error al subir a Cloudinary: ${response.body}');
      }
    } catch (e) {
      debugPrint('[ClientProfileService] Excepción al subir foto: $e');
    }
    return null;
  }

  Future<void> _syncPhotoWithBackend(
    String photoUrl, {
    String? clientId,
    String? usuarioId,
  }) async {
    try {
      // Actualizar usuario en SharedPreferences para persistencia local inmediata
      final prefs = await SharedPreferences.getInstance();
      final userStr = prefs.getString('user');
      String? sessionUserId = usuarioId;
      if (userStr != null && userStr.isNotEmpty) {
        final Map<String, dynamic> userMap =
            Map<String, dynamic>.from(jsonDecode(userStr) as Map);
        userMap['foto'] = photoUrl;
        sessionUserId ??= (userMap['_id'] ?? userMap['id'])?.toString();
        await prefs.setString('user', jsonEncode(userMap));
      }

      // Determinar el ID de cliente (o usuarioId como respaldo, ya que el backend soporta ambos)
      String? targetId = (clientId != null && clientId.isNotEmpty) ? clientId : null;
      if (targetId == null) {
        try {
          final clienteActual = await ClienteService.obtenerClienteActual();
          targetId = (clienteActual?['_id'] ?? clienteActual?['id'])?.toString();
        } catch (_) {}
      }
      targetId ??= sessionUserId;

      if (targetId != null && targetId.isNotEmpty) {
        await ClienteService.actualizarFoto(targetId, photoUrl);
        debugPrint('[ClientProfileService] Foto sincronizada con backend para ID: $targetId');
      }
    } catch (e) {
      debugPrint('[ClientProfileService] Nota backend sync: $e');
    }
  }
}
