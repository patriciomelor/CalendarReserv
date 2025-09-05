// lib/screens/select_professional_screen.dart

import 'package:app_agendamiento/screens/booking_calendar_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectProfessionalScreen extends StatelessWidget {
  final String salonId;
  final DocumentSnapshot service; // Recibimos el servicio seleccionado

  const SelectProfessionalScreen({
    super.key,
    required this.salonId,
    required this.service,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('2. Selecciona un Profesional'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('professionals')
            .where('salonId', isEqualTo: salonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final professionals = snapshot.data!.docs;
          if (professionals.isEmpty) {
            return const Center(
              child: Text('Este salón no tiene profesionales disponibles.'),
            );
          }

          return ListView.builder(
            itemCount: professionals.length,
            itemBuilder: (context, index) {
              final professional = professionals[index];
              final professionalData =
                  professional.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(professionalData['nombre']),
                subtitle: Text(professionalData['especialidad']),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navegamos al calendario, pasando todo lo que hemos seleccionado
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => BookingCalendarScreen(
                        salonId: salonId,
                        service: service,
                        professional: professional,
                      ),
                    ),
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
