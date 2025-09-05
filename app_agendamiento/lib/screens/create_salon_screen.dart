// lib/screens/create_salon_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateSalonScreen extends StatefulWidget {
  const CreateSalonScreen({super.key});

  @override
  State<CreateSalonScreen> createState() => _CreateSalonScreenState();
}

class _CreateSalonScreenState extends State<CreateSalonScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controladores para los datos del salón
  final _salonNameController = TextEditingController();
  final _salonAddressController = TextEditingController();
  final _salonPhoneController = TextEditingController();

  // Controladores para los datos del administrador del salón
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void dispose() {
    _salonNameController.dispose();
    _salonAddressController.dispose();
    _salonPhoneController.dispose();
    _adminNameController.dispose();
    _adminEmailController.dispose();
    _adminPasswordController.dispose();
    super.dispose();
  }

  Future<void> _createSalonAndAdmin() async {
    if (!_formKey.currentState!.validate()) {
      return; // Si el formulario no es válido, no hacemos nada.
    }

    setState(() => _isLoading = true);

    try {
      // Para crear un usuario, necesitamos una instancia secundaria de Firebase
      // para no desloguear al Súper Admin actual.
      final tempApp = await Firebase.initializeApp(
        name: 'tempAdminCreation',
        options: Firebase.app().options,
      );
      final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

      // 1. Crear el nuevo usuario administrador en Firebase Auth
      UserCredential userCredential = await tempAuth
          .createUserWithEmailAndPassword(
            email: _adminEmailController.text.trim(),
            password: _adminPasswordController.text.trim(),
          );
      final adminUid = userCredential.user!.uid;
      await tempApp.delete(); // Cerramos la instancia temporal

      // 2. Crear el documento del salón en Firestore
      final salonDocRef = await FirebaseFirestore.instance
          .collection('salones')
          .add({
            'nombre': _salonNameController.text.trim(),
            'direccion': _salonAddressController.text.trim(),
            'telefono': _salonPhoneController.text.trim(),
            'adminUid': adminUid, // Guardamos referencia al admin
            // Valores por defecto para la configuración del salón
            'openingTime': '09:00',
            'closingTime': '18:00',
            'workDays': [1, 2, 3, 4, 5], // Lunes a Viernes
          });

      // 3. Crear el documento del usuario admin en Firestore, vinculándolo al salón
      await FirebaseFirestore.instance.collection('users').doc(adminUid).set({
        'nombre': _adminNameController.text.trim(),
        'email': _adminEmailController.text.trim(),
        'rol': 'admin',
        'salonId': salonDocRef.id, // Vínculo hacia el salón que administra
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Salón y administrador creados con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error de autenticación: ${e.message}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Ocurrió un error: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Crear Nuevo Cliente'),
        backgroundColor: const Color(0xFFB71C1C),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Datos del Salón',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              TextFormField(
                controller: _salonNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Salón',
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _salonAddressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _salonPhoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 30),
              const Text(
                'Datos del Administrador del Salón',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Divider(),
              TextFormField(
                controller: _adminNameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Representante',
                ),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              TextFormField(
                controller: _adminEmailController,
                decoration: const InputDecoration(labelText: 'Email de Acceso'),
                keyboardType: TextInputType.emailAddress,
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Email inválido'
                    : null,
              ),
              TextFormField(
                controller: _adminPasswordController,
                decoration: const InputDecoration(
                  labelText: 'Contraseña Provisional',
                ),
                obscureText: true,
                validator: (value) =>
                    (value?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createSalonAndAdmin,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Crear Cliente'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFB71C1C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
