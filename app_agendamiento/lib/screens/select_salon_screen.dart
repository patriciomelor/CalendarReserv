// lib/screens/select_salon_screen.dart

import 'package:agend_app/screens/select_service_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final isDarkMode = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Elige un Salón',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: theme.primaryColor,
        foregroundColor: theme.colorScheme.onPrimary,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barra de Búsqueda
          _buildSearchBar(theme, isDarkMode),

          // Lista de Salones
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('salons').snapshots(),
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
                  final name = data['name']?.toString().toLowerCase() ?? '';
                  final address = data['address']?.toString().toLowerCase() ?? '';
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

                    return _buildSalonCard(theme, salon, salonData);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // --- Widgets Refactorizados ---

  Widget _buildSearchBar(ThemeData theme, bool isDarkMode) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        onChanged: (value) => setState(() => _searchQuery = value),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre o dirección...',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: isDarkMode ? Colors.grey[800] : Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 15),
        ),
      ),
    );
  }

  Widget _buildSalonCard(
      ThemeData theme, DocumentSnapshot salon, Map<String, dynamic> salonData) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        title: Text(
          salonData['name'] ?? 'Salón sin Nombre',
          style: GoogleFonts.lato(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: theme.colorScheme.primary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            salonData['address'] ?? 'Sin Dirección',
            style: GoogleFonts.lato(
              fontSize: 14,
              color: theme.colorScheme.secondary,
            ),
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          color: theme.colorScheme.primary,
          size: 18,
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SelectServiceScreen(salonId: salon.id),
            ),
          );
        },
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
              style: GoogleFonts.lato(
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