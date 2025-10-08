// lib/screens/customer_home_screen.dart

import 'package:agend_app/screens/appointment_details_screen.dart';
import 'package:agend_app/screens/select_salon_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class CustomerHomeScreen extends StatelessWidget {
  final Map<String, dynamic> userData;

  const CustomerHomeScreen({super.key, required this.userData});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser!;
    final textColor = const Color(0xFF333333);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SelectSalonScreen(),
            ),
          );
        },
        label: Text('Agendar Cita', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
        icon: const Icon(Icons.add),
        backgroundColor: const Color(0xFF4A90E2),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text(
              'Bienvenido, ${userData['nombre']}!',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 22),
            ),
            centerTitle: false,
            elevation: 0,
            backgroundColor: const Color(0xFFF8F9FA),
            foregroundColor: textColor,
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1.0),
              child: Container(
                color: Colors.grey[200],
                height: 1.0,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Mis Próximas Citas',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            sliver: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('customerId', isEqualTo: currentUser.uid)
                  .where('startTime', isGreaterThanOrEqualTo: Timestamp.now())
                  .where('status', isEqualTo: 'confirmada')
                  .orderBy('startTime', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
                }
                if (snapshot.hasError) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'Error al cargar las citas.',
                        style: GoogleFonts.poppins(color: Colors.grey[600]),
                      ),
                    ),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Text(
                        'No tienes citas programadas.',
                        style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ),
                  );
                }

                final appointments = snapshot.data!.docs;

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final appointment = appointments[index];
                      final data = appointment.data() as Map<String, dynamic>;
                      final startTime = (data['startTime'] as Timestamp).toDate();

                      final formattedDate = DateFormat('d MMM yyyy', 'es_ES').format(startTime);
                      final formattedTime = DateFormat('hh:mm a').format(startTime);
                      final dayOfWeek = DateFormat('EEEE', 'es_ES').format(startTime);

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.grey.withOpacity(0.08),
                              spreadRadius: 1,
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            '$dayOfWeek, $formattedDate',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                              color: textColor,
                            ),
                          ),
                          subtitle: Text(
                            'A las $formattedTime',
                            style: GoogleFonts.poppins(color: Colors.grey[600], fontSize: 14),
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (_) =>
                                _cancelAppointment(context, appointment.id),
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                value: 'cancel',
                                child: Text('Cancelar Cita', style: GoogleFonts.poppins()),
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
                        ),
                      );
                    },
                    childCount: appointments.length,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(String status) {
    IconData iconData;
    Color color;

    switch (status) {
      case 'cancelada':
        iconData = Icons.cancel_outlined;
        color = Colors.red;
        break;
      case 'completada':
        iconData = Icons.check_circle_outline;
        color = Colors.green;
        break;
      default:
        iconData = Icons.event_available;
        color = Color(0xFF4A90E2);
    }

    return CircleAvatar(
      backgroundColor: color.withOpacity(0.1),
      child: Icon(
        iconData,
        color: color,
      ),
    );
  }

  Future<void> _cancelAppointment(BuildContext context, String appointmentId) async {
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