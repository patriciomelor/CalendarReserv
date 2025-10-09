// lib/screens/customer_home_screen.dart

import 'package:agend_app/screens/appointment_details_screen.dart';
import 'package:agend_app/screens/select_salon_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectSalonScreen(),
            ),
          );
        },
        label: const Text('Agendar Cita'),
        icon: const Icon(Icons.add),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: Text('Bienvenido, ${userData['nombre']}!'),
            pinned: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('customerId', isEqualTo: currentUser.uid)
                  .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
                  .where('status', whereIn: ['pendiente', 'confirmada'])
                  .orderBy('startTime', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(
                      child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error al cargar las citas.',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No tienes citas programadas.',
                      ),
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;
                final pendingAppointments = appointments
                    .where((doc) => doc['status'] == 'pendiente')
                    .toList();
                final confirmedAppointments = appointments
                    .where((doc) => doc['status'] == 'confirmada')
                    .toList();

                return SliverList(
                  delegate: SliverChildListDelegate([
                    if (pendingAppointments.isNotEmpty)
                      ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Text(
                            'Citas Pendientes de Confirmación',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ...pendingAppointments.map((appointment) {
                          final data = appointment.data() as Map<String, dynamic>;
                          final startTime = (data['startTime'] as Timestamp).toDate();
                          final formattedDate =
                              DateFormat('d MMM yyyy', 'es_ES').format(startTime);
                          final formattedTime = DateFormat('hh:mm a').format(startTime);
                          final dayOfWeek =
                              DateFormat('EEEE', 'es_ES').format(startTime);

                          return CustomCard(
                            title: '$dayOfWeek, $formattedDate',
                            subtitle: 'A las $formattedTime',
                            icon: Icons.calendar_today,
                            trailing: const Text('Pendiente'),
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
                          );
                        }).toList(),
                      ],
                    if (confirmedAppointments.isNotEmpty)
                      ...[
                        Padding(
                          padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                          child: Text(
                            'Mis Próximas Citas',
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                        ),
                        ...confirmedAppointments.map((appointment) {
                          final data = appointment.data() as Map<String, dynamic>;
                          final startTime = (data['startTime'] as Timestamp).toDate();
                          final formattedDate =
                              DateFormat('d MMM yyyy', 'es_ES').format(startTime);
                          final formattedTime = DateFormat('hh:mm a').format(startTime);
                          final dayOfWeek =
                              DateFormat('EEEE', 'es_ES').format(startTime);

                          return CustomCard(
                            title: '$dayOfWeek, $formattedDate',
                            subtitle: 'A las $formattedTime',
                            icon: Icons.calendar_today,
                            trailing: PopupMenuButton<String>(
                              onSelected: (_) =>
                                  _cancelAppointment(context, appointment.id),
                              itemBuilder: (context) => [
                                const PopupMenuItem(
                                  value: 'cancel',
                                  child: Text('Cancelar Cita'),
                                ),
                              ],
                              icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                            ),
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
                          );
                        }).toList(),
                      ],
                  ]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelAppointment(
      BuildContext context, String appointmentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelación'),
        content: const Text('¿Estás seguro de que quieres cancelar esta cita?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sí, cancelar'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({'status': 'cancelada'});

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al cancelar la cita: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
