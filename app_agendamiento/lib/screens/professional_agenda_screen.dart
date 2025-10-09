// lib/screens/professional_agenda_screen.dart

import 'package:agend_app/widgets/CustomCard.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import 'package:agend_app/services/notification_service.dart';

class ProfessionalAgendaScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const ProfessionalAgendaScreen({super.key, required this.userData});

  @override
  State<ProfessionalAgendaScreen> createState() =>
      _ProfessionalAgendaScreenState();
}

class _ProfessionalAgendaScreenState extends State<ProfessionalAgendaScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime _selectedDay = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final professionalId = widget.userData['professionalId'];
    final salonId = widget.userData['salonId'];
    final theme = Theme.of(context);

    final startOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    if (professionalId == null || salonId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Error de Configuración')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Tu cuenta de profesional no está configurada correctamente. '
              'Falta el ID de profesional o el ID del salón. '
              'Por favor, contacta al administrador.',
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.error, fontSize: 16),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            title: Text('Mi Agenda (ID: $professionalId)'),
            centerTitle: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.share_outlined),
                tooltip: 'Copiar mi enlace de reserva',
                onPressed: () {
                  if (salonId != null && professionalId != null) {
                    final webUrl = Uri.base;
                    final bookingUrl =
                        '${webUrl.origin}/#/book/$salonId/$professionalId';
                    Clipboard.setData(ClipboardData(text: bookingUrl));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Enlace de reserva copiado al portapapeles.',
                        ),
                        backgroundColor: theme.primaryColor,
                      ),
                    );
                  }
                },
              ),
              IconButton(
                icon: const Icon(Icons.logout_outlined),
                onPressed: () => FirebaseAuth.instance.signOut(),
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: _buildCalendar(theme),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
              child: Text(
                'Citas para el ${DateFormat('d MMM yyyy', 'es_ES').format(_selectedDay)}',
                style: theme.textTheme.headlineSmall,
              ),
            ),
          ),
          _buildAppointmentList(professionalId, startOfDay, endOfDay, theme),
        ],
      ),
    );
  }

  Widget _buildCalendar(ThemeData theme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: TableCalendar(
        locale: 'es_ES',
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 365)),
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
    );
  }

  Widget _buildAppointmentList(
      String professionalId, DateTime startOfDay, DateTime endOfDay, ThemeData theme) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('professionalId', isEqualTo: professionalId)
          .where('status', whereIn: ['confirmada', 'pendiente'])
          .where(
            'startTime',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay),
          )
          .where('startTime', isLessThan: Timestamp.fromDate(endOfDay))
          .orderBy('startTime')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                'No tienes citas para este día.',
                style: theme.textTheme.titleMedium,
              ),
            ),
          );
        }
        final appointments = snapshot.data!.docs;
        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final appointmentDoc = appointments[index];
                final appointment = appointmentDoc.data() as Map<String, dynamic>;
                final startTime = (appointment['startTime'] as Timestamp).toDate();
                final status = appointment['status'];
                return CustomCard(
                  title: appointment['customerName'] ?? 'Cliente',
                  subtitle: appointment['customerEmail'] ?? 'No especificado',
                  icon: Icons.person,
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(status),
                      PopupMenuButton<String>(
                        onSelected: (_) => _cancelAppointment(context, appointmentDoc),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'cancel',
                            child: Text('Cancelar Cita'),
                          ),
                        ],
                        icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                );
              },
              childCount: appointments.length,
            ),
          ),
        );
      },
    );
  }

  Future<void> _cancelAppointment(
      BuildContext context, DocumentSnapshot appointmentDoc) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar Cancelación'),
        content: const Text(
            '¿Estás seguro de que quieres cancelar esta cita? Se notificará al cliente.'),
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
        await appointmentDoc.reference.update({'status': 'cancelada'});

        final appointmentData = appointmentDoc.data() as Map<String, dynamic>;
        final customerEmail = appointmentData['customerEmail'];
        final customerName = appointmentData['customerName'];
        final startTime = (appointmentData['startTime'] as Timestamp).toDate();
        final formattedDate = DateFormat('d/M/y').format(startTime);
        final formattedTime = DateFormat('HH:mm').format(startTime);

        if (customerEmail != null) {
          await NotificationService.sendEmail(
            to: customerEmail,
            subject: 'Tu cita ha sido cancelada',
            htmlBody:
                '''<h1>Hola $customerName,</h1><p>Lamentamos informarte que tu cita para el <strong>$formattedDate a las $formattedTime</strong> ha sido cancelada por el profesional.</p><p>Por favor, si lo deseas, puedes volver a agendar otra cita.</p>''',
          );
        }

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cita cancelada y cliente notificado.'),
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
