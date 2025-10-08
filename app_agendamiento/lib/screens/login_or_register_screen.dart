// lib/screens/login_or_register_screen.dart

import 'package:agend_app/screens/register_screen.dart';
import 'package:agend_app/screens/select_salon_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
      // Autentica al usuario como anónimo
      await FirebaseAuth.instance.signInAnonymously();
      // Navega a la pantalla de selección de salón
      Navigator.pushReplacement( // Usamos pushReplacement para que no pueda volver aquí
        context,
        MaterialPageRoute(builder: (context) => const SelectSalonScreen()),
      );
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
                  // Logo o Título
                  Text(
                    '¡Hola de Nuevo!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Bienvenido de vuelta, te hemos extrañado.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.lato(
                      fontSize: 18,
                      color: theme.colorScheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Campo de Email
                  _buildTextField(
                    controller: _emailController,
                    label: 'Correo Electrónico',
                    icon: Icons.email_outlined,
                    isDarkMode: isDarkMode,
                  ),
                  const SizedBox(height: 20),

                  // Campo de Contraseña
                  _buildTextField(
                    controller: _passwordController,
                    label: 'Contraseña',
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

                  // Botón de Iniciar Sesión
                  _buildSignInButton(theme),
                  const SizedBox(height: 24),

                  // Opción de Registrarse
                  _buildRegisterNow(theme),
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
                  _buildGuestButton(theme),
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
  }) {
    final theme = Theme.of(context);
    return TextField(
      controller: controller,
      obscureText: obscureText,
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

  Widget _buildSignInButton(ThemeData theme) {
    return ElevatedButton(
      onPressed: _isLoading ? null : _signIn,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
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
              'Iniciar Sesión',
              style: GoogleFonts.lato(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Widget _buildRegisterNow(ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          '¿No eres miembro?',
          style: GoogleFonts.lato(color: theme.colorScheme.secondary),
        ),
        TextButton(
          onPressed: widget.showRegisterPage,
          child: Text(
            'Regístrate ahora',
            style: GoogleFonts.lato(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGuestButton(ThemeData theme) {
    return OutlinedButton.icon(
      onPressed: widget.onGuestContinue,
      icon: const Icon(Icons.person_outline),
      label: Text(
        'Continuar como invitado',
        style: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        side: BorderSide(color: theme.colorScheme.primary),
        foregroundColor: theme.colorScheme.primary,
      ),
    );
  }
}