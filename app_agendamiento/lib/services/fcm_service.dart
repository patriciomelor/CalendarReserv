// lib/services/fcm_service.dart

import 'package:app_agendamiento/services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Debe ser una función de nivel superior según la documentación de Firebase
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Si quieres hacer algo con el mensaje en segundo plano, hazlo aquí
  print("Handling a background message: ${message.messageId}");
}

class FcmService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> initNotifications() async {
    // Solicitar permisos para notificaciones
    await _firebaseMessaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    // Obtener el token de FCM
    final token = await _firebaseMessaging.getToken();
    print("FCM Token: $token");
    await saveTokenToDatabase(token);

    // Escuchar mensajes en primer plano
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      print('Got a message whilst in the foreground!');
      print('Message data: ${message.data}');

      if (message.notification != null) {
        print('Message also contained a notification: ${message.notification}');
        NotificationService().showNotification(
          title: message.notification!.title ?? '',
          body: message.notification!.body ?? '',
        );
      }
    });

    // Manejador de mensajes en segundo plano
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  Future<void> saveTokenToDatabase(String? token) async {
    if (token == null) return;

    String? userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId != null) {
      try {
        await _firestore.collection("users").doc(userId).update({
          "fcmToken": token,
        });
        print("FCM token saved to database for user $userId");
      } catch (e) {
        print("Error saving FCM token: $e");
        // Si el documento no existe, créalo.
        if (e is FirebaseException && e.code == 'not-found') {
          await _firestore.collection("users").doc(userId).set({
            "fcmToken": token,
          }, SetOptions(merge: true));
          print("FCM token document created and saved for user $userId");
        }
      }
    } else {
      print("User not logged in, FCM token not saved.");
    }
  }
}
