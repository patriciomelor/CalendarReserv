// lib/services/notification_service.dart

import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // --- Lógica para Notificaciones Locales ---

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> showNotification({
    required String title,
    required String body,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'your_channel_id', // ID del canal
      'your_channel_name', // Nombre del canal
      channelDescription: 'your_channel_description', // Descripción
      importance: Importance.max,
      priority: Priority.high,
      showWhen: false,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0, // ID de la notificación
      title,
      body,
      platformChannelSpecifics,
    );
  }

  // --- Lógica para Envío de Correos (existente) ---

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
      // print('Respuesta del servicio de correo: ${response.body}');
    } catch (e) {
      // print('Error al enviar correo: $e');
    }
  }
}