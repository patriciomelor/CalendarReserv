// lib/screens/salon_settings_screen.dart

import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_button.dart';
import 'package:agend_app/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SalonSettingsScreen extends StatefulWidget {
  final String salonId;
  const SalonSettingsScreen({super.key, required this.salonId});

  @override
  State<SalonSettingsScreen> createState() => _SalonSettingsScreenState();
}

class _SalonSettingsScreenState extends State<SalonSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _openingTimeController = TextEditingController();
  final _closingTimeController = TextEditingController();
  final _slotsPerTimeController = TextEditingController(); // Nuevo controlador

  final Map<int, bool> _workDays = {
    1: false, // Lunes
    2: false, // Martes
    3: false, // Miércoles
    4: false, // Jueves
    5: false, // Viernes
    6: false, // Sábado
    7: false, // Domingo
  };
  final Map<int, String> _dayNames = {
    1: 'Lunes',
    2: 'Martes',
    3: 'Miércoles',
    4: 'Jueves',
    5: 'Viernes',
    6: 'Sábado',
    7: 'Domingo',
  };

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSalonData();
  }

  Future<void> _loadSalonData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('salones')
          .doc(widget.salonId)
          .get();
      if (doc.exists) {
        final data = doc.data()!;
        _nameController.text = data['nombre'] ?? '';
        _openingTimeController.text = data['openingTime'] ?? '09:00';
        _closingTimeController.text = data['closingTime'] ?? '18:00';
        _slotsPerTimeController.text =
            (data['slotsPerTime'] ?? 1).toString(); // Cargar dato

        final workDaysFromDb = List<int>.from(
          data['workDays'] ?? [1, 2, 3, 4, 5],
        );
        setState(() {
          for (var day in _workDays.keys) {
            _workDays[day] = workDaysFromDb.contains(day);
          }
        });
      }
    } catch (e) {
      // Manejar error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _saveSettings() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final selectedDays = _workDays.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await FirebaseFirestore.instance
          .collection('salones')
          .doc(widget.salonId)
          .update({
        'nombre': _nameController.text.trim(),
        'openingTime': _openingTimeController.text.trim(),
        'closingTime': _closingTimeController.text.trim(),
        'workDays': selectedDays,
        'slotsPerTime':
            int.tryParse(_slotsPerTimeController.text.trim()) ?? 1,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Configuración guardada'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: 'Configuración del Salón'),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(labelText: 'Nombre del Salón'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _openingTimeController,
                      decoration: const InputDecoration(labelText: 'Hora de Apertura (HH:mm)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
                          return 'Formato inválido (HH:mm)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _closingTimeController,
                      decoration: const InputDecoration(labelText: 'Hora de Cierre (HH:mm)'),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (!RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
                          return 'Formato inválido (HH:mm)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _slotsPerTimeController,
                      decoration: const InputDecoration(labelText: 'Cupos por Horario'),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Campo requerido';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Debe ser un número';
                        }
                        if (int.parse(value) <= 0) {
                          return 'Debe ser un número mayor a 0';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Días de Atención:',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    ..._workDays.keys.map((day) {
                      return CheckboxListTile(
                        title: Text(_dayNames[day]!),
                        value: _workDays[day],
                        onChanged: (bool? value) {
                          setState(() {
                            _workDays[day] = value!;
                          });
                        },
                      );
                    }),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: CustomButton(
                        text: 'Guardar Cambios',
                        onPressed: _saveSettings,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
