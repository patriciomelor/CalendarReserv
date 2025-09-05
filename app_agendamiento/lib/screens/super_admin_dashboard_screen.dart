// lib/screens/super_admin_dashboard_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_agendamiento/screens/create_salon_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const SuperAdminDashboardScreen({super.key, required this.userData});

  // En el futuro, aquí iría la lógica para crear un nuevo salón
  void _addSalon(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSalonScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel Super Admin: ${userData['nombre']}'),
        backgroundColor: const Color(0xFFB71C1C), // Un rojo oscuro distintivo
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addSalon(context),
        backgroundColor: const Color(0xFFB71C1C),
        child: const Icon(Icons.add_business, color: Colors.white),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              'Clientes Registrados (Salones)',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('salones')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar los salones.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay salones registrados.'),
                  );
                }

                final salons = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: salons.length,
                  itemBuilder: (context, index) {
                    final salon = salons[index];
                    final data = salon.data() as Map<String, dynamic>;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: const Icon(
                          Icons.storefront,
                          color: Color(0xFFB71C1C),
                        ),
                        title: Text(data['nombre'] ?? 'Sin Nombre'),
                        subtitle: Text(
                          'Dirección: ${data['direccion'] ?? 'No especificada'}',
                        ),
                        // En el futuro, al tocar aquí podríamos ver los detalles del salón
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
