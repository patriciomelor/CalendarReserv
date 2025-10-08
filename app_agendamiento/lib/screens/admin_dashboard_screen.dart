// lib/screens/admin_dashboard_screen.dart

import 'package:agend_app/screens/salon_agenda_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:agend_app/screens/professionals_screen.dart';
import 'package:agend_app/screens/services_screen.dart';
import 'package:agend_app/screens/salon_settings_screen.dart';
import 'package:google_fonts/google_fonts.dart';

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
      backgroundColor: Colors.grey[100],
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
                  style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                ),
                floating: true,
                snap: true,
                elevation: 0,
                backgroundColor: Colors.transparent,
                foregroundColor: Colors.black,
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
                        style: GoogleFonts.poppins(fontSize: 18),
                      ),
                      const SizedBox(height: 20),
                      _buildManagementCard(
                        context,
                        icon: Icons.calendar_month,
                        title: 'Agenda del Día',
                        color: Colors.indigo,
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
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                  ),
                ),
              ),
              SliverList(
                delegate: SliverChildListDelegate([
                  _buildManagementListTile(
                    context,
                    icon: Icons.group,
                    title: 'Gestionar Profesionales',
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
                  _buildManagementListTile(
                    context,
                    icon: Icons.cut,
                    title: 'Gestionar Servicios',
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
                  _buildManagementListTile(
                    context,
                    icon: Icons.settings,
                    title: 'Configuración del Salón',
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

  Widget _buildManagementCard(BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.1),
                child: Icon(icon, color: color, size: 30),
              ),
              const SizedBox(width: 20),
              Text(
                title,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildManagementListTile(BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        leading: Icon(icon, color: Colors.grey[700]),
        title: Text(
          title,
          style: GoogleFonts.poppins(fontWeight: FontWeight.w500),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
