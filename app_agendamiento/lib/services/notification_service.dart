// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  // --- Inicialización según la plataforma ---
  Future<void> init() async {
    if (kIsWeb) {
      // Lógica para WEB con Firebase Cloud Messaging
      await _initFCMWeb();
    } else {
      // Lógica para Android/iOS con notificaciones locales
      await _initLocalNotifications();
    }
  }

  // --- Firebase Cloud Messaging para WEB ---
  Future<void> _initFCMWeb() async {
    // Solicitar permisos
    NotificationSettings settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (settings.authorizationStatus == AuthorizationStatus.authorized) {
      print('✅ Permisos de notificación concedidos');

      // Obtener token FCM
      String? token = await _messaging.getToken(
        vapidKey:
            'BC9aDR_aWxsT-ANx02vtIh9XzPNQnav4zU-KH6kDDjfdxgWkMR7ZH3bUnbwh0tHXt8i-rsFj5pTSJNaZGUaEX9o',
      );

      if (token != null) {
        print('📱 FCM Token Web: $token');
        // Aquí puedes guardar el token en tu backend si lo necesitas
      }

      // Escuchar notificaciones cuando la app está en primer plano
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('🔔 Notificación recibida en primer plano');
        print('Título: ${message.notification?.title}');
        print('Cuerpo: ${message.notification?.body}');

        // Mostrar la notificación en el navegador
        if (message.notification != null) {
          _showWebNotification(
            title: message.notification!.title ?? 'Nueva notificación',
            body: message.notification!.body ?? '',
          );
        }
      });

      // Manejar cuando el usuario hace clic en la notificación
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('🖱️ Usuario hizo clic en la notificación');
        // Aquí puedes navegar a una pantalla específica
      });
    } else if (settings.authorizationStatus == AuthorizationStatus.denied) {
      print('❌ Permisos de notificación denegados');
    } else {
      print('⚠️ Permisos de notificación no determinados');
    }
  }

  // Método auxiliar para mostrar notificaciones web
  void _showWebNotification({required String title, required String body}) {
    // Las notificaciones web se manejan automáticamente por el Service Worker
    // Este método es principalmente informativo
    print('💬 Mostrando notificación web: $title - $body');
  }

  // --- Notificaciones Locales para Android/iOS ---
  Future<void> _initLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
    print('✅ Notificaciones locales inicializadas (Android/iOS)');
  }

  // --- Canales de Notificación ---
  // Canal para recordatorios
  static const String _recordatoriosChannelId = 'recordatorios_channel';
  static const String _recordatoriosChannelName = 'Recordatorios de Citas';
  static const String _recordatoriosChannelDesc =
      'Notificaciones de recordatorio de citas próximas';

  // Canal para confirmaciones
  static const String _confirmacionesChannelId = 'confirmaciones_channel';
  static const String _confirmacionesChannelName = 'Confirmaciones';
  static const String _confirmacionesChannelDesc =
      'Confirmaciones de citas agendadas';

  // Canal para cancelaciones
  static const String _cancelacionesChannelId = 'cancelaciones_channel';
  static const String _cancelacionesChannelName = 'Avisos de Cancelación';
  static const String _cancelacionesChannelDesc =
      'Notificaciones de citas canceladas';

  // Método para mostrar notificación de recordatorio
  Future<void> showReminderNotification({
    required String title,
    required String body,
  }) async {
    await _showNotificationWithChannel(
      title: title,
      body: body,
      channelId: _recordatoriosChannelId,
      channelName: _recordatoriosChannelName,
      channelDescription: _recordatoriosChannelDesc,
    );
  }

  // Método para mostrar notificación de confirmación
  Future<void> showConfirmationNotification({
    required String title,
    required String body,
  }) async {
    await _showNotificationWithChannel(
      title: title,
      body: body,
      channelId: _confirmacionesChannelId,
      channelName: _confirmacionesChannelName,
      channelDescription: _confirmacionesChannelDesc,
    );
  }

  // Método para mostrar notificación de cancelación
  Future<void> showCancellationNotification({
    required String title,
    required String body,
  }) async {
    await _showNotificationWithChannel(
      title: title,
      body: body,
      channelId: _cancelacionesChannelId,
      channelName: _cancelacionesChannelName,
      channelDescription: _cancelacionesChannelDesc,
    );
  }

  // Método interno que maneja los canales
  Future<void> _showNotificationWithChannel({
    required String title,
    required String body,
    required String channelId,
    required String channelName,
    required String channelDescription,
  }) async {
    if (kIsWeb) {
      // En web, las notificaciones se manejan con FCM
      print('ℹ️ Las notificaciones web se manejan automáticamente por FCM');
      return;
    }

    // Para Android/iOS
    final AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
          channelId,
          channelName,
          channelDescription: channelDescription,
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
        );

    final NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      DateTime.now().millisecondsSinceEpoch ~/
          1000, // ID único basado en timestamp
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // Método genérico (mantiene compatibilidad con código existente)
  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    await showReminderNotification(title: title, body: body);
  }

  // --- Envío de Correos (sin cambios) ---
  static const String _scriptUrl =
      'https://us-central1-appagendamiento-ddbd0.cloudfunctions.net/sendEmail';

  static Future<void> sendEmail({
    required String to,
    required String subject,
    required String htmlBody,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_scriptUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'to': to, 'subject': subject, 'htmlBody': htmlBody}),
      );
      print('✉️ Respuesta del servicio de correo: ${response.body}');
    } catch (e) {
      print('❌ Error al enviar correo: $e');
    }
  }
}
