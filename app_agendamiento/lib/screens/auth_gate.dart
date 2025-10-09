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
          if (snapshot.hasData) {
            if (snapshot.data!.isAnonymous) {
              return const HomeScreen();
            }
            return FutureBuilder(
              future: FcmService().initNotifications(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                return const HomeScreen();
              },
            );
          } else {
            return const LoginOrRegisterScreen();
          }
        },
      ),
    );
  }
}