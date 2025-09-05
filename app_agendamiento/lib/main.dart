// lib/main.dart

import 'package:app_agendamiento/screens/auth_gate.dart';
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

      // TEMA PARA MODO CLARO (EL QUE YA TENÍAMOS, PERO MÁS DETALLADO)
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: Colors.grey[100], // Fondo un poco más suave
        appBarTheme: const AppBarTheme(
          foregroundColor: Colors.white, // Color de texto e íconos en AppBar
        ),
      ),

      // TEMA PARA MODO OSCURO
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepPurple,
        scaffoldBackgroundColor: const Color(
          0xFF121212,
        ), // Fondo oscuro estándar
        cardColor: const Color(0xFF1E1E1E), // Color de las tarjetas
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF1E1E1E), // AppBar un poco más oscura
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            foregroundColor: Colors.white, // Color del texto de los botones
          ),
        ),
        // Puedes seguir personalizando más colores y estilos aquí
      ),

      // Esto le dice a la app que use el tema del sistema (claro u oscuro)
      themeMode: ThemeMode.system,

      home: const AuthGate(),
    );
  }
}
