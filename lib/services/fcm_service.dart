import 'dart:async';
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'auth_service.dart';
import 'notificacion_service.dart';
import '../screens/shared/notifications_screen.dart';

/// Handler de mensajes en segundo plano (requiere ser función de nivel superior con @pragma).
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  try {
    // Si Firebase no está inicializado en el isolate de fondo, inicializarlo
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp();
    }
    debugPrint('[FCM Background] Mensaje recibido: ${message.messageId} - ${message.notification?.title}');
  } catch (e) {
    debugPrint('[FCM Background] Error en background handler: $e');
  }
}

class FcmService {
  static final FcmService _instance = FcmService._internal();
  factory FcmService() => _instance;
  FcmService._internal();

  final NotificacionService _notificacionService = NotificacionService();
  bool _isInitialized = false;
  bool _isFirebaseAvailable = false;
  String? _lastToken;

  /// GlobalKey para permitir navegación y visualización de alertas desde cualquier punto
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
      GlobalKey<ScaffoldMessengerState>();

  bool get isFirebaseAvailable => _isFirebaseAvailable;

  /// Inicialización centralizada de Firebase y FCM
  Future<void> inicializar() async {
    if (_isInitialized) return;

    try {
      // 1. Inicializar Firebase Core
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }
      _isFirebaseAvailable = true;
      debugPrint('🔥 [FCM] Firebase Core inicializado correctamente.');

      // 2. Configurar Background Handler
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      // 3. Solicitar permisos (Android 13+ y iOS)
      await solicitarPermisos();

      // 4. Configurar presentación en primer plano (iOS / Android)
      await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );

      // 5. Escuchar mensajes en primer plano (Foreground)
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

      // 6. Escuchar cuando el usuario toca una notificación en segundo plano
      FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

      // 7. Verificar si la app se abrió desde estado cerrado por una notificación
      final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        debugPrint('📩 [FCM] App abierta desde notificación en estado cerrado: ${initialMessage.data}');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleNotificationTap(initialMessage.data);
        });
      }

      // 8. Escuchar renovación automática del token FCM
      FirebaseMessaging.instance.onTokenRefresh.listen((nuevoToken) async {
        debugPrint('🔄 [FCM] Token FCM renovado.');
        _lastToken = nuevoToken;
        await _registrarTokenEnServidor(nuevoToken);
      });

      _isInitialized = true;
    } catch (e) {
      _isFirebaseAvailable = false;
      debugPrint(
        '⚠️ [FCM] No se pudo inicializar Firebase en este entorno. '
        'Asegúrate de colocar google-services.json en android/app/ para activar notificaciones push reales.\nDetalle: $e',
      );
    }
  }

  /// Solicita permisos de notificación al usuario
  Future<bool> solicitarPermisos() async {
    if (!_isFirebaseAvailable) return false;
    try {
      final settings = await FirebaseMessaging.instance.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      final autorizado = settings.authorizationStatus == AuthorizationStatus.authorized ||
          settings.authorizationStatus == AuthorizationStatus.provisional;

      debugPrint('🔔 [FCM] Estado de permisos: ${settings.authorizationStatus}');
      return autorizado;
    } catch (e) {
      debugPrint('⚠️ [FCM] Error al solicitar permisos: $e');
      return false;
    }
  }

  /// Obtiene el token FCM actual del dispositivo
  Future<String?> obtenerToken() async {
    if (!_isFirebaseAvailable) return null;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      _lastToken = token;
      return token;
    } catch (e) {
      debugPrint('⚠️ [FCM] Error al obtener token FCM: $e');
      return null;
    }
  }

  /// Registra el token FCM en el backend si el usuario está autenticado
  Future<void> registrarDispositivo() async {
    if (!_isFirebaseAvailable) return;

    final tieneSesion = await AuthService.tieneSesion();
    if (!tieneSesion) {
      debugPrint('ℹ️ [FCM] Registro omitido: no hay sesión activa.');
      return;
    }

    final token = await obtenerToken();
    if (token == null || token.trim().isEmpty) {
      debugPrint('⚠️ [FCM] No se pudo obtener el token para registrar en el backend.');
      return;
    }

    await _registrarTokenEnServidor(token);
  }

  /// Envía el token al backend y lo almacena localmente para evitar duplicados innecesarios
  Future<void> _registrarTokenEnServidor(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ultimoRegistrado = prefs.getString('fcm_token_registrado');

      // Si ya está registrado el mismo token, no repetir llamada innecesaria
      if (ultimoRegistrado == token) {
        return;
      }

      final plataforma = kIsWeb
          ? 'WEB'
          : Platform.isIOS
              ? 'IOS'
              : 'FLUTTER_ANDROID';

      await _notificacionService.registrarDispositivo(
        token: token,
        plataforma: plataforma,
      );

      await prefs.setString('fcm_token_registrado', token);
      debugPrint('✅ [FCM] Dispositivo registrado exitosamente en el backend.');
    } catch (e) {
      debugPrint('⚠️ [FCM] No se pudo registrar el dispositivo en el backend: $e');
    }
  }

  /// Desvincula el dispositivo al cerrar sesión
  Future<void> desvincularDispositivo() async {
    if (!_isFirebaseAvailable) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = _lastToken ?? prefs.getString('fcm_token_registrado') ?? await obtenerToken();

      if (token != null && token.isNotEmpty) {
        await _notificacionService.desvincularDispositivo(token: token);
      }
      await prefs.remove('fcm_token_registrado');
      debugPrint('✅ [FCM] Token desvinculado del backend al cerrar sesión.');
    } catch (e) {
      debugPrint('⚠️ [FCM] Error al desvincular dispositivo: $e');
    }
  }

  /// Manejo de mensajes cuando la app está abierta en primer plano (Foreground)
  void _handleForegroundMessage(RemoteMessage message) {
    debugPrint('🔔 [FCM Foreground] Mensaje recibido: ${message.notification?.title} - ${message.notification?.body}');

    final titulo = message.notification?.title ?? 'Nueva notificación';
    final cuerpo = message.notification?.body ?? '';

    // Mostrar banner interactivo en la app usando ScaffoldMessenger
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger != null) {
      messenger.showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 5),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          backgroundColor: const Color(0xFF0B3B4A),
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Color(0xFFFF8A00),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_active, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (cuerpo.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        cuerpo,
                        style: const TextStyle(fontSize: 12.5, color: Colors.white70),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          action: SnackBarAction(
            label: 'VER',
            textColor: const Color(0xFFFF8A00),
            onPressed: () {
              _handleNotificationTap(message.data);
            },
          ),
        ),
      );
    }
  }

  /// Manejo de toque en notificación cuando la app estaba en segundo plano
  void _handleMessageOpenedApp(RemoteMessage message) {
    debugPrint('👆 [FCM] Notificación pulsada desde segundo plano: ${message.data}');
    _handleNotificationTap(message.data);
  }

  /// Enrutamiento inteligente según los datos de la notificación y el rol del usuario
  void _handleNotificationTap(Map<String, dynamic> data) async {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final tipo = data['tipo']?.toString().toUpperCase() ?? 'SISTEMA';
    debugPrint('🧭 [FCM] Procesando navegación para tipo: $tipo con data: $data');

    // Siempre permitir ir a la pantalla de historial de notificaciones
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ),
    );
  }
}

