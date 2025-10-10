// lib/screens/register_screen.dart

import 'package:agend_app/widgets/custom_button.dart';
import 'package:agend_app/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class RegisterScreen extends StatefulWidget {
  final VoidCallback showLoginPage;
  final VoidCallback? onGuestContinue;

  const RegisterScreen({
    super.key,
    required this.showLoginPage,
    this.onGuestContinue,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _errorMessage = '';
  bool _isLoading = false;

  Future<void> _signUp() async {
    if (_isLoading) return;

    // Validaciones de campos
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor, ingresa tu nombre.');
      return;
    }
    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      // Crear usuario
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Guardar datos adicionales en Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'rol': 'customer', // Rol por defecto
        'createdAt': FieldValue.serverTimestamp(), // Fecha de creación
      });

      // La navegación la maneja AuthGate
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'La contraseña debe tener al menos 6 caracteres.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Este correo electrónico ya está en uso.';
        } else {
          _errorMessage = 'Ocurrió un error. Verifica tus datos.';
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  // Título
                  Text(
                    'Crea tu Cuenta',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Completa tus datos para empezar!',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campos de texto
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nombre Completo',
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                  ),
                  const SizedBox(height: 20),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Contraseña',
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

                  // Botón de Registrarse
                  CustomButton(
                    text: 'Registrarse',
                    onPressed: _isLoading ? () {} : _signUp,
                  ),
                  const SizedBox(height: 24),

                  // Opción de Iniciar Sesión
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '¿Ya eres miembro?',
                        style: TextStyle(color: theme.colorScheme.secondary),
                      ),
                      TextButton(
                        onPressed: widget.showLoginPage,
                        child: Text(
                          'Inicia sesión',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ],
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
