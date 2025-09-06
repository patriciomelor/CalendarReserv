// lib/main.dart

import 'package:app_agendamiento/screens/auth_gate.dart';
import 'package:app_agendamiento/screens/public_booking_page.dart'; // NUEVO IMPORT
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'App de Agendamiento',
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
      ),
      themeMode: ThemeMode.system,

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
