// lib/screens/professional_agenda_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class ProfessionalAgendaScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfessionalAgendaScreen({super.key, required this.userData});

  @override
  State<ProfessionalAgendaScreen> createState() =>
      _ProfessionalAgendaScreenState();
}

class _ProfessionalAgendaScreenState extends State<ProfessionalAgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final professionalId = widget.userData['professionalId'];
    final salonId = widget.userData['salonId'];

    final startOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Agenda - ${widget.userData['nombre']}'),
        backgroundColor: Colors.green,
        foregroundColor: Colors.white,
        actions: [
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
          : Column(
              children: [
                // Calendario para seleccionar el día
                TableCalendar(
                  locale: 'es_ES',
                  firstDay: DateTime.utc(2020, 1, 1),
                  lastDay: DateTime.utc(2030, 12, 31),
                  focusedDay: _focusedDay,
                  selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _selectedDay = selectedDay;
                      _focusedDay = focusedDay;
                    });
                  },
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Citas para el ${DateFormat('d/M/y').format(_selectedDay)}',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                // Lista de citas para el día seleccionado
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('appointments')
                        .where('professionalId', isEqualTo: professionalId)
                        .where(
                          'startTime',
                          isGreaterThanOrEqualTo: Timestamp.fromDate(
                            startOfDay,
                          ),
                        )
                        .where(
                          'startTime',
                          isLessThan: Timestamp.fromDate(endOfDay),
                        )
                        .orderBy('startTime')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return Center(
                          child: Text(
                            'No tienes citas para el ${DateFormat('d/M/y').format(_selectedDay)}.',
                          ),
                        );
                      }
                      final appointments = snapshot.data!.docs;
                      return ListView.builder(
                        itemCount: appointments.length,
                        itemBuilder: (context, index) {
                          final appointment =
                              appointments[index].data()
                                  as Map<String, dynamic>;
                          final startTime =
                              (appointment['startTime'] as Timestamp).toDate();
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 6,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  DateFormat('HH:mm').format(startTime),
                                ),
                              ),
                              title: Text(
                                appointment['customerName'] ?? 'Cliente',
                              ),
                              subtitle: Text(
                                'Estado: ${appointment['status']}',
                              ),
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
