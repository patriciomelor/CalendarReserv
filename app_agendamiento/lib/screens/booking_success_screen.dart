// lib/screens/booking_success_screen.dart

import 'package:agend_app/screens/login_or_register_screen.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:flutter/material.dart';

class BookingSuccessScreen extends StatelessWidget {
  const BookingSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(
        title: '¡Cita Confirmada!',
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 100),
              const SizedBox(height: 20),
              Text(
                '¡Tu cita ha sido agendada con éxito!',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                'Recibirás un correo electrónico con los detalles.',
                style: Theme.of(context).textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              CustomButton(
                text: 'Volver al Inicio',
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => LoginOrRegisterScreen(),
                    ),
                    (route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}