// lib/screens/login_or_register_screen.dart

import 'package:agend_app/screens/register_screen.dart';
import 'package:agend_app/screens/select_salon_screen.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:agend_app/widgets/custom_text_field.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class LoginOrRegisterScreen extends StatefulWidget {
  const LoginOrRegisterScreen({super.key});

  @override
  State<LoginOrRegisterScreen> createState() => _LoginOrRegisterScreenState();
}

class _LoginOrRegisterScreenState extends State<LoginOrRegisterScreen> {
  bool showLoginPage = true;

  void togglePages() {
    setState(() {
      showLoginPage = !showLoginPage;
    });
  }

  void _continueAsGuest() async {
    try {
      // Autentica al usuario como anónimo. El AuthGate se encargará de la navegación.
      await FirebaseAuth.instance.signInAnonymously();
    } catch (e) {
      // Manejo de errores en caso de que el inicio de sesión anónimo falle
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al continuar como invitado: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (showLoginPage) {
      return LoginScreen(
        showRegisterPage: togglePages,
        onGuestContinue: _continueAsGuest,
      );
    } else {
      return RegisterScreen(
        showLoginPage: togglePages,
        onGuestContinue: _continueAsGuest,
      );
    }
  }
}

// Widget de Login separado para mantener el código organizado
class LoginScreen extends StatefulWidget {
  final VoidCallback showRegisterPage;
  final VoidCallback onGuestContinue;

  const LoginScreen({
    super.key,
    required this.showRegisterPage,
    required this.onGuestContinue,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signIn() async {
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    // Validar que los campos no estén vacíos
    if (_emailController.text.trim().isEmpty ||
        _passwordController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Por favor, ingresa correo y contraseña.';
        _isLoading = false;
      });
      return;
    }

    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      // La navegación se manejará automáticamente por el AuthGate
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'user-not-found' || e.code == 'wrong-password') {
          _errorMessage = 'Correo o contraseña incorrectos.';
        } else {
          _errorMessage = 'Ocurrió un error. Inténtalo de nuevo.';
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Logo o Título
                  Text(
                    '¡Hola de Nuevo!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido de vuelta, te hemos extrañado.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campo de Email
                  CustomTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),

                  // Campo de Contraseña
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),

                  // Mensaje de Error
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Botón de Iniciar Sesión
                  CustomButton(
                    text: 'Iniciar Sesión',
                    onPressed: _isLoading ? () {} : _signIn,
                  ),
                  const SizedBox(height: 24),

                  // Opción de Registrarse
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿No eres miembro?',
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                      TextButton(
                        onPressed: widget.showRegisterPage,
                        child: Text(
                          'Regístrate ahora',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Divisor
                  const Row(
                    children: [
                      Expanded(child: Divider(thickness: 1)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12.0),
                        child: Text('O'),
                      ),
                      Expanded(child: Divider(thickness: 1)),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Botón de Invitado
                  CustomButton(
                    text: 'Continuar como invitado',
                    onPressed: widget.onGuestContinue,
                    icon: Icons.person_outline,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}