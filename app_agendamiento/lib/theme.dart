import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  primarySwatch: Colors.teal,
  fontFamily: GoogleFonts.montserrat().fontFamily,
  scaffoldBackgroundColor: const Color(0xFFF7F7F7),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    elevation: 0,
    iconTheme: IconThemeData(color: Colors.teal),
    titleTextStyle: TextStyle(
      color: Color(0xFF00695C),
      fontWeight: FontWeight.bold,
      fontSize: 22,
    ),
    centerTitle: true,
  ),
  floatingActionButtonTheme: FloatingActionButtonThemeData(
    backgroundColor: Colors.teal,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(12)),
    ),
  ),
  cardTheme: CardThemeData(
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    elevation: 4,
    margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
  ),
);
