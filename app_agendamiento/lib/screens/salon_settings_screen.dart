// lib/screens/salon_settings_screen.dart

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

  // Mapa para los días de la semana
  Map<int, bool> _workDays = {
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
      appBar: AppBar(
        title: const Text('Configuración del Salón'),
        backgroundColor: Colors.orange,
      ),
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
                      decoration: const InputDecoration(
                        labelText: 'Nombre del Salón',
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _openingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Hora de Apertura (formato HH:mm)',
                      ),
                      validator: (value) =>
                          !RegExp(r'^\d{2}:\d{2}$').hasMatch(value!)
                          ? 'Formato inválido'
                          : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _closingTimeController,
                      decoration: const InputDecoration(
                        labelText: 'Hora de Cierre (formato HH:mm)',
                      ),
                      validator: (value) =>
                          !RegExp(r'^\d{2}:\d{2}$').hasMatch(value!)
                          ? 'Formato inválido'
                          : null,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      'Días de Atención:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
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
                    }).toList(),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        child: const Text('Guardar Cambios'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
