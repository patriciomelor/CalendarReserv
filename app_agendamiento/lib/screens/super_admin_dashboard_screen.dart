// lib/screens/super_admin_dashboard_screen.dart

import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_fab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agend_app/screens/create_salon_screen.dart';

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
      appBar: CustomAppBar(
        title: 'Panel Super Admin: ${userData['nombre']}',
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      floatingActionButton: CustomFAB(
        onPressed: () => _addSalon(context),
        icon: Icons.add_business,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Clientes Registrados (Salones)',
              style: Theme.of(context).textTheme.headlineSmall,
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

                    return CustomCard(
                      icon: Icons.storefront,
                      title: data['nombre'] ?? 'Sin Nombre',
                      subtitle: 
                          'Dirección: ${data['direccion'] ?? 'No especificada'}',
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