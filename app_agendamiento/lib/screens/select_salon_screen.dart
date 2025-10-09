// lib/screens/select_salon_screen.dart

import 'package:agend_app/screens/select_service_screen.dart';
import 'package:agend_app/widgets/CustomCard.dart';
import 'package:agend_app/widgets/custom_appbar.dart';
import 'package:agend_app/widgets/custom_text_field.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SelectSalonScreen extends StatefulWidget {
  const SelectSalonScreen({super.key});

  @override
  State<SelectSalonScreen> createState() => _SelectSalonScreenState();
}

class _SelectSalonScreenState extends State<SelectSalonScreen> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: const CustomAppBar(
        title: 'Elige un Salón',
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: InputDecoration(
                labelText: 'Buscar por nombre o dirección...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),

          // Lista de Salones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('salones').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return _buildFeedbackCard(
                    icon: Icons.error_outline,
                    message: 'Error al cargar los salones.',
                    color: theme.colorScheme.error,
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return _buildFeedbackCard(
                    icon: Icons.store_mall_directory_outlined,
                    message: 'No hay salones disponibles.',
                    color: theme.colorScheme.secondary,
                  );
                }

                // Filtrar salones según la búsqueda
                final filteredSalons = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = data['nombre']?.toString().toLowerCase() ?? '';
                  final address = data['direccion']?.toString().toLowerCase() ?? '';
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || address.contains(query);
                }).toList();

                if (filteredSalons.isEmpty) {
                  return _buildFeedbackCard(
                    icon: Icons.search_off_outlined,
                    message: 'No se encontraron salones.',
                    color: theme.colorScheme.secondary,
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: filteredSalons.length,
                  itemBuilder: (context, index) {
                    final salon = filteredSalons[index];
                    final salonData = salon.data() as Map<String, dynamic>;

                    return CustomCard(
                      title: salonData['name'] ?? 'Salón sin Nombre',
                      subtitle: salonData['address'] ?? 'Sin Dirección',
                      icon: Icons.store,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                SelectServiceScreen(salonId: salon.id),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackCard(
      {required IconData icon, required String message, required Color color}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color.withOpacity(0.7)),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}