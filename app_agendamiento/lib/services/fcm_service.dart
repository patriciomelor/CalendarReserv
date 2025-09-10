// lib/services/fcm_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;

  Future<void> initNotifications() async {
    // Solicitar permiso para recibir notificaciones
    await _firebaseMessaging.requestPermission();

    // Obtener el token FCM del dispositivo
    final fcmToken = await _firebaseMessaging.getToken();
    print('FCM Token: $fcmToken');

    // Guardar el token en el documento del usuario actual en Firestore
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null && fcmToken != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid)
          .update({'fcmToken': fcmToken});
    }

    // (Opcional) Escuchar mensajes mientras la app está en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('¡Recibido un mensaje en primer plano!');
      print('Mensaje: ${message.notification?.title}');
    });
  }
}
