// lib/screens/login_or_register_screen.dart

import 'package:app_agendamiento/screens/login_screen.dart';
import 'package:app_agendamiento/screens/register_screen.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  // Inicialmente, mostramos la página de login
  bool showLoginPage = true;

  // Método para cambiar entre las dos páginas
  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(showRegisterPage: togglePages);
    } else {
      return RegisterScreen(showLoginPage: togglePages);
    }
  }
}
