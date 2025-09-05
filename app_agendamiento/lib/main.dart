// lib/main.dart

import 'package:app_agendamiento/screens/auth_gate.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() async {
  // Asegúrate de que los widgets de Flutter estén listos
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializa Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDateFormatting('es_ES', null);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false, // Quita la cinta de "Debug"
      title: 'App de Agendamiento',
      theme: ThemeData(
        primarySwatch: Colors.deepPurple, // Un color base para la app
      ),
      // AuthGate será ahora el punto de entrada de la app.
      home: const AuthGate(),
    );
  }
}
