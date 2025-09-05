// lib/screens/customer_home_screen.dart

import 'package:app_agendamiento/screens/appointment_details_screen.dart';
import 'package:app_agendamiento/screens/select_salon_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class CustomerHomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CustomerHomeScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;

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
      body: Column(
        children: [
          // Sección superior para agendar
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: ElevatedButton.icon(
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
                minimumSize: const Size(double.infinity, 50), // Ancho completo
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const SelectSalonScreen(),
                  ),
                );
              },
            ),
          ),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Mis Próximas Citas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
          // Lista de citas
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('customerId', isEqualTo: currentUser.uid)
                  .orderBy(
                    'startTime',
                    descending: true,
                  ) // Ordenar por fecha, más nuevas primero
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No tienes citas programadas.'),
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment = appointments[index];
                    final data = appointment.data() as Map<String, dynamic>;
                    final startTime = (data['startTime'] as Timestamp).toDate();

                    // Formateamos la fecha para que sea legible
                    final formattedDate = DateFormat(
                      'EEEE d \'de\' MMMM, yyyy',
                      'es_ES',
                    ).format(startTime);
                    final formattedTime = DateFormat(
                      'hh:mm a',
                    ).format(startTime);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: Icon(
                          data['status'] == 'cancelada'
                              ? Icons.cancel_outlined
                              : Icons.event_available,
                          color: data['status'] == 'cancelada'
                              ? Colors.red
                              : Colors.blueAccent,
                        ),
                        title: Text('Cita para el $formattedDate'),
                        subtitle: Text(
                          'A las $formattedTime - Estado: ${data['status']}',
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => AppointmentDetailsScreen(
                                appointment: appointment,
                              ),
                            ),
                          );
                        },
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
