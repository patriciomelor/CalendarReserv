// lib/screens/professionals_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfessionalsScreen extends StatefulWidget {
  final String salonId;

  const ProfessionalsScreen({super.key, required this.salonId});

  @override
  State<ProfessionalsScreen> createState() => _ProfessionalsScreenState();
}

class _ProfessionalsScreenState extends State<ProfessionalsScreen> {
  // Controladores para el formulario del diálogo
  final _nameController = TextEditingController();
  final _specialtyController = TextEditingController();

  // Función para mostrar el diálogo de "Añadir Profesional"
  void _showAddProfessionalDialog() {
    // Limpiamos los controladores antes de mostrar el diálogo
    _nameController.clear();
    _specialtyController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Nuevo Profesional'),
          content: Column(
            mainAxisSize: MainAxisSize
                .min, // Para que el diálogo no ocupe toda la pantalla
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(labelText: 'Nombre Completo'),
              ),
              TextField(
                controller: _specialtyController,
                decoration: const InputDecoration(
                  labelText: 'Especialidad (ej: Peluquero)',
                ),
              ),
            ],
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

  // Función para añadir el profesional a Firestore
  Future<void> _addProfessional() async {
    final name = _nameController.text.trim();
    final specialty = _specialtyController.text.trim();

    if (name.isNotEmpty && specialty.isNotEmpty) {
      await FirebaseFirestore.instance.collection('professionals').add({
        'nombre': name,
        'especialidad': specialty,
        'salonId': widget.salonId, // Usamos el ID del salón actual
      });
    }
  }

  // Función para eliminar un profesional
  Future<void> _deleteProfessional(String docId) async {
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
      // El FloatingActionButton es el botón redondo en la esquina
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddProfessionalDialog,
        backgroundColor: Colors.indigo,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      // Usamos un StreamBuilder para escuchar los cambios en tiempo real
      body: StreamBuilder<QuerySnapshot>(
        // El stream es nuestra consulta a Firestore
        stream: FirebaseFirestore.instance
            .collection('professionals')
            .where(
              'salonId',
              isEqualTo: widget.salonId,
            ) // Filtramos por el salón actual
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Ocurrió un error.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay profesionales registrados.\n¡Añade uno con el botón +!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Si todo está bien, construimos la lista
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
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteProfessional(professional.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
