// lib/screens/professional_agenda_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final textColor = const Color(0xFF333333);

    final startOfDay = DateTime(
      _selectedDay.year,
      _selectedDay.month,
      _selectedDay.day,
    );
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: professionalId == null
          ? Center(
              child: Text(
                'Error: tu cuenta no está vinculada a un perfil de profesional.',
                style: GoogleFonts.poppins(color: Colors.red[700]),
              ),
            )
          : CustomScrollView(
              slivers: [
                SliverAppBar(
                  pinned: true,
                  title: Text(
                    'Mi Agenda',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: textColor, fontSize: 22),
                  ),
                  centerTitle: false,
                  elevation: 0,
                  backgroundColor: const Color(0xFFF8F9FA),
                  foregroundColor: textColor,
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
                              content: Text(
                                'Enlace de reserva copiado al portapapeles.',
                                style: GoogleFonts.poppins(),
                              ),
                              backgroundColor: const Color(0xFF4A90E2),
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
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(1.0),
                    child: Container(
                      color: Colors.grey[200],
                      height: 1.0,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: _buildCalendar(),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16.0, 24.0, 16.0, 8.0),
                    child: Text(
                      'Citas para el ${DateFormat('d MMM yyyy', 'es_ES').format(_selectedDay)}',
                      style: GoogleFonts.poppins(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                  ),
                ),
                _buildAppointmentList(professionalId, startOfDay, endOfDay),
              ],
            ),
    );
  }

  Widget _buildCalendar() {
    return Container(
      margin: const EdgeInsets.all(16),
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
            color: const Color(0xFF4A90E2).withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          selectedDecoration: const BoxDecoration(
            color: Color(0xFF4A90E2),
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: HeaderStyle(
          titleCentered: true,
          titleTextStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold, fontSize: 16),
          formatButtonVisible: false,
        ),
      ),
    );
  }

  Widget _buildAppointmentList(
      String professionalId, DateTime startOfDay, DateTime endOfDay) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('appointments')
          .where('professionalId', isEqualTo: professionalId)
          .where('status', isEqualTo: 'confirmada')
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
                style: GoogleFonts.poppins(fontSize: 16, color: Colors.grey[600]),
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    leading: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4A90E2).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        DateFormat('HH:mm').format(startTime),
                        style: GoogleFonts.poppins(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF4A90E2),
                          fontSize: 16,
                        ),
                      ),
                    ),
                    title: Text(
                      appointment['customerName'] ?? 'Cliente',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600, color: const Color(0xFF333333)),
                    ),
                    subtitle: Text(
                      appointment['customerEmail'] ?? 'No especificado',
                      style: GoogleFonts.poppins(color: Colors.grey[600]),
                    ),
                    trailing: PopupMenuButton<String>(
                      onSelected: (_) => _cancelAppointment(context, appointmentDoc),
                      itemBuilder: (context) => [
                        PopupMenuItem(
                          value: 'cancel',
                          child: Text('Cancelar Cita', style: GoogleFonts.poppins()),
                        ),
                      ],
                      icon: Icon(Icons.more_vert, color: Colors.grey[600]),
                    ),
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