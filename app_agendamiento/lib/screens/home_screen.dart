// lib/screens/home_screen.dart

import 'package:agend_app/screens/admin_dashboard_screen.dart';
import 'package:agend_app/screens/customer_home_screen.dart';
import 'package:agend_app/screens/professional_agenda_screen.dart';
import 'package:agend_app/screens/super_admin_dashboard_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser == null) {
      // This should not happen if AuthGate is working correctly, but as a fallback.
      return const Scaffold(
        body: Center(
          child: Text('No user logged in.'),
        ),
      );
    }

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(currentUser.uid).get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Text('Error: ${snapshot.error}'),
            ),
          );
        }

        if (!snapshot.hasData || !snapshot.data!.exists) {
          return const Scaffold(
            body: Center(
              child: Text('User data not found.'),
            ),
          );
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final role = userData['role'] as String?;

        switch (role) {
          case 'superAdmin':
          case 'super-admin': // Added for compatibility
            return SuperAdminDashboardScreen(userData: userData);
          case 'admin':
            return AdminDashboardScreen(userData: userData);
          case 'professional':
            return ProfessionalAgendaScreen(userData: userData);
          case 'customer':
          case 'cliente': // Added for compatibility
          default:
            return CustomerHomeScreen(userData: userData);
        }
      },
    );
  }
}