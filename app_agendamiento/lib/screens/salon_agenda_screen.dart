import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

class AppointmentDetails {
  final String id;
  final String customerName;
  final String professionalName;
  final String serviceName;
  final DateTime startTime;
  final String status;

  AppointmentDetails({
    required this.id,
    required this.customerName,
    required this.professionalName,
    required this.serviceName,
    required this.startTime,
    required this.status,
  });
}

class SalonAgendaScreen extends StatefulWidget {
  final String salonId;
  const SalonAgendaScreen({super.key, required this.salonId});

  @override
  State<SalonAgendaScreen> createState() => _SalonAgendaScreenState();
}

class _SalonAgendaScreenState extends State<SalonAgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  Future<List<AppointmentDetails>> _fetchAgendaDetails(
    List<QueryDocumentSnapshot> docs,
  ) async {
    List<AppointmentDetails> detailsList = [];
    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      // Fetch related documents. Consider denormalizing data for performance.
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
          id: doc.id,
          customerName: data['customerName'] ?? 'Cliente sin nombre',
          professionalName:
              professionalDoc.data()?['nombre'] ?? 'Profesional no encontrado',
          serviceName: serviceDoc.data()?['nombre'] ?? 'Servicio no encontrado',
          startTime: (data['startTime'] as Timestamp).toDate(),
          status: data['status'] ?? 'desconocido',
        ),
      );
    }
    return detailsList;
  }

  Future<void> _cancelAppointment(String appointmentId) async {
    final bool? confirm = await showDialog(
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
            child: const Text('Sí, Cancelar'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await FirebaseFirestore.instance
            .collection('appointments')
            .doc(appointmentId)
            .update({'status': 'cancelada'});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada con éxito.'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
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

  @override
  Widget build(BuildContext context) {
    final startOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      appBar: const CustomAppBar(title: 'Agenda del Salón'),
      body: Column(
        children: [
          TableCalendar(
            locale: 'es_ES',
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            onDaySelected: (selectedDay, focusedDay) {
              setState(() {
                _selectedDay = selectedDay;
                _focusedDay = focusedDay;
              });
            },
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor.withOpacity(0.5),
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            headerStyle: const HeaderStyle(
              titleCentered: true,
              formatButtonVisible: false,
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              'Citas para el ${DateFormat('EEEE d \'de\' MMMM', 'es_ES').format(_selectedDay)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('appointments')
                  .where('salonId', isEqualTo: widget.salonId)
                  .where(
                    'startTime',
                    isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
                  )
                  .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
                  .orderBy('startTime')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Error al cargar la agenda.'),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text('No hay citas para este día.'),
                  );
                }

                return FutureBuilder<List<AppointmentDetails>>(
                  future: _fetchAgendaDetails(snapshot.data!.docs),
                  builder: (context, detailsSnapshot) {
                    if (detailsSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (detailsSnapshot.hasError || !detailsSnapshot.hasData) {
                      return const Center(
                        child: Text('Error al cargar detalles.'),
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
                        final isCancelled = appointment.status == 'cancelada';

                        return Card(
                          color: isCancelled ? Colors.grey[300] : Colors.white,
                          margin: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text(
                                appointment.customerName.isNotEmpty
                                    ? appointment.customerName[0]
                                    : '?',
                              ),
                            ),
                            title: Text(
                              '${appointment.serviceName} con ${appointment.professionalName}',
                              style: TextStyle(
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            subtitle: Text(
                              'Cliente: ${appointment.customerName} - Estado: ${appointment.status}',
                              style: TextStyle(
                                decoration: isCancelled
                                    ? TextDecoration.lineThrough
                                    : null,
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(formattedTime),
                                if (!isCancelled)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.cancel_outlined,
                                      color: Colors.red,
                                    ),
                                    onPressed: () =>
                                        _cancelAppointment(appointment.id),
                                    tooltip: 'Cancelar Cita',
                                  ),
                              ],
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
      ),
    );
  }
}
