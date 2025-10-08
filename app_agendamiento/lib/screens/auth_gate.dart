// lib/screens/auth_gate.dart

import 'package:agend_app/screens/home_screen.dart';
import 'package:agend_app/screens/login_or_register_screen.dart';
import 'package:agend_app/services/fcm_service.dart'; // NUEVO IMPORT
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatefulWidget {
  // MODIFICADO a StatefulWidget
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // NUEVA CLASE State

  @override
  void initState() {
    super.initState();
    // Cuando el AuthGate se inicie, verificamos si el usuario está logueado
    // para inicializar las notificaciones y guardar su token.
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null && !user.isAnonymous) {
        // No guardamos token para invitados
        FcmService().initNotifications();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return const HomeScreen();
          } else {
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}
