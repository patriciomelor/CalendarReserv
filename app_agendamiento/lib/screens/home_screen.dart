// lib/screens/home_screen.dart

import 'package:app_agendamiento/screens/admin_dashboard_screen.dart';
import 'package:app_agendamiento/screens/customer_home_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
      // El AppBar y el botón de logout ahora están en las pantallas específicas de cada rol.
      // Este widget es solo un "despachador".
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

            // LA LÓGICA CLAVE: Revisamos el rol del usuario
            if (userData['rol'] == 'admin') {
              // Si es admin, mostramos el Dashboard de Administrador
              return AdminDashboardScreen(userData: userData);
            } else {
              // Si no, mostramos la pantalla de Cliente
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
