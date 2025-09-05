// lib/screens/auth_gate.dart

import 'package:app_agendamiento/screens/home_screen.dart';
import 'package:app_agendamiento/screens/login_or_register_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        // StreamBuilder escucha los cambios en el estado de autenticación.
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Si el snapshot tiene datos, significa que el usuario está logueado.
          if (snapshot.hasData) {
            return const HomeScreen();
          }
          // Si no, mostramos el flujo de login/registro.
          else {
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}
