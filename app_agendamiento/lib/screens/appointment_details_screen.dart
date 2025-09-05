// lib/screens/appointment_details_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
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
    bool confirm =
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Confirmar Cancelación'),
            content: const Text(
              '¿Estás seguro de que deseas cancelar esta cita?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Sí, cancelar'),
                style: TextButton.styleFrom(foregroundColor: Colors.red),
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalles de la Cita'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
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
                if (!isPast && status == 'confirmada')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar Cita'),
                      onPressed: _cancelAppointment,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(16),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
    IconData icon,
    String label,
    String value, {
    Color? statusColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[600]),
          const SizedBox(width: 16),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: TextStyle(color: statusColor, fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }
}
