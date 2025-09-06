// lib/screens/professional_agenda_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // NUEVO: Import para usar el portapapeles
import 'package:intl/intl.dart';

class ProfessionalAgendaScreen extends StatelessWidget {
  final Map<String, dynamic> userData;
  const ProfessionalAgendaScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));
    final professionalId = userData['professionalId'];
    final salonId = userData['salonId']; // Obtenemos el salonId del usuario

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Agenda - ${userData['nombre']}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
          // NUEVO: Botón para copiar el enlace
          IconButton(
            icon: const Icon(Icons.share),
            tooltip: 'Copiar mi enlace de reserva',
            onPressed: () {
              if (salonId != null && professionalId != null) {
                final webUrl = Uri.base;
                final bookingUrl =
                    '${webUrl.origin}/#/book/$salonId/$professionalId';
                Clipboard.setData(ClipboardData(text: bookingUrl));

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Enlace de reserva copiado al portapapeles.'),
                  ),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => FirebaseAuth.instance.signOut(),
          ),
        ],
      ),
      body: professionalId == null
          ? const Center(
              child: Text(
                'Error: tu cuenta no está vinculada a un perfil de profesional.',
              ),
            )
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('professionalId', isEqualTo: professionalId)
                  .where(
                    'startTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
                  )
                  .where(
                    'startTime',
                    isLessThan: Timestamp.fromDate(endOfToday),
                  )
                  .orderBy('startTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No tienes citas para hoy.',
                      style: TextStyle(fontSize: 18),
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;

                return ListView.builder(
                  itemCount: appointments.length,
                  itemBuilder: (context, index) {
                    final appointment =
                        appointments[index].data() as Map<String, dynamic>;
                    final startTime = (appointment['startTime'] as Timestamp)
                        .toDate();
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Text(DateFormat('HH:mm').format(startTime)),
                        ),
                        title: Text(appointment['customerName'] ?? 'Cliente'),
                        subtitle: Text('Estado: ${appointment['status']}'),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
