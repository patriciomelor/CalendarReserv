// lib/services/notification_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
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
      print('Respuesta del servicio de correo: ${response.body}');
    } catch (e) {
      print('Error al enviar correo: $e');
    }
  }
}
