// lib/screens/public_booking_page.dart

import 'package:app_agendamiento/screens/booking_calendar_screen.dart'; // Reutilizamos el calendario
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class PublicBookingPage extends StatelessWidget {
  final String salonId;
  final String professionalId;

  const PublicBookingPage({
    super.key,
    required this.salonId,
    required this.professionalId,
  });

  Future<Map<String, dynamic>> _fetchInitialData() async {
    final salonDoc = await FirebaseFirestore.instance
        .collection('salones')
        .doc(salonId)
        .get();
    final professionalDoc = await FirebaseFirestore.instance
        .collection('professionals')
        .doc(professionalId)
        .get();
    return {'salon': salonDoc, 'professional': professionalDoc};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Agendar Cita')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _fetchInitialData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('Error: No se pudo cargar la información.'),
            );
          }

          final salonDoc = snapshot.data!['salon'] as DocumentSnapshot;
          final professionalDoc =
              snapshot.data!['professional'] as DocumentSnapshot;

          if (!salonDoc.exists || !professionalDoc.exists) {
            return const Center(
              child: Text('El enlace de reserva no es válido.'),
            );
          }

          final salonData = salonDoc.data() as Map<String, dynamic>;
          final professionalData =
              professionalDoc.data() as Map<String, dynamic>;

          return Column(
            children: [
              // Encabezado con información del profesional y el salón
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      professionalData['nombre'],
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      professionalData['especialidad'],
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      salonData['nombre'],
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ],
                ),
              ),
              const Divider(),
              const Padding(
                padding: EdgeInsets.all(8.0),
                child: Text(
                  '1. Selecciona un servicio:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              // Lista de servicios
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where('salonId', isEqualTo: salonId)
                      .snapshots(),
                  builder: (context, serviceSnapshot) {
                    if (!serviceSnapshot.hasData)
                      return const Center(child: CircularProgressIndicator());

                    return ListView.builder(
                      itemCount: serviceSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final serviceDoc = serviceSnapshot.data!.docs[index];
                        final serviceData =
                            serviceDoc.data() as Map<String, dynamic>;

                        return ListTile(
                          title: Text(serviceData['nombre']),
                          subtitle: Text(
                            '\$${serviceData['precio']} - ${serviceData['duracion']} min',
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios),
                          onTap: () {
                            // Al seleccionar un servicio, vamos directo al calendario
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingCalendarScreen(
                                  salonId: salonId,
                                  professional: professionalDoc,
                                  service: serviceDoc,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
