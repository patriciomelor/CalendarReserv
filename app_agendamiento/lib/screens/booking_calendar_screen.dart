// lib/screens/booking_calendar_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

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

  @override
  Widget build(BuildContext context) {
    final serviceData = widget.service.data() as Map<String, dynamic>;
    final professionalData = widget.professional.data() as Map<String, dynamic>;

    return Scaffold(
      appBar: AppBar(
        title: const Text('3. Selecciona Fecha y Hora'),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Resumen de la selección
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

              // Calendario
              TableCalendar(
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
                  // Aquí irá la lógica para mostrar las horas disponibles
                  print('Día seleccionado: $_selectedDay');
                },
              ),
              const Divider(height: 30),

              // Esta sección mostrará las horas disponibles en la siguiente fase
              if (_selectedDay != null)
                const Center(
                  child: Text('Próximo paso: Mostrar horas disponibles aquí.'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
