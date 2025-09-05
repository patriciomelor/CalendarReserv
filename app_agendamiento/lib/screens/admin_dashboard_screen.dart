// lib/screens/admin_dashboard_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:app_agendamiento/screens/professionals_screen.dart';
import 'package:app_agendamiento/screens/services_screen.dart';
import 'package:app_agendamiento/screens/salon_settings_screen.dart';

class AdminDashboardScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const AdminDashboardScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final salonId = userData['salonId'];

    // Si por alguna razón el admin no tiene un salonId, mostramos un error.
    if (salonId == null) {
      return const Scaffold(
        body: Center(child: Text('Error: No tienes un salón asignado.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
      ),
      // Usamos otro FutureBuilder para obtener los datos específicos del salón.
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('salones')
            .doc(salonId)
            .get(),
        builder: (context, salonSnapshot) {
          if (salonSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (salonSnapshot.hasError) {
            return Center(
              child: Text(
                'Error al cargar datos del salón: ${salonSnapshot.error}',
              ),
            );
          }
          if (!salonSnapshot.hasData || !salonSnapshot.data!.exists) {
            return const Center(
              child: Text('No se encontró el salón especificado.'),
            );
          }

          final salonData = salonSnapshot.data!.data() as Map<String, dynamic>;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  salonData['nombre'] ?? 'Nombre del Salón',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Bienvenido, ${userData['nombre']}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const Divider(height: 40, thickness: 1),

                // Aquí irán las opciones del administrador
                const Text(
                  'Opciones de Gestión:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 20),
                ListTile(
                  leading: const Icon(Icons.group),
                  title: const Text('Gestionar Profesionales'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ProfessionalsScreen(salonId: salonId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cut),
                  title: const Text('Gestionar Servicios'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ServicesScreen(salonId: salonId),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.settings),
                  title: const Text('Configuración del Salón'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            SalonSettingsScreen(salonId: salonId),
                      ),
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
