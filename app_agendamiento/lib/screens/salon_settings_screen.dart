// lib/screens/salon_settings_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
        _slotsPerTimeController.text = (data['slotsPerTime'] ?? 1)
            .toString(); // Cargar dato

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
                int.tryParse(_slotsPerTimeController.text.trim()) ??
                1, // Guardar dato
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Configuración guardada',
              style: GoogleFonts.poppins(),
            ),
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
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(
          'Configuración del Salón',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.black,
        elevation: 0,
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
                    _buildTextField(_nameController, 'Nombre del Salón'),
                    _buildTextField(
                      _openingTimeController,
                      'Hora de Apertura (HH:mm)',
                      isTime: true,
                    ),
                    _buildTextField(
                      _closingTimeController,
                      'Hora de Cierre (HH:mm)',
                      isTime: true,
                    ),
                    _buildTextField(
                      _slotsPerTimeController,
                      'Cupos por Horario',
                      isNumeric: true,
                    ), // Nuevo campo
                    const SizedBox(height: 20),
                    Text(
                      'Días de Atención:',
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ..._workDays.keys.map((day) {
                      return CheckboxListTile(
                        title: Text(
                          _dayNames[day]!,
                          style: GoogleFonts.poppins(),
                        ),
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
                      child: ElevatedButton(
                        onPressed: _saveSettings,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueAccent,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.all(16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Guardar Cambios',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label, {
    bool isTime = false,
    bool isNumeric = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.poppins(),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo requerido';
          }
          if (isTime && !RegExp(r'^\d{2}:\d{2}$').hasMatch(value)) {
            return 'Formato inválido (HH:mm)';
          }
          if (isNumeric && int.tryParse(value) == null) {
            return 'Debe ser un número';
          }
          if (isNumeric && int.parse(value) <= 0) {
            return 'Debe ser un número mayor a 0';
          }
          return null;
        },
      ),
    );
  }
}
