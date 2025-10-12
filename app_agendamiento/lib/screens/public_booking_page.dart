
// lib/screens/public_booking_page.dart

import 'package:agend_app/screens/booking_calendar_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class PublicBookingPage extends StatefulWidget {
  final String salonId;
  final String professionalId;

  const PublicBookingPage({
    super.key,
    required this.salonId,
    required this.professionalId,
  });

  @override
  State<PublicBookingPage> createState() => _PublicBookingPageState();
}

class _PublicBookingPageState extends State<PublicBookingPage> {
  late Future<Map<String, dynamic>> _initialDataFuture;

  @override
  void initState() {
    super.initState();
    _initialDataFuture = _fetchInitialData();
  }

  Future<Map<String, dynamic>> _fetchInitialData() async {
    // Asegurarse de que el usuario esté autenticado (anónimamente si es necesario)
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
    }

    final salonDoc = await FirebaseFirestore.instance
        .collection('salones')
        .doc(widget.salonId)
        .get();
    final professionalDoc = await FirebaseFirestore.instance
        .collection('professionals')
        .doc(widget.professionalId)
        .get();
    return {'salon': salonDoc, 'professional': professionalDoc};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Agendar Cita'),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _initialDataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Text('Error al cargar la información: ${snapshot.error}'),
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
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('services')
                      .where('salonId', isEqualTo: widget.salonId)
                      .snapshots(),
                  builder: (context, serviceSnapshot) {
                    if (serviceSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!serviceSnapshot.hasData || serviceSnapshot.data!.docs.isEmpty) {
                      return const Center(child: Text('No hay servicios disponibles.'));
                    }

                    return ListView.builder(
                      itemCount: serviceSnapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final serviceDoc = serviceSnapshot.data!.docs[index];
                        final serviceData =
                            serviceDoc.data() as Map<String, dynamic>;

                        return CustomCard(
                          icon: Icons.cut,
                          title: serviceData['nombre'],
                          subtitle:
                              '\$${serviceData['precio']} - ${serviceData['duracion']} min',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => BookingCalendarScreen(
                                  salonId: widget.salonId,
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
