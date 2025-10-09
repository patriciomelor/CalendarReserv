// lib/screens/select_service_screen.dart

import 'package:agend_app/screens/select_professional_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectServiceScreen extends StatelessWidget {
  final String salonId;
  const SelectServiceScreen({super.key, required this.salonId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '1. Selecciona un Servicio'),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('services')
            .where('salonId', isEqualTo: salonId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

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

              return CustomCard(
                icon: Icons.cut,
                title: serviceData['nombre'],
                subtitle:
                    '\$${serviceData['precio']} - ${serviceData['duracion']} min',
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