// lib/screens/select_service_screen.dart

import 'package:app_agendamiento/screens/select_professional_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectServiceScreen extends StatelessWidget {
  final String salonId;
  const SelectServiceScreen({super.key, required this.salonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('1. Selecciona un Servicio'),
        backgroundColor: Colors.blueAccent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('salonId', isEqualTo: salonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());

          final services = snapshot.data!.docs;
          if (services.isEmpty) {
            return const Center(
              child: Text('Este salón no tiene servicios disponibles.'),
            );
          }

          return ListView.builder(
            itemCount: services.length,
            itemBuilder: (context, index) {
              final service = services[index];
              final serviceData = service.data() as Map<String, dynamic>;

              return ListTile(
                title: Text(serviceData['nombre']),
                subtitle: Text(
                  '\$${serviceData['precio']} - ${serviceData['duracion']} min',
                ),
                trailing: const Icon(Icons.arrow_forward_ios),
                onTap: () {
                  // Navegamos al siguiente paso, pasando el salón y el servicio seleccionado
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SelectProfessionalScreen(
                        salonId: salonId,
                        service:
                            service, // Pasamos el documento completo del servicio
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
