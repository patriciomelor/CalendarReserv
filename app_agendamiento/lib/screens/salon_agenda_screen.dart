// lib/screens/salon_agenda_screen.dart

import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Clase para contener la información enriquecida de la cita
class AppointmentDetails {
  final String customerName;
  final String professionalName;
  final String serviceName;
  final DateTime startTime;
  final String status;

  AppointmentDetails({
    required this.customerName,
    required this.professionalName,
    required this.serviceName,
    required this.startTime,
    required this.status,
  });
}

class SalonAgendaScreen extends StatelessWidget {
  final String salonId;
  const SalonAgendaScreen({super.key, required this.salonId});

  // Nueva función para obtener todos los detalles de las citas
  Future<List<AppointmentDetails>> _fetchAgendaDetails(
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<AppointmentDetails> detailsList = [];

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Para evitar múltiples llamadas, podríamos cachear estos datos en el futuro
      final professionalDoc = await FirebaseFirestore.instance
          .collection('professionals')
          .doc(data['professionalId'])
          .get();
      final serviceDoc = await FirebaseFirestore.instance
          .collection('services')
          .doc(data['serviceId'])
          .get();

      detailsList.add(
        AppointmentDetails(
          customerName: data['customerName'] ?? 'Cliente sin nombre',
          professionalName:
              professionalDoc.data()?['nombre'] ?? 'No encontrado',
          serviceName: serviceDoc.data()?['nombre'] ?? 'No encontrado',
          startTime: (data['startTime'] as Timestamp).toDate(),
          status: data['status'] ?? 'desconocido',
        ),
      );
    }
    return detailsList;
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final endOfToday = startOfToday.add(const Duration(days: 1));

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Agenda de Hoy (${DateFormat('d/M/y').format(now)})',
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('appointments')
            .where('salonId', isEqualTo: salonId)
            .where(
              'startTime',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startOfToday),
            )
            .where('startTime', isLessThan: Timestamp.fromDate(endOfToday))
            .orderBy('startTime')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(
              child: Text('Ocurrió un error al cargar la agenda.'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No hay citas para hoy.',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          // Usamos un FutureBuilder para enriquecer los datos
          return FutureBuilder<List<AppointmentDetails>>(
            future: _fetchAgendaDetails(snapshot.data!.docs),
            builder: (context, detailsSnapshot) {
              if (detailsSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (detailsSnapshot.hasError || !detailsSnapshot.hasData) {
                return const Center(
                  child: Text('Error al cargar detalles de citas.'),
                );
              }

              final appointments = detailsSnapshot.data!;

              return ListView.builder(
                itemCount: appointments.length,
                itemBuilder: (context, index) {
                  final appointment = appointments[index];
                  final formattedTime = DateFormat(
                    'HH:mm',
                  ).format(appointment.startTime);

                  return CustomCard(
                    icon: Icons.person,
                    title: appointment.customerName,
                    subtitle: '${appointment.serviceName} con ${appointment.professionalName}',
                    trailing: Text(formattedTime),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}