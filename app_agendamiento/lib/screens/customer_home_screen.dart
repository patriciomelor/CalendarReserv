// lib/screens/customer_home_screen.dart

import 'package:app_agendamiento/screens/select_salon_screen.dart'; // MODIFICADO: Importamos la nueva pantalla
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CustomerHomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CustomerHomeScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bienvenido, ${userData['nombre']}!'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '¿Listo para tu próxima cita?',
                style: TextStyle(fontSize: 22),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.calendar_today, color: Colors.white),
                label: const Text(
                  'Agendar Nueva Cita',
                  style: TextStyle(fontSize: 18, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 15,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // MODIFICADO: Ahora navegamos a la pantalla de selección de salones
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SelectSalonScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
