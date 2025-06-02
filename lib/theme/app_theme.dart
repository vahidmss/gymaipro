import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // رنگ‌های اصلی
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700);

  // استایل‌های متن
  static const TextStyle headingStyle = TextStyle(
    color: Colors.white,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  static const TextStyle subheadingStyle = TextStyle(
    color: goldColor,
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyStyle = TextStyle(
    color: Colors.white.withOpacity(0.8),
    fontSize: 16,
  );

  // دکوریشن‌های مشترک
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20),
    border: Border.all(color: goldColor.withOpacity(0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.1),
        blurRadius: 8,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        darkGold,
        goldColor,
        accentColor.withOpacity(0.8),
      ],
    ),
    borderRadius: BorderRadius.circular(20),
  );

  // استایل دکمه‌ها
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: goldColor,
    foregroundColor: Colors.white,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
    ),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: goldColor,
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15),
      side: const BorderSide(color: goldColor),
    ),
  );

  // استایل فیلدهای ورودی
  static InputDecoration textFieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: BorderSide(color: goldColor.withOpacity(0.3)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: goldColor),
      ),
      filled: true,
      fillColor: cardColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
    );
  }

  static ThemeData get darkTheme => darkGoldTheme;

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
    dialogTheme: DialogTheme(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: goldColor, width: 1),
      ),
      titleTextStyle: const TextStyle(
        color: goldColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.white.withOpacity(0.9),
        fontSize: 14,
      ),
    ),
  );
}
