// lib/screens/booking_calendar_screen.dart

import 'package:agend_app/screens/booking_success_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
            .where(
              (booked) =>
                  booked['startTime']!.hour == slotTime.hour &&
                  booked['startTime']!.minute == slotTime.minute,
            )
            .toList();

        final isCurrentUserBooked =
            currentUser != null &&
            bookingsForSlot.any(
              (booking) => booking['customerId'] == currentUser.uid,
            );

        potentialSlots.add(
          TimeSlot(
            time: slotTime,
            bookings: bookingsForSlot.length,
            isCurrentUserBooked: isCurrentUserBooked,
          ),
        );

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

      final appointmentRef = FirebaseFirestore.instance
          .collection('appointments')
          .doc();

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

        if (existingAppointments.docs.any(
          (doc) => doc.data()['customerId'] == customerId,
        )) {
          throw Exception('Ya tienes una cita en este horario.');
        }

        transaction.set(appointmentRef, {
          'salonId': widget.salonId,
          'serviceId': widget.service.id,
          'professionalId': widget.professional.id,
          'customerId': customerId,
          'customerName': customerName,
          'customerEmail': customerEmail,
          'startTime': Timestamp.fromDate(startTime),
          'endTime': Timestamp.fromDate(endTime),
          'status': 'pendiente',
          'createdAt': FieldValue.serverTimestamp(),
          'isGuest': isGuestBooking,
        });
      });

      final appointmentId = appointmentRef.id;
      final confirmUrl =
          'https://us-central1-appagendamiento-ddbd0.cloudfunctions.net/confirmAppointment?id=$appointmentId';
      final cancelUrl =
          'https://us-central1-appagendamiento-ddbd0.cloudfunctions.net/cancelAppointment?id=$appointmentId';

      final formattedDate = DateFormat(
        'EEEE d \'de\' MMMM, yyyy',
        'es_ES',
      ).format(startTime);
      final formattedTime = DateFormat('hh:mm a').format(startTime);

      // --- INICIO DE LA PLANTILLA DE CORREO MEJORADA ---
      final String htmlBody =
          '''
        <!DOCTYPE html>
        <html lang="es">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title>Confirmación de Cita</title>
          <style>
            body {
              font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, Helvetica, Arial, sans-serif;
              margin: 0;
              padding: 0;
              background-color: #f4f4f7;
              color: #333;
            }
            .container {
              max-width: 600px;
              margin: 20px auto;
              background-color: #ffffff;
              border-radius: 8px;
              overflow: hidden;
              box-shadow: 0 4px 15px rgba(0,0,0,0.05);
            }
            .header {
              background-color: #00796b; /* Un tono de teal más oscuro */
              color: #ffffff;
              padding: 24px;
              text-align: center;
            }
            .header h1 {
              margin: 0;
              font-size: 24px;
            }
            .content {
              padding: 32px;
            }
            .content p {
              line-height: 1.6;
              margin: 0 0 16px;
            }
            .details {
              background-color: #f9f9f9;
              border: 1px solid #eeeeee;
              border-radius: 4px;
              padding: 20px;
              margin-top: 20px;
            }
            .details strong {
              color: #004d40; /* Teal muy oscuro */
            }
            .button-container {
              text-align: center;
              margin-top: 24px;
            }
            .button {
              display: inline-block;
              padding: 12px 24px;
              font-size: 16px;
              font-weight: bold;
              color: #ffffff;
              text-decoration: none;
              border-radius: 5px;
              background-color: #009688; /* Teal principal */
            }
            .button.cancel {
              background-color: #f44336; /* Rojo para cancelar */
              margin-left: 10px;
            }
            .footer {
              text-align: center;
              padding: 20px;
              font-size: 12px;
              color: #888;
            }
          </style>
        </head>
        <body>
          <div class="container">
            <div class="header">
              <h1>¡Cita Pre-Agendada!</h1>
            </div>
            <div class="content">
              <p>¡Hola <strong>$customerName</strong>!</p>
              <p>Hemos recibido tu solicitud de cita. Por favor, revisa los detalles y confirma tu asistencia para asegurar tu horario.</p>
              <div class="details">
                <p><strong>Servicio:</strong> ${serviceData['nombre']}</p>
                <p><strong>Profesional:</strong> ${professionalData['nombre']}</p>
                <p><strong>Fecha:</strong> $formattedDate</p>
                <p><strong>Hora:</strong> $formattedTime</p>
              </div>
              <div class="button-container">
                <a href="$confirmUrl" class="button">Confirmar Cita</a>
              </div>
               <p style="margin-top: 24px; text-align: center; font-size: 14px;">Si no puedes asistir, puedes cancelar tu cita aquí:</p>
              <div class="button-container" style="margin-top: 8px;">
                 <a href="$cancelUrl" class="button cancel">Cancelar Cita</a>
              </div>
            </div>
            <div class="footer">
              <p>Este es un correo automático, por favor no respondas.</p>
            </div>
          </div>
        </body>
        </html>
      ''';
      // --- FIN DE LA PLANTILLA DE CORREO MEJORADA ---

      await NotificationService.sendEmail(
        to: customerEmail,
        subject: 'Confirma tu cita para ${serviceData['nombre']}',
        htmlBody: htmlBody,
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
                const SizedBox(height: 16),
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
            CustomButton(
              text: 'Confirmar',
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  Navigator.of(context).pop({
                    'name': nameController.text.trim(),
                    'email': emailController.text.trim(),
                  });
                }
              },
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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(title: '3. Selecciona Fecha y Hora'),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Resumen de tu Cita:', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              CustomCard(
                icon: Icons.cut,
                title: serviceData['nombre'] ?? 'Servicio no encontrado',
                subtitle:
                    'con ${professionalData['nombre'] ?? 'Profesional no encontrado'}',
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
                    color: theme.primaryColor.withOpacity(0.5),
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: theme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true,
                  titleTextStyle: theme.textTheme.titleLarge!,
                  formatButtonVisible: false,
                ),
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
                          final isFullyBooked = slot.bookings >= _slotsPerTime;
                          final canBook =
                              !isFullyBooked && !slot.isCurrentUserBooked;

                          Color buttonColor;
                          if (isSelected) {
                            buttonColor = Colors.deepPurple;
                          } else if (!canBook) {
                            buttonColor = Colors.grey[400]!;
                          } else {
                            buttonColor = Colors.green;
                          }

                          return CustomButton(
                            text: slot.time.format(context),
                            backgroundColor: buttonColor,
                            onPressed: canBook
                                ? () {
                                    setState(() {
                                      _selectedTime = slot.time;
                                    });
                                  }
                                : () {},
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
                    child: CustomButton(
                      text: 'Confirmar Cita',
                      onPressed: _bookAppointment,
                      icon: Icons.check_circle_outline,
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
