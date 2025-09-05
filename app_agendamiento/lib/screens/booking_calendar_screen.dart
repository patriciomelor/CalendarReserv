// lib/screens/booking_calendar_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

// NUEVO: Clase auxiliar para manejar el estado de cada bloque de tiempo
class TimeSlot {
  final TimeOfDay time;
  bool isBooked;

  TimeSlot({required this.time, this.isBooked = false});
}

class BookingCalendarScreen extends StatefulWidget {
  final String salonId;
  final DocumentSnapshot service;
  final DocumentSnapshot professional;

  const BookingCalendarScreen({
    super.key,
    required this.salonId,
    required this.service,
    required this.professional,
  });

  @override
  State<BookingCalendarScreen> createState() => _BookingCalendarScreenState();
}

class _BookingCalendarScreenState extends State<BookingCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  TimeOfDay? _selectedTime;

  // MODIFICADO: Ahora guardamos una lista de objetos TimeSlot
  List<TimeSlot> _timeSlots = [];
  bool _isLoadingSlots = false;

  // MODIFICADO: La función ahora genera TODOS los horarios y marca los que están reservados
  Future<void> _generateTimeSlots(DateTime day) async {
    setState(() {
      _isLoadingSlots = true;
      _timeSlots = [];
      _selectedTime = null;
    });

    try {
      final salonDoc = await FirebaseFirestore.instance
          .collection('salones')
          .doc(widget.salonId)
          .get();
      if (!salonDoc.exists) return;

      final salonData = salonDoc.data()!;
      final openingTimeParts = (salonData['openingTime'] as String).split(':');
      final closingTimeParts = (salonData['closingTime'] as String).split(':');
      final openingTime = TimeOfDay(
        hour: int.parse(openingTimeParts[0]),
        minute: int.parse(openingTimeParts[1]),
      );
      final closingTime = TimeOfDay(
        hour: int.parse(closingTimeParts[0]),
        minute: int.parse(closingTimeParts[1]),
      );
      final workDays = List<int>.from(salonData['workDays']);

      if (!workDays.contains(day.weekday)) {
        setState(() => _isLoadingSlots = false);
        return;
      }

      final serviceData = widget.service.data() as Map<String, dynamic>;
      final serviceDuration = serviceData['duracion'] as int;
      final startOfDay = DateTime(day.year, day.month, day.day);

      final appointmentsSnapshot = await FirebaseFirestore.instance
          .collection('appointments')
          .where('professionalId', isEqualTo: widget.professional.id)
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where(
            'startTime',
            isLessThan: Timestamp.fromDate(
              startOfDay.add(const Duration(days: 1)),
            ),
          )
          .get();

      final bookedTimes = appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return MapEntry(
          (data['startTime'] as Timestamp).toDate(),
          (data['endTime'] as Timestamp).toDate(),
        );
      }).toList();

      List<TimeSlot> potentialSlots = [];
      DateTime currentTime = startOfDay.add(
        Duration(hours: openingTime.hour, minutes: openingTime.minute),
      );
      DateTime endTimeLimit = startOfDay.add(
        Duration(hours: closingTime.hour, minutes: closingTime.minute),
      );

      while (currentTime.isBefore(endTimeLimit)) {
        final slotTime = TimeOfDay.fromDateTime(currentTime);
        bool isBooked = false;
        final slotStart = currentTime;
        final slotEnd = slotStart.add(Duration(minutes: serviceDuration));

        if (slotEnd.isAfter(endTimeLimit)) {
          break;
        }

        for (var booked in bookedTimes) {
          if (slotStart.isBefore(booked.value) && slotEnd.isAfter(booked.key)) {
            isBooked = true;
            break;
          }
        }
        potentialSlots.add(TimeSlot(time: slotTime, isBooked: isBooked));
        currentTime = currentTime.add(
          const Duration(minutes: 15),
        ); // Puedes ajustar el intervalo
      }

      setState(() {
        _timeSlots = potentialSlots;
      });
    } catch (e) {
      print('Error al generar horarios: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

  // MODIFICADO: La función ahora usa una transacción para evitar dobles reservas
  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final serviceData = widget.service.data() as Map<String, dynamic>;
    final serviceDuration = serviceData['duracion'] as int;
    final startTime = DateTime(
      _selectedDay!.year,
      _selectedDay!.month,
      _selectedDay!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );
    final endTime = startTime.add(Duration(minutes: serviceDuration));

    final firestore = FirebaseFirestore.instance;

    try {
      await firestore.runTransaction((transaction) async {
        // 1. Volver a verificar la disponibilidad DENTRO de la transacción
        final appointmentsSnapshot = await firestore
            .collection('appointments')
            .where('professionalId', isEqualTo: widget.professional.id)
            .where('startTime', isLessThan: Timestamp.fromDate(endTime))
            .where('endTime', isGreaterThan: Timestamp.fromDate(startTime))
            .limit(1)
            .get();

        if (appointmentsSnapshot.docs.isNotEmpty) {
          // Si encontramos una cita, significa que alguien la reservó.
          throw Exception('Este horario ya no está disponible.');
        }

        // 2. Si está libre, creamos la nueva cita
        final userDoc = await transaction.get(
          firestore.collection('users').doc(currentUser.uid),
        );
        final customerName = userDoc.data()?['nombre'] ?? 'Cliente';

        transaction.set(firestore.collection('appointments').doc(), {
          'salonId': widget.salonId,
          'serviceId': widget.service.id,
          'professionalId': widget.professional.id,
          'customerId': currentUser.uid,
          'customerName': customerName,
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'status': 'confirmada',
        });
      });

      // Si la transacción es exitosa...
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Cita agendada con éxito!'),
            backgroundColor: Colors.green,
          ),
        );
        int count = 0;
        Navigator.of(context).popUntil((_) => count++ >= 3);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final serviceData = widget.service.data() as Map<String, dynamic>;
    final professionalData = widget.professional.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('3. Selecciona Fecha y Hora'),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de tu Cita:',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Card(
                child: ListTile(
                  title: Text('Servicio: ${serviceData['nombre']}'),
                  subtitle: Text('Profesional: ${professionalData['nombre']}'),
                ),
              ),
              const SizedBox(height: 20),

              TableCalendar(
                locale: 'es_ES',
                firstDay: DateTime.now(),
                lastDay: DateTime.now().add(const Duration(days: 60)),
                focusedDay: _focusedDay,
                calendarFormat: CalendarFormat.month,
                selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                  });
                  _generateTimeSlots(selectedDay);
                },
              ),
              const Divider(height: 30),

              // MODIFICADO: La UI ahora se construye basada en el estado de cada TimeSlot
              if (_selectedDay != null)
                _isLoadingSlots
                    ? const Center(child: CircularProgressIndicator())
                    : _timeSlots.isEmpty
                    ? const Center(
                        child: Text('No hay horas disponibles para este día.'),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _timeSlots.map((slot) {
                          final isSelected = _selectedTime == slot.time;
                          final isBooked = slot.isBooked;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors
                                        .deepPurple // Seleccionado
                                  : isBooked
                                  ? Colors.grey[400] // Reservado
                                  : Colors.green, // Disponible
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isBooked
                                ? null
                                : () {
                                    // Deshabilitar si está reservado
                                    setState(() {
                                      _selectedTime = slot.time;
                                    });
                                  },
                            child: Text(slot.time.format(context)),
                          );
                        }).toList(),
                      ),

              // NUEVO: Leyenda de colores
              if (_selectedDay != null &&
                  !_isLoadingSlots &&
                  _timeSlots.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 20.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildLegendItem(Colors.green, 'Disponible'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.deepPurple, 'Seleccionado'),
                      const SizedBox(width: 16),
                      _buildLegendItem(Colors.grey[400]!, 'Reservado'),
                    ],
                  ),
                ),

              if (_selectedTime != null)
                Padding(
                  padding: const EdgeInsets.only(top: 24.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(
                        Icons.check_circle_outline,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Confirmar Cita',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.all(16),
                      ),
                      onPressed: _bookAppointment,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // NUEVO: Widget auxiliar para la leyenda
  Widget _buildLegendItem(Color color, String text) {
    return Row(
      children: [
        Container(width: 16, height: 16, color: color),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}
