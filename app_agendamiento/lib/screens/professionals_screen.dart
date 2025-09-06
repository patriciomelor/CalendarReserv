// lib/screens/professionals_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ProfessionalsScreen extends StatefulWidget {
  final String salonId;

  const ProfessionalsScreen({super.key, required this.salonId});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  void _showAddProfessionalDialog() {
    _nameController.clear();
    _specialtyController.clear();
    _emailController.clear();
    _passwordController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Nuevo Profesional'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre Completo',
                  ),
                ),
                TextField(
                  controller: _specialtyController,
                  decoration: const InputDecoration(labelText: 'Especialidad'),
                ),
                const Divider(height: 20),
                const Text(
                  'Credenciales de Acceso',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email de Acceso',
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                TextField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Contraseña Provisional',
                  ),
                  obscureText: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: const Text('Añadir'),
              onPressed: () {
                _addProfessional();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addProfessional() async {
    final name = _nameController.text.trim();
    final specialty = _specialtyController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (name.isNotEmpty &&
        specialty.isNotEmpty &&
        email.isNotEmpty &&
        password.length >= 6) {
      try {
        final tempApp = await Firebase.initializeApp(
          name: 'tempProfessionalCreation',
          options: Firebase.app().options,
        );
        final tempAuth = FirebaseAuth.instanceFor(app: tempApp);

        UserCredential userCredential = await tempAuth
            .createUserWithEmailAndPassword(email: email, password: password);
        final professionalUid = userCredential.user!.uid;
        await tempApp.delete();

        final professionalDocRef = await FirebaseFirestore.instance
            .collection('professionals')
            .add({
              'nombre': name,
              'especialidad': specialty,
              'salonId': widget.salonId,
              'uid': professionalUid, // Vínculo con su cuenta de usuario
            });

        await FirebaseFirestore.instance
            .collection('users')
            .doc(professionalUid)
            .set({
              'nombre': name,
              'email': email,
              'rol': 'professional', // NUEVO ROL
              'salonId': widget.salonId,
              'professionalId': professionalDocRef.id, // Vínculo inverso
            });
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al crear profesional: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Future<void> _deleteProfessional(String docId) async {
    // En una app real, también se debería deshabilitar o eliminar el usuario de Firebase Auth.
    // Por ahora, solo lo eliminamos de la colección de profesionales.
    await FirebaseFirestore.instance
        .collection('professionals')
        .doc(docId)
        .delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Profesionales'),
        backgroundColor: Colors.indigo,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfessionalDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('professionals')
            .where('salonId', isEqualTo: widget.salonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay profesionales registrados.'),
            );
          }
          final professionals = snapshot.data!.docs;
          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              final professionalData =
                  professional.data() as Map<String, dynamic>;
              return ListTile(
                leading: const Icon(Icons.person),
                title: Text(professionalData['nombre'] ?? 'Sin nombre'),
                subtitle: Text(
                  professionalData['especialidad'] ?? 'Sin especialidad',
                ),
                // MODIFICADO: Cambiamos el trailing por un Row con dos botones
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.share, color: Colors.blue),
                      tooltip: 'Copiar enlace de reserva',
                      onPressed: () {
                        // Obtenemos la URL base de la web
                        final webUrl = Uri.base;
                        // Construimos el enlace directo
                        final bookingUrl =
                            '${webUrl.origin}/#/book/${widget.salonId}/${professional.id}';
                        // Copiamos al portapapeles
                        Clipboard.setData(ClipboardData(text: bookingUrl));

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Enlace de reserva copiado al portapapeles.',
                            ),
                          ),
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () => _deleteProfessional(professional.id),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
