import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static ThemeData darkGoldTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: const Color(0xFFFFD700),
    scaffoldBackgroundColor: const Color(0xFF181818),
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFFFD700),
      secondary: Color(0xFF181818),
      surface: Color(0xFF232323),
      onPrimary: Colors.black,
      onSecondary: Color(0xFFFFD700),
    ),
    textTheme: GoogleFonts.vazirmatnTextTheme().apply(
      bodyColor: Colors.white,
      displayColor: const Color(0xFFFFD700),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFFFD700),
        foregroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        elevation: 8,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF232323),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFD700)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFFFD700)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF232323),
      contentTextStyle: const TextStyle(color: Color(0xFFFFD700)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF181818),
      foregroundColor: Color(0xFFFFD700),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: Color(0xFFFFD700),
        fontWeight: FontWeight.bold,
        fontSize: 22,
      ),
    ),
  );
}
