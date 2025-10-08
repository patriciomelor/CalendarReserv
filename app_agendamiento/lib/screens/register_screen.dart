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

  Future<void> signUp() async {
    if (_isLoading) return;

    if (_passwordController.text.trim() !=
        _confirmPasswordController.text.trim()) {
      setState(() => _errorMessage = 'Las contraseñas no coinciden.');
      return;
    }
    if (_nameController.text.trim().isEmpty) {
      setState(() => _errorMessage = 'Por favor, ingresa tu nombre.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
            'nombre': _nameController.text.trim(),
            'email': _emailController.text.trim(),
            'rol': 'cliente',
          });
    } on FirebaseAuthException catch (e) {
      setState(() {
        if (e.code == 'weak-password') {
          _errorMessage = 'La contraseña es muy débil.';
        } else if (e.code == 'email-already-in-use') {
          _errorMessage = 'Este correo ya está en uso.';
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
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Crea tu Cuenta',
                  style: GoogleFonts.poppins(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '¡Completa tus datos para registrarte!',
                  style: GoogleFonts.poppins(fontSize: 18, color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),
                _buildTextField(_nameController, 'Nombre Completo'),
                const SizedBox(height: 20),
                _buildTextField(_emailController, 'Correo Electrónico', isEmail: true),
                const SizedBox(height: 20),
                _buildTextField(_passwordController, 'Contraseña', isPassword: true),
                const SizedBox(height: 20),
                _buildTextField(_confirmPasswordController, 'Confirmar Contraseña', isPassword: true),
                const SizedBox(height: 20),
                if (_errorMessage.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10.0),
                    child: Text(
                      _errorMessage,
                      style: GoogleFonts.poppins(color: Colors.red, fontSize: 14),
                    ),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : signUp,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.all(20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      backgroundColor: Colors.blueAccent,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(
                            color: Colors.white,
                          )
                        : Text(
                            'Registrarse',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 25),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('¿Ya eres miembro?', style: GoogleFonts.poppins()),
                    TextButton(
                      onPressed: widget.showLoginPage,
                      child: Text(
                        'Inicia sesión',
                        style: GoogleFonts.poppins(
                          color: Colors.blueAccent,
                          fontWeight: FontWeight.bold,
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
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, {bool isEmail = false, bool isPassword = false}) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(isEmail ? Icons.email_outlined : isPassword? Icons.lock_outline : Icons.person_outline),
      ),
      keyboardType: isEmail ? TextInputType.emailAddress : TextInputType.text,
    );
  }
}
