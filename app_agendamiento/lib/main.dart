// lib/main.dart

import 'package:agend_app/firebase_options.dart';
import 'package:agend_app/screens/public_booking_page.dart';
import 'package:agend_app/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:agend_app/screens/auth_gate.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'theme.dart'; // Importa tu tema

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);
  await NotificationService()
      .init(); // Inicializa el servicio de notificaciones locales

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Agendamiento',
      theme: appTheme, // Usa el tema global
      // MODIFICADO: Usamos onGenerateRoute para manejar URLs dinámicas
      onGenerateRoute: (settings) {
        // Ejemplo de URL: /book/salonId/professionalId
        if (settings.name != null && settings.name!.startsWith('/book/')) {
          final parts = settings.name!.split('/');
          if (parts.length == 4) {
            // Esperamos /book/salonId/professionalId
            final salonId = parts[2];
            final professionalId = parts[3];
            return MaterialPageRoute(
              builder: (context) => PublicBookingPage(
                salonId: salonId,
                professionalId: professionalId,
              ),
            );
          }
        }
        // Si la URL no coincide, mostramos el flujo normal de autenticación
        return MaterialPageRoute(builder: (context) => const AuthGate());
      },
      // home: const AuthGate(), // 'home' y 'onGenerateRoute' no pueden usarse juntos
    );
  }
}
