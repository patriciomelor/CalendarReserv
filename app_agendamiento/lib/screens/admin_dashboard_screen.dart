// lib/screens/admin_dashboard_screen.dart

import 'package:app_agendamiento/screens/salon_agenda_screen.dart';
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

          // MODIFICADO: Usamos un ListView en lugar de un Column para permitir el scroll
          return ListView(
            padding: const EdgeInsets.all(16.0),
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

              ListTile(
                leading: const Icon(Icons.calendar_month, color: Colors.indigo),
                title: const Text('Agenda del Día'),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SalonAgendaScreen(salonId: salonId),
                    ),
                  );
                },
              ),
              const Divider(),

              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8.0),
                child: Text(
                  'Opciones de Gestión:',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
                ),
              ),

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
          );
        },
      ),
    );
  }
}
