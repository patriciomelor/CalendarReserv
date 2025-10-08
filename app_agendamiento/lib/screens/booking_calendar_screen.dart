// lib/screens/booking_calendar_screen.dart

import 'package:agend_app/screens/booking_success_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:agend_app/services/notification_service.dart';

class TimeSlot {
  final TimeOfDay time;
  final int bookings;
  final bool isCurrentUserBooked;

  TimeSlot({
    required this.time,
    this.bookings = 0,
    this.isCurrentUserBooked = false,
  });
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
  int _slotsPerTime = 1;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _generateTimeSlots(_selectedDay!);
  }

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
      _slotsPerTime = salonData['slotsPerTime'] ?? 1;
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

      final bookedSlots = appointmentsSnapshot.docs.map((doc) {
        final data = doc.data();
        return {
          'startTime': (data['startTime'] as Timestamp).toDate(),
          'customerId': data['customerId'],
        };
      }).toList();

      final currentUser = FirebaseAuth.instance.currentUser;

      List<TimeSlot> potentialSlots = [];
      DateTime currentTime = startOfDay.add(
        Duration(hours: openingTime.hour, minutes: openingTime.minute),
      );
      DateTime endTimeLimit = startOfDay.add(
        Duration(hours: closingTime.hour, minutes: closingTime.minute),
      );

      while (currentTime.isBefore(endTimeLimit)) {
        final slotTime = TimeOfDay.fromDateTime(currentTime);
        final slotStart = currentTime;
        final slotEnd = slotStart.add(Duration(minutes: serviceDuration));

        if (slotEnd.isAfter(endTimeLimit)) {
          break;
        }

        final bookingsForSlot = bookedSlots
            .where((booked) =>
                booked['startTime']!.hour == slotTime.hour &&
                booked['startTime']!.minute == slotTime.minute)
            .toList();

        final isCurrentUserBooked = currentUser != null &&
            bookingsForSlot.any(
                (booking) => booking['customerId'] == currentUser.uid);

        potentialSlots.add(TimeSlot(
          time: slotTime,
          bookings: bookingsForSlot.length,
          isCurrentUserBooked: isCurrentUserBooked,
        ));

        currentTime = currentTime.add(const Duration(minutes: 15));
      }

      setState(() {
        _timeSlots = potentialSlots;
      });
    } catch (e) {
      // print('Error al generar horarios: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingSlots = false);
      }
    }
  }

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
          if (mounted) {
            Navigator.of(context).pop();
          }
          return;
        }
        customerName = guestDetails['name']!;
        customerEmail = guestDetails['email']!;

        if (currentUser == null) {
          final userCredential = await FirebaseAuth.instance.signInAnonymously();
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

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final query = FirebaseFirestore.instance
            .collection('appointments')
            .where('professionalId', isEqualTo: widget.professional.id)
            .where('startTime', isEqualTo: Timestamp.fromDate(startTime));

        final existingAppointments = await query.get();

        if (existingAppointments.docs.length >= _slotsPerTime) {
          throw Exception(
            'Este horario ya no está disponible. Por favor, elige otro.',
          );
        }

        if (existingAppointments.docs
            .any((doc) => doc.data()['customerId'] == customerId)) {
          throw Exception('Ya tienes una cita en este horario.');
        }

        transaction.set(FirebaseFirestore.instance.collection('appointments').doc(), {
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
      });

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
            SnackBar(
              content: Text('¡Cita agendada con éxito!', style: GoogleFonts.poppins()),
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
          title: Text('Datos para la Reserva', style: GoogleFonts.poppins()),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: 'Tu Nombre Completo',
                    labelStyle: GoogleFonts.poppins(),
                  ),
                  validator: (value) =>
                      value!.isEmpty ? 'Campo requerido' : null,
                ),
                TextFormField(
                  controller: emailController,
                  decoration: InputDecoration(
                    labelText: 'Tu Correo Electrónico',
                    labelStyle: GoogleFonts.poppins(),
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
              child: Text('Cancelar', style: GoogleFonts.poppins()),
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
              child: Text('Confirmar', style: GoogleFonts.poppins()),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final serviceData = widget.service.data() as Map<String, dynamic>;
    final professionalData = widget.professional.data() as Map<String, dynamic>;
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text('3. Selecciona Fecha y Hora', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Resumen de tu Cita:',
                style: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  title: Text('Servicio: ${serviceData['nombre']}', style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                  subtitle: Text('Profesional: ${professionalData['nombre']}', style: GoogleFonts.poppins()),
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
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: const BoxDecoration(
                    color: Colors.blueAccent,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                  formatButtonVisible: false,
                ),
              ),
              const Divider(height: 30),
              if (_selectedDay != null)
                _isLoadingSlots
                    ? const Center(child: CircularProgressIndicator())
                    : _timeSlots.isEmpty
                    ? Center(
                        child: Text('No hay horas disponibles para este día.', style: GoogleFonts.poppins()),
                      )
                    : Wrap(
                        spacing: 8.0,
                        runSpacing: 8.0,
                        children: _timeSlots.map((slot) {
                          final isSelected = _selectedTime == slot.time;
                          final isFullyBooked = slot.bookings >= _slotsPerTime;
                          final canBook = !isFullyBooked && !slot.isCurrentUserBooked;

                          return ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isSelected
                                  ? Colors.deepPurple
                                  : canBook
                                  ? Colors.green
                                  : Colors.grey[400],
                              foregroundColor: Colors.white,
                            ),
                            onPressed: canBook
                                ? () {
                                    setState(() {
                                      _selectedTime = slot.time;
                                    });
                                  }
                                : null,
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
                      _buildLegendItem(Colors.grey[400]!, 'No disponible'),
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
                      label: Text(
                        'Confirmar Cita',
                        style: GoogleFonts.poppins(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        padding: const EdgeInsets.all(16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        Text(text, style: GoogleFonts.poppins()),
      ],
    );
  }
}
