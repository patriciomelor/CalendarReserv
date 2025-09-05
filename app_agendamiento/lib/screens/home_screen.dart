// lib/screens/home_screen.dart

import 'package:app_agendamiento/screens/admin_dashboard_screen.dart';
import 'package:app_agendamiento/screens/customer_home_screen.dart';
import 'package:app_agendamiento/screens/super_admin_dashboard_screen.dart'; // NUEVO IMPORT
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:app_agendamiento/screens/professional_agenda_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.hasData && snapshot.data!.exists) {
            final userData = snapshot.data!.data() as Map<String, dynamic>;
            final userRole = userData['rol']; // Obtenemos el rol

            if (userRole == 'super-admin') {
              return SuperAdminDashboardScreen(userData: userData);
            } else if (userRole == 'admin') {
              return AdminDashboardScreen(userData: userData);
            } else if (userRole == 'professional') {
              // <-- AÑADIR ESTA CONDICIÓN
              return ProfessionalAgendaScreen(userData: userData);
            } else {
              return CustomerHomeScreen(userData: userData);
            }
          }

          return const Center(
            child: Text('No se encontraron datos para este usuario.'),
          );
        },
      ),
    );
  }
}
