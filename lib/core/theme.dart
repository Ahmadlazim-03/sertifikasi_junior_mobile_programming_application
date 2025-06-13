import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF8B4513); // Cokelat tua
  static const Color secondaryColor = Color(0xFFF5DEB3); // Krem
  static const Color accentColor = Color(0xFFFFA500); // Oranye

  static final ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.white,
    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      titleTextStyle: GoogleFonts.pacifico(
        color: Colors.white,
        fontSize: 24,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    textTheme: TextTheme(
      displayLarge: GoogleFonts.pacifico(fontSize: 32, fontWeight: FontWeight.bold, color: primaryColor),
      headlineSmall: GoogleFonts.poppins(fontSize: 24, fontWeight: FontWeight.bold),
      titleLarge: GoogleFonts.poppins(fontSize: 20, fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.poppins(fontSize: 16, color: Colors.black87),
      labelLarge: GoogleFonts.poppins(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: accentColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 16),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: secondaryColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor),
      ),
      filled: true,
      fillColor: secondaryColor.withOpacity(0.2),
    ),
  );
}