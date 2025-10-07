// lib/screens/booking_calendar_screen.dart

import 'package:app_agendamiento/screens/booking_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:app_agendamiento/services/notification_service.dart';

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
  List<TimeSlot> _timeSlots = [];
  bool _isLoadingSlots = false;

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
        currentTime = currentTime.add(const Duration(minutes: 15));
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

  // **** FUNCIÓN _bookAppointment COMPLETAMENTE REESCRITA SIN TRANSACCIÓN ****
  Future<void> _bookAppointment() async {
    if (_selectedDay == null || _selectedTime == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    var currentUser = FirebaseAuth.instance.currentUser;
    final bool isGuestBooking = currentUser == null || currentUser.isAnonymous;

    try {
      String customerName;
      String customerEmail;
      String customerId;

      if (isGuestBooking) {
        final guestDetails = await _showGuestDetailsDialog();
        if (guestDetails == null) {
          Navigator.of(context).pop();
          return;
        }
        customerName = guestDetails['name']!;
        customerEmail = guestDetails['email']!;

        if (currentUser == null) {
          final userCredential = await FirebaseAuth.instance
              .signInAnonymously();
          currentUser = userCredential.user;
        }
        customerId = currentUser!.uid;
      } else {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();
        customerName = userDoc.data()?['nombre'] ?? 'Cliente';
        customerEmail = userDoc.data()?['email'] ?? '';
        customerId = currentUser.uid;
      }

      final serviceData = widget.service.data() as Map<String, dynamic>;
      final professionalData =
          widget.professional.data() as Map<String, dynamic>;
      final serviceDuration = serviceData['duracion'] as int;
      final startTime = DateTime(
        _selectedDay!.year,
        _selectedDay!.month,
        _selectedDay!.day,
        _selectedTime!.hour,
        _selectedTime!.minute,
      );
      final endTime = startTime.add(Duration(minutes: serviceDuration));

      // 1. Re-verificación de disponibilidad justo antes de escribir
      final query = FirebaseFirestore.instance
          .collection('appointments')
          .where('professionalId', isEqualTo: widget.professional.id)
          .where('startTime', isLessThan: Timestamp.fromDate(endTime))
          .where('endTime', isGreaterThan: Timestamp.fromDate(startTime))
          .limit(1);

      final existingAppointments = await query.get();
      if (existingAppointments.docs.isNotEmpty) {
        throw Exception(
          'Este horario ya no está disponible. Por favor, elige otro.',
        );
      }

      // 2. Si está libre, crear la cita
      await FirebaseFirestore.instance.collection('appointments').add({
        'salonId': widget.salonId,
        'serviceId': widget.service.id,
        'professionalId': widget.professional.id,
        'customerId': customerId,
        'customerName': customerName,
        'customerEmail': customerEmail,
        'startTime': Timestamp.fromDate(startTime),
        'endTime': Timestamp.fromDate(endTime),
        'status': 'confirmada',
        'isGuest': isGuestBooking,
      });

      // 3. Enviar notificación por correo
      final formattedDate = DateFormat(
        'EEEE d \'de\' MMMM, yyyy',
        'es_ES',
      ).format(startTime);
      final formattedTime = DateFormat('hh:mm a').format(startTime);
      await NotificationService.sendEmail(
        to: customerEmail,
        subject: '¡Tu cita ha sido confirmada!',
        htmlBody:
            '''<h1>¡Hola $customerName!</h1><p>Tu cita ha sido agendada con éxito.</p><p><strong>Servicio:</strong> ${serviceData['nombre']}</p><p><strong>Profesional:</strong> ${professionalData['nombre']}</p><p><strong>Fecha:</strong> $formattedDate a las $formattedTime</p>''',
      );

      if (mounted) Navigator.of(context).pop(); // Cierra el diálogo de carga

      if (mounted) {
        if (isGuestBooking) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (context) => const BookingSuccessScreen(),
            ),
            (route) => false,
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('¡Cita agendada con éxito!'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    } catch (e) {
      if (mounted) Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        _generateTimeSlots(_selectedDay!);
      }
    }
  }

  Future<Map<String, String>?> _showGuestDetailsDialog() async {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();

    return showDialog<Map<String, String>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Datos para la Reserva'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Tu Nombre Completo',
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: const InputDecoration(
                    labelText: 'Tu Correo Electrónico',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) => value!.isEmpty || !value.contains('@')
                      ? 'Email inválido'
                      : null,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                  });
                }
              },
              child: const Text('Confirmar'),
            ),
          ],
        );
      },
    );
  }

  DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

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
                                  ? Colors.deepPurple
                                  : isBooked
                                  ? Colors.grey[400]
                                  : Colors.green,
                              foregroundColor: Colors.white,
                            ),
                            onPressed: isBooked
                                ? null
                                : () {
                                    setState(() {
                                      _selectedTime = slot.time;
                                    });
                                  },
                            child: Text(slot.time.format(context)),
                          );
                        }).toList(),
                      ),
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
