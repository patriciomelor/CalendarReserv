// lib/screens/super_admin_dashboard_screen.dart

import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_fab.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:agend_app/screens/create_salon_screen.dart';

class SuperAdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const SuperAdminDashboardScreen({super.key, required this.userData});

  void _addSalon(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateSalonScreen()),
    );
  }

  void _editSalon(BuildContext context, DocumentSnapshot salon) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => CreateSalonScreen(salon: salon)),
    );
  }

  Future<void> _deleteSalon(BuildContext context, String salonId) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar este salón? Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('salones')
            .doc(salonId)
            .delete();
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Salón eliminado con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al eliminar el salón: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
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

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        leading: const Icon(Icons.storefront, size: 40),
                        title: Text(data['nombre'] ?? 'Sin Nombre'),
                        subtitle: Text(data['direccion'] ?? 'No especificada'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit, color: Colors.blue),
                              onPressed: () => _editSalon(context, salon),
                              tooltip: 'Editar Salón',
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _deleteSalon(context, salon.id),
                              tooltip: 'Eliminar Salón',
                            ),
                          ],
                        ),
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
