// lib/screens/register_screen.dart

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';

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
            'name': _nameController.text
                .trim(), // Corregido a 'name' para consistencia
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
    final isDarkMode = theme.brightness == Brightness.dark;

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
                    style: GoogleFonts.lato(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '¡Completa tus datos para empezar!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campos de texto
                  _buildTextField(
                    controller: _nameController,
                    label: 'Nombre Completo',
                    icon: Icons.person_outline,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    isDarkMode: isDarkMode,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),
                  _buildTextField(
                    controller: _confirmPasswordController,
                    label: 'Confirmar Contraseña',
                    icon: Icons.lock_outline,
                    obscureText: true,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 24),

                  // Mensaje de Error
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: Text(
                        _errorMessage,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.lato(
                          color: theme.colorScheme.error,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),

                  // Botón de Registrarse
                  _buildSignUpButton(theme),
                  const SizedBox(height: 24),

                  // Opción de Iniciar Sesión
                  _buildLoginNow(theme),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- Widgets Refactorizados ---

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required bool isDarkMode,
    TextInputType? keyboardType,
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: theme.colorScheme.secondary),
        filled: true,
        fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
        ),
      ),
      style: GoogleFonts.lato(),
    );
  }

  Widget _buildSignUpButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signUp,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: theme.colorScheme.primary,
        foregroundColor: theme.colorScheme.onPrimary,
      ),
      child: _isLoading
          ? const SizedBox(
              height: 24,
              width: 24,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 3,
              ),
            )
          : Text(
              'Registrarse',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildLoginNow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿Ya eres miembro?',
          style: GoogleFonts.lato(color: theme.colorScheme.secondary),
        ),
        TextButton(
          onPressed: widget.showLoginPage,
          child: Text(
            'Inicia sesión',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }
}
