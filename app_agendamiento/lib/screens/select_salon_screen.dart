// lib/screens/select_salon_screen.dart

import 'package:app_agendamiento/screens/select_service_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectSalonScreen extends StatelessWidget {
  const SelectSalonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Elige un Salón'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Hacemos la consulta a la colección 'salones'
        stream: FirebaseFirestore.instance.collection('salones').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los salones.'));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text('No hay salones disponibles en este momento.'),
            );
          }

          final salons = snapshot.data!.docs;

          return ListView.builder(
            itemCount: salons.length,
            itemBuilder: (context, index) {
              final salon = salons[index];
              final salonData = salon.data() as Map<String, dynamic>;

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  title: Text(salonData['nombre'] ?? 'Sin Nombre'),
                  subtitle: Text(salonData['direccion'] ?? 'Sin Dirección'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    // Al seleccionar un salón, navegamos a la pantalla de servicios
                    // pasando el ID del salón elegido.
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SelectServiceScreen(salonId: salon.id),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
