import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // رنگ‌های اصلی
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);
  static const Color backgroundColor = Color(0xFF121212);
  static const Color cardColor = Color(0xFF1E1E1E);
  static const Color accentColor = Color(0xFFFFD700);
  static const Color primaryColor = Color(0xFF1976D2);
  static const Color textColor = Colors.white;

  // استایل‌های متن
  static TextStyle headingStyle = TextStyle(
    color: Colors.white,
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
  );

  static TextStyle subheadingStyle = TextStyle(
    color: goldColor,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
  );

  static TextStyle bodyStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.6),
    fontSize: 16.sp,
  );

  // دکوریشن‌های مشترک
  static BoxDecoration cardDecoration = BoxDecoration(
    color: cardColor,
    borderRadius: BorderRadius.circular(20.r),
    border: Border.all(color: goldColor.withValues(alpha: 0.1)),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.1),
        blurRadius: 8.r,
        offset: Offset(0.w, 4.h),
      ),
    ],
  );

  static BoxDecoration gradientDecoration = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [darkGold, goldColor, accentColor.withValues(alpha: 0.1)],
    ),
    borderRadius: BorderRadius.circular(20.r),
  );

  // استایل دکمه‌ها
  static ButtonStyle primaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: goldColor,
    foregroundColor: Colors.white,
    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15.r)),
  );

  static ButtonStyle secondaryButtonStyle = ElevatedButton.styleFrom(
    backgroundColor: Colors.transparent,
    foregroundColor: goldColor,
    padding: EdgeInsets.symmetric(horizontal: 32.w, vertical: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(15.r),
      side: const BorderSide(color: goldColor),
    ),
  );

  // استایل فیلدهای ورودی
  static InputDecoration textFieldDecoration(String label, {String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      labelStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
      hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.1)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: BorderSide(color: goldColor.withValues(alpha: 0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15.r),
        borderSide: const BorderSide(color: goldColor),
      ),
      filled: true,
      fillColor: cardColor,
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16),
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
          borderRadius: BorderRadius.circular(16.r),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        elevation: 8,
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF232323),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFFFD700)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: Color(0xFFFFD700), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFFFFD700)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF232323),
      contentTextStyle: const TextStyle(color: Color(0xFFFFD700)),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF181818),
      foregroundColor: const Color(0xFFFFD700),
      elevation: 0,
      titleTextStyle: TextStyle(
        color: const Color(0xFFFFD700),
        fontWeight: FontWeight.bold,
        fontSize: 22.sp,
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: const BorderSide(color: goldColor),
      ),
      titleTextStyle: TextStyle(
        color: goldColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: Colors.white.withValues(alpha: 0.1),
        fontSize: 14.sp,
      ),
    ),
  );
}
