// lib/screens/services_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ServicesScreen extends StatefulWidget {
  final String salonId;

  const ServicesScreen({super.key, required this.salonId});

  @override
  State<ServicesScreen> createState() => _ServicesScreenState();
}

class _ServicesScreenState extends State<ServicesScreen> {
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  void _showAddServiceDialog() {
    _nameController.clear();
    _priceController.clear();
    _durationController.clear();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Añadir Nuevo Servicio'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Servicio',
                ),
              ),
              TextField(
                controller: _priceController,
                decoration: const InputDecoration(
                  labelText: 'Precio (ej: 10000)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ], // Solo permite números
              ),
              TextField(
                controller: _durationController,
                decoration: const InputDecoration(
                  labelText: 'Duración (en minutos, ej: 30)',
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                ], // Solo permite números
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
                _addService();
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _addService() async {
    final name = _nameController.text.trim();
    final price = int.tryParse(_priceController.text.trim());
    final duration = int.tryParse(_durationController.text.trim());

    if (name.isNotEmpty && price != null && duration != null) {
      await FirebaseFirestore.instance.collection('services').add({
        'nombre': name,
        'precio': price,
        'duracion': duration,
        'salonId': widget.salonId,
      });
    }
  }

  Future<void> _deleteService(String docId) async {
    await FirebaseFirestore.instance.collection('services').doc(docId).delete();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestionar Servicios'),
        backgroundColor: Colors.teal,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddServiceDialog,
        backgroundColor: Colors.teal,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('salonId', isEqualTo: widget.salonId)
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
                'No hay servicios registrados.\n¡Añade uno con el botón +!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          final services = snapshot.data!.docs;

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final serviceData = service.data() as Map<String, dynamic>;

              final price = serviceData['precio'] ?? 0;
              final duration = serviceData['duracion'] ?? 0;

              return ListTile(
                leading: const Icon(Icons.cut),
                title: Text(serviceData['nombre'] ?? 'Sin nombre'),
                subtitle: Text('Precio: \$$price - Duración: $duration min'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _deleteService(service.id),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
