// lib/screens/create_salon_screen.dart

import 'package:agend_app/services/notification_service.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CreateSalonScreen extends StatefulWidget {
  final DocumentSnapshot? salon;

  const CreateSalonScreen({super.key, this.salon});

  @override
  State<CreateSalonScreen> createState() => _CreateSalonScreenState();
}

class _CreateSalonScreenState extends State<CreateSalonScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  late bool _isEditing;

  // Controladores para los datos del salón
  final _salonNameController = TextEditingController();
  final _salonAddressController = TextEditingController();
  final _salonPhoneController = TextEditingController();

  // Controladores para los datos del administrador del salón
  final _adminNameController = TextEditingController();
  final _adminEmailController = TextEditingController();
  final _adminPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _isEditing = widget.salon != null;

    if (_isEditing) {
      final data = widget.salon!.data() as Map<String, dynamic>;
      _salonNameController.text = data['nombre'] ?? '';
      _salonAddressController.text = data['direccion'] ?? '';
      _salonPhoneController.text = data['telefono'] ?? '';

      // Cargamos los datos del admin, pero los campos de auth no serán editables
      _loadAdminData(data['adminUid']);
    }
  }

  Future<void> _loadAdminData(String? adminUid) async {
    if (adminUid == null) return;
    final adminDoc = await FirebaseFirestore.instance.collection('users').doc(adminUid).get();
    if (adminDoc.exists) {
      final adminData = adminDoc.data()!;
      _adminNameController.text = adminData['nombre'] ?? '';
      _adminEmailController.text = adminData['email'] ?? '';
    }
  }

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

  Future<void> _saveSalon() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isEditing) {
        // Lógica para actualizar un salón existente
        await FirebaseFirestore.instance.collection('salones').doc(widget.salon!.id).update({
          'nombre': _salonNameController.text.trim(),
          'direccion': _salonAddressController.text.trim(),
          'telefono': _salonPhoneController.text.trim(),
        });

        // Actualizar el nombre y email del admin si han cambiado
        final adminUid = (widget.salon!.data() as Map<String, dynamic>)['adminUid'];
        if (adminUid != null) {
          await FirebaseFirestore.instance.collection('users').doc(adminUid).update({
            'nombre': _adminNameController.text.trim(),
            'email': _adminEmailController.text.trim(),
          });
        }

      } else {
        // Lógica para crear un nuevo salón y admin
        final tempApp = await Firebase.initializeApp(
          name: 'tempAdminCreation',
          options: Firebase.app().options,
        );
        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

        UserCredential userCredential = await tempAuth.createUserWithEmailAndPassword(
          email: _adminEmailController.text.trim(),
          password: _adminPasswordController.text.trim(),
        );
        final adminUid = userCredential.user!.uid;
        await tempApp.delete();

        final salonDocRef = await FirebaseFirestore.instance.collection('salones').add({
          'nombre': _salonNameController.text.trim(),
          'direccion': _salonAddressController.text.trim(),
          'telefono': _salonPhoneController.text.trim(),
          'adminUid': adminUid,
          'openingTime': '09:00',
          'closingTime': '18:00',
          'workDays': [1, 2, 3, 4, 5],
        });

        await FirebaseFirestore.instance.collection('users').doc(adminUid).set({
          'nombre': _adminNameController.text.trim(),
          'email': _adminEmailController.text.trim(),
          'rol': 'admin',
          'salonId': salonDocRef.id,
        });

        await NotificationService.sendEmail(
          to: _adminEmailController.text.trim(),
          subject: '¡Bienvenido! Tu cuenta de administrador ha sido creada.',
          htmlBody: '''
            <h1>¡Hola ${_adminNameController.text.trim()}!</h1>
            <p>Tu cuenta para administrar el salón "${_salonNameController.text.trim()}" ha sido creada con éxito.</p>
            <p>Puedes iniciar sesión con: <strong>${_adminEmailController.text.trim()}</strong></p>
          ''',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Salón ${ _isEditing ? 'actualizado' : 'creado' } con éxito.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error de autenticación: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Ocurrió un error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(title: _isEditing ? 'Editar Salón' : 'Crear Nuevo Salón'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Datos del Salón',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              TextFormField(
                controller: _salonNameController,
                decoration: const InputDecoration(labelText: 'Nombre del Salón'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salonAddressController,
                decoration: const InputDecoration(labelText: 'Dirección'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _salonPhoneController,
                decoration: const InputDecoration(labelText: 'Teléfono'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 30),
              Text(
                'Datos del Administrador del Salón',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const Divider(),
              TextFormField(
                controller: _adminNameController,
                decoration: const InputDecoration(labelText: 'Nombre del Representante'),
                validator: (value) => value!.isEmpty ? 'Campo requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _adminEmailController,
                decoration: const InputDecoration(labelText: 'Email de Acceso'),
                keyboardType: TextInputType.emailAddress,
                enabled: true, // No se puede editar el email
                style: TextStyle(color: _isEditing ? Colors.grey : null),
                validator: (value) => value!.isEmpty || !value.contains('@')
                    ? 'Email inválido'
                    : null,
              ),
              if (!_isEditing)
                const SizedBox(height: 16),
              if (!_isEditing)
                TextFormField(
                  controller: _adminPasswordController,
                  decoration: const InputDecoration(labelText: 'Contraseña Provisional'),
                  obscureText: true,
                  validator: (value) =>
                      !_isEditing && (value?.length ?? 0) < 6 ? 'Mínimo 6 caracteres' : null,
                ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CustomButton(
                  text: _isEditing ? 'Guardar Cambios' : 'Crear Salón',
                  onPressed: _isLoading ? () {} : _saveSalon,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
