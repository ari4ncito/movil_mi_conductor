import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

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

  // Backend base URLs
  static String get backendBaseUrl {
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000/api';
    }
    return 'http://localhost:3000/api';
  }

  final ValueNotifier<ClientProfile> profileNotifier = ValueNotifier<ClientProfile>(
    const ClientProfile(),
  );

  ClientProfile get currentProfile => profileNotifier.value;

  void updateProfileData({String? name, String? email, String? phone}) {
    profileNotifier.value = profileNotifier.value.copyWith(
      name: name,
      email: email,
      phone: phone,
    );
  }

  void setLocalPhotoPreview(Uint8List bytes) {
    profileNotifier.value = profileNotifier.value.copyWith(
      localImageBytes: bytes,
    );
  }

  /// Sube la imagen a Cloudinary y sincroniza la foto con el backend
  Future<String?> uploadProfilePhoto(Uint8List bytes, {String? clientId}) async {
    try {
      // 1. Guardar localmente para visualización instantánea en la app
      setLocalPhotoPreview(bytes);

      // 2. Subir directamente a Cloudinary mediante HTTP POST
      final base64Image = base64Encode(bytes);
      final dataUri = 'data:image/jpeg;base64,$base64Image';

      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudinaryCloudName/image/upload');
      final client = HttpClient();
      final request = await client.postUrl(uri);
      request.headers.contentType = ContentType('application', 'x-www-form-urlencoded', charset: 'utf-8');

      final body = 'upload_preset=$cloudinaryUploadPreset&folder=$cloudinaryFolder&file=${Uri.encodeComponent(dataUri)}';
      request.write(body);

      final response = await request.close();
      final responseBody = await response.transform(utf8.decoder).join();
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final Map<String, dynamic> jsonResponse = jsonDecode(responseBody) as Map<String, dynamic>;
        final String? secureUrl = jsonResponse['secure_url'] as String?;

        if (secureUrl != null && secureUrl.isNotEmpty) {
          // Actualizar estado del perfil con la URL permanente
          profileNotifier.value = profileNotifier.value.copyWith(
            fotoUrl: secureUrl,
          );

          // 3. Sincronizar con el backend
          await _syncPhotoWithBackend(secureUrl, clientId: clientId ?? profileNotifier.value.id);

          return secureUrl;
        }
      } else {
        debugPrint('[ClientProfileService] Error al subir a Cloudinary: $responseBody');
      }
    } catch (e) {
      debugPrint('[ClientProfileService] Excepción al subir foto: $e');
    }
    return null;
  }

  Future<void> _syncPhotoWithBackend(String photoUrl, {String? clientId}) async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 4);

      final targetId = clientId?.isNotEmpty == true ? clientId : null;
      if (targetId != null) {
        final uri = Uri.parse('$backendBaseUrl/clientes/$targetId');
        final req = await client.putUrl(uri);
        req.headers.contentType = ContentType.json;
        req.write(jsonEncode({'foto': photoUrl}));
        final res = await req.close();
        debugPrint('[ClientProfileService] Backend status: ${res.statusCode}');
      }
      client.close();
    } catch (e) {
      debugPrint('[ClientProfileService] Nota backend sync: $e');
    }
  }
}

