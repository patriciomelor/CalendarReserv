// lib/screens/home_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart'; // NUEVO: Importamos Firestore
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Obtenemos el usuario actual de FirebaseAuth
  final currentUser = FirebaseAuth.instance.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Página Principal'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              FirebaseAuth.instance.signOut();
            },
          ),
        ],
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
      ),
      // Usamos un FutureBuilder para obtener los datos del usuario de Firestore
      body: FutureBuilder<DocumentSnapshot>(
        // El 'future' es la operación asíncrona que queremos realizar
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get(),
        // El 'builder' define qué construir en la pantalla basado en el estado del future
        builder: (context, snapshot) {
          // Estado 1: Esperando que los datos lleguen
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          // Estado 2: Hubo un error al obtener los datos
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          // Estado 3: Los datos llegaron correctamente
          if (snapshot.hasData && snapshot.data!.exists) {
            // Convertimos los datos del documento en un mapa para poder leerlos
            final userData = snapshot.data!.data() as Map<String, dynamic>;

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    '¡Has iniciado sesión!',
                    style: TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    // Mostramos el nombre que obtuvimos de Firestore
                    userData['nombre'] ?? 'Nombre no disponible',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    // Mostramos el email (podemos obtenerlo de Firestore o de currentUser)
                    userData['email'] ?? '',
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              ),
            );
          }
          // Estado 4 (Fallback): El usuario está autenticado pero no tiene datos en Firestore
          return const Center(
            child: Text('No se encontraron datos para este usuario.'),
          );
        },
      ),
    );
  }
}
