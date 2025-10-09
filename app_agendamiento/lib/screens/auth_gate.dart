// lib/screens/auth_gate.dart

import 'package:agend_app/screens/home_screen.dart';
import 'package:agend_app/screens/login_or_register_screen.dart';
import 'package:agend_app/services/fcm_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Si hay un usuario (registrado o anónimo), inicializa las notificaciones
          if (snapshot.hasData) {
            return FutureBuilder(
              // Llama a initNotifications para cualquier tipo de usuario
              future: FcmService().initNotifications(),
              builder: (context, snapshot) {
                // Muestra un indicador de carga mientras se inicializa FCM
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                // Una vez completado, muestra la pantalla de inicio
                return const HomeScreen();
              },
            );
          } else {
            // Si no hay usuario, muestra la pantalla de login/registro
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}