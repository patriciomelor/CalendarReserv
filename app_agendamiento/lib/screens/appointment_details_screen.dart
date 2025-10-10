// lib/screens/appointment_details_screen.dart

import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppointmentDetailsScreen extends StatefulWidget {
  final DocumentSnapshot appointment;
  const AppointmentDetailsScreen({super.key, required this.appointment});

  @override
  State<AppointmentDetailsScreen> createState() =>
      _AppointmentDetailsScreenState();
}

class _AppointmentDetailsScreenState extends State<AppointmentDetailsScreen> {
  Future<Map<String, String>> _getAppointmentDetails() async {
    final data = widget.appointment.data() as Map<String, dynamic>;

    final salonDoc = await FirebaseFirestore.instance
        .collection('salones')
        .doc(data['salonId'])
        .get();
    final serviceDoc = await FirebaseFirestore.instance
        .collection('services')
        .doc(data['serviceId'])
        .get();
    final professionalDoc = await FirebaseFirestore.instance
        .collection('professionals')
        .doc(data['professionalId'])
        .get();

    return {
      'salonName': salonDoc.data()?['nombre'] ?? 'Salón no encontrado',
      'serviceName': serviceDoc.data()?['nombre'] ?? 'Servicio no encontrado',
      'professionalName':
          professionalDoc.data()?['nombre'] ?? 'Profesional no encontrado',
    };
  }

  Future<void> _cancelAppointment() async {
    bool confirm = await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Cancelación'),
            content: const Text('¿Estás seguro de que deseas cancelar esta cita?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error),
                child: const Text('Sí, cancelar'),
              ),
            ],
          ),
        ) ??
        false;

    if (confirm) {
      await FirebaseFirestore.instance
          .collection('appointments')
          .doc(widget.appointment.id)
          .update({'status': 'cancelada'});

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cita cancelada.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = widget.appointment.data() as Map<String, dynamic>;
    final startTime = (data['startTime'] as Timestamp).toDate();
    final isPast = startTime.isBefore(DateTime.now());
    final status = data['status'];
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: const CustomAppBar(title: 'Detalles de la Cita'),
      body: FutureBuilder<Map<String, String>>(
        future: _getAppointmentDetails(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return const Center(
              child: Text('No se pudieron cargar los detalles.'),
            );
          }

          final details = snapshot.data!;

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow(Icons.store, 'Salón', details['salonName']!),
                _buildDetailRow(
                  Icons.calendar_today,
                  'Fecha',
                  DateFormat(
                    'EEEE d \'de\' MMMM, yyyy',
                    'es_ES',
                  ).format(startTime),
                ),
                _buildDetailRow(
                  Icons.access_time,
                  'Hora',
                  DateFormat('hh:mm a').format(startTime),
                ),
                _buildDetailRow(Icons.cut, 'Servicio', details['serviceName']!),
                _buildDetailRow(
                  Icons.person,
                  'Profesional',
                  details['professionalName']!,
                ),
                _buildDetailRow(
                  status == 'confirmada' ? Icons.check_circle : Icons.cancel,
                  'Estado',
                  status,
                  statusColor: status == 'confirmada'
                      ? Colors.green
                      : Colors.red,
                ),
                const Spacer(),
                if (!isPast && status == 'confirmada' && currentUser != null)
                  FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(currentUser.uid)
                        .get(),
                    builder: (context, userSnapshot) {
                      if (!userSnapshot.hasData) return const SizedBox.shrink();
                      final userData =
                          userSnapshot.data!.data() as Map<String, dynamic>;
                      final userRole = userData['rol'];

                      bool canCancel = false;
                      if (userRole == 'professional' &&
                          data['professionalId'] == currentUser.uid) {
                        canCancel = true;
                      }
                      if (data['customerId'] == currentUser.uid) {
                        canCancel = true;
                      }

                      if (canCancel) {
                        return SizedBox(
                          width: double.infinity,
                          child: CustomButton(
                            text: 'Cancelar Cita',
                            onPressed: _cancelAppointment,
                            icon: Icons.cancel_outlined,
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text('$label:', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context)
                  .textTheme
                  .bodyLarge
                  ?.copyWith(color: statusColor),
            ),
          ),
        ],
      ),
    );
  }
}