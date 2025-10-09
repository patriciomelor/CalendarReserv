// lib/screens/admin_dashboard_screen.dart

import 'package:agend_app/screens/salon_agenda_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agend_app/screens/professionals_screen.dart';
import 'package:agend_app/screens/services_screen.dart';
import 'package:agend_app/screens/salon_settings_screen.dart';

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

          return CustomScrollView(
            slivers: [
              SliverAppBar(
                title: Text(
                  salonData['nombre'] ?? 'Panel de Administración',
                ),
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                actions: [
                  IconButton(
                    icon: const Icon(Icons.logout),
                    onPressed: () {
                      FirebaseAuth.instance.signOut();
                    },
                  ),
                ],
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bienvenido, ${userData['nombre']}!',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 20),
                      CustomCard(
                        icon: Icons.calendar_month,
                        title: 'Agenda del Día',
                        subtitle: 'Revisa y gestiona las citas de hoy',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  SalonAgendaScreen(salonId: salonId),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Opciones de Gestión',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  CustomCard(
                    icon: Icons.group,
                    title: 'Gestionar Profesionales',
                    subtitle: 'Añade o elimina profesionales de tu salón',
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
                  CustomCard(
                    icon: Icons.cut,
                    title: 'Gestionar Servicios',
                    subtitle: 'Define los servicios que ofreces',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ServicesScreen(salonId: salonId),
                        ),
                      );
                    },
                  ),
                  CustomCard(
                    icon: Icons.settings,
                    title: 'Configuración del Salón',
                    subtitle: 'Edita la información de tu salón',
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
                ]),
              ),
            ],
          );
        },
      ),
    );
  }
}