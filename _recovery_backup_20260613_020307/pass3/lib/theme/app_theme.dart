import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class AppTheme {
  // ============================================
  // فونت اصلی اپلیکیشن
  // ============================================
  static const String fontFamily = 'IRANSans';

  // ============================================
  // رنگ‌های طلایی (مشترک بین light و dark)
  // ============================================
  static const Color goldColor = Color(0xFFD4AF37);
  static const Color darkGold = Color(0xFFB8860B);

  // ============================================
  // رنگ‌های Dark Mode
  // ============================================
  static const Color darkBackgroundColor = Color.fromARGB(255, 0, 0, 0);
  static const Color darkCardColor = Color(0xFF1E1E1E);
  static const Color darkTextColor = Colors.white;
  static const Color darkGreySeparator = Color(0xFF393E46);
  static const Color darkGreyGradient = Color(0xFF4A4E5A);
  static const Color veryDarkBackground = Color(0xFF0D0D0D);

  // ============================================
  // رنگ‌های Light Mode (طلایی لوکس)
  // ============================================
  static const Color lightBackgroundColor = Color(
    0xFFFFFCF5,
  ); // سفید کرمی روشن (میانی gradient)
  static const Color lightCardColor = Color(
    0xFFFFFAF5,
  ); // سفید کرمی با تفاوت بیشتر از background
  static const Color lightTextColor = Color(0xFF1A1611); // قهوه‌ای خیلی تیره
  static const Color lightTextSecondary = Color(0xFF5A4E3D); // قهوه‌ای متوسط
  static const Color lightSurfaceColor = Color(0xFFFFFAF0); // سطح روشن
  static const Color lightDividerColor = Color(
    0xFFE5D9C4,
  ); // جداکننده طلایی روشن
  static const Color lightButtonBackground = Color(
    0xFFFFF8E8,
  ); // پس‌زمینه دکمه روشن
  static const Color lightButtonText = Color(0xFF1A1611); // متن دکمه
  static const Color lightGradientStart = Color(
    0xFFFFF5D6,
  ); // شروع gradient طلایی روشن
  static const Color lightGradientEnd = Color(
    0xFFFFE8A3,
  ); // پایان gradient طلایی روشن
  static const Color lightBackgroundGradientStart = Color(
    0xFFFFF8E8,
  ); // شروع gradient پس‌زمینه
  static const Color lightBackgroundGradientMiddle = Color(
    0xFFFFFCF5,
  ); // میانی gradient پس‌زمینه
  static const Color lightBackgroundGradientEnd = Color(
    0xFFFFF5E6,
  ); // پایان gradient پس‌زمینه
  static const Color lightGoldGradient = Color(
    0xFFFFECAF,
  ); // رنگ روشن طلایی برای gradient
  static const Color goldTabIndicator = Color(
    0xFFE7B628,
  ); // خط طلایی زیر تب فعال

  // ============================================
  // رنگ‌های خاکستری Material (برای placeholder)
  // ============================================
  static Color get grey300 => Colors.grey[300]!;
  static Color get grey600 => Colors.grey[600]!;

  // ============================================
  // رنگ‌های معنایی (برای استفاده در ماژول‌های دیگر)
  // ============================================
  static const Color errorColor = Colors.red;
  static const Color successColor = Colors.green;
  static const Color onGoldColor = Color(0xFF0A0A0A); // رنگ تیره روی طلایی

  // رنگ‌های ماکرو (برای نمودارها)
  static const Color proteinColor = Color(0xFF2E7D32); // سبز
  static const Color carbsColor = Color(0xFF1565C0); // آبی
  static const Color fatColor = Color(0xFFEF6C00); // نارنجی

  // رنگ‌های جایگزین برای primaryColor و accentColor
  static const Color primaryColor = goldColor;
  static const Color accentColor = goldColor;

  // ============================================
  // رنگ‌های قدیمی برای سازگاری (deprecated)
  // ============================================
  @Deprecated('Use AppThemeExtension.of(context).backgroundColor instead')
  static const Color backgroundColor = darkBackgroundColor;

  @Deprecated('Use AppThemeExtension.of(context).cardColor instead')
  static const Color cardColor = darkCardColor;

  @Deprecated('Use AppThemeExtension.of(context).textColor instead')
  static const Color textColor = darkTextColor;

  // ============================================
  // استایل‌های متن اصلی
  // ============================================
  static TextStyle headingStyle = TextStyle(
    color: Colors.white,
    fontSize: 24.sp,
    fontWeight: FontWeight.bold,
    fontFamily: fontFamily,
  );

  static TextStyle subheadingStyle = TextStyle(
    color: goldColor,
    fontSize: 18.sp,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static TextStyle bodyStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.6),
    fontSize: 16.sp,
    fontFamily: fontFamily,
  );

  // ============================================
  // استایل‌های دیالوگ (استفاده در داشبورد)
  // ============================================
  static TextStyle dialogTitleStyle = TextStyle(
    color: Colors.white,
    fontSize: 18.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    fontFamily: fontFamily,
  );

  static TextStyle dialogSubtitleStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.65),
    fontSize: 11.sp,
    fontWeight: FontWeight.w500,
    fontFamily: fontFamily,
  );

  static TextStyle dialogValueLabelStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.65),
    fontSize: 10.sp,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    fontFamily: fontFamily,
  );

  static TextStyle dialogValueStyle = TextStyle(
    color: Colors.white,
    fontSize: 32.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.8,
    height: 1.1,
    fontFamily: fontFamily,
  );

  static TextStyle dialogUnitStyle = TextStyle(
    color: goldColor,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
    fontFamily: fontFamily,
  );

  static TextStyle dialogDescriptionStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.8),
    fontSize: 13.sp,
    height: 1.7,
    letterSpacing: 0.2,
    fontFamily: fontFamily,
  );

  static TextStyle dialogKeyPointsTitleStyle = TextStyle(
    color: goldColor,
    fontSize: 13.sp,
    fontWeight: FontWeight.bold,
    letterSpacing: 0.3,
    fontFamily: fontFamily,
  );

  static TextStyle dialogKeyPointStyle = TextStyle(
    color: Colors.white.withValues(alpha: 0.85),
    fontSize: 12.sp,
    height: 1.5,
    fontFamily: fontFamily,
  );

  static TextStyle dialogButtonStyle = TextStyle(
    fontWeight: FontWeight.bold,
    fontSize: 14.sp,
    letterSpacing: 0.3,
    fontFamily: fontFamily,
  );

  // ============================================
  // دکوریشن‌های مشترک (برای استفاده در ماژول‌های دیگر)
  // ============================================
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
      colors: [darkGold, goldColor, goldColor.withValues(alpha: 0.1)],
    ),
    borderRadius: BorderRadius.circular(20.r),
  );

  // ============================================
  // استایل دکمه‌ها
  // ============================================
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

  // ============================================
  // استایل فیلدهای ورودی
  // ============================================
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

  // ============================================
  // تم‌های Material
  // ============================================
  static ThemeData get darkTheme => darkGoldTheme;
  static ThemeData get lightTheme => lightGoldTheme;

  // تم روشن (طلایی لوکس)
  static ThemeData lightGoldTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: goldColor,
    scaffoldBackgroundColor: lightBackgroundGradientMiddle,
    colorScheme: const ColorScheme.light(
      primary: Color(0xFFD4AF37), // طلایی اصلی
      secondary: Color(0xFFB8860B), // طلایی تیره
      surface: Color(0xFFFFFEF9), // سفید کرمی
      onPrimary: Color(0xFF2C2416), // قهوه‌ای تیره روی طلایی
      onSecondary: Color(0xFFFFFEF9), // کرم روی طلایی تیره
      onSurface: Color(0xFF2C2416), // قهوه‌ای تیره
      surfaceVariant: Color(0xFFFFFBF0), // سطح روشن
      onSurfaceVariant: Color(0xFF6B5D47), // قهوه‌ای متوسط
    ),
    textTheme: ThemeData.light().textTheme.apply(
      bodyColor: lightTextColor,
      displayColor: goldColor,
      fontFamily: fontFamily,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldColor,
        foregroundColor: const Color(0xFF2C2416),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        elevation: 4,
        shadowColor: goldColor.withValues(alpha: 0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: lightCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: lightDividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: goldColor, width: 2),
      ),
      labelStyle: TextStyle(color: goldColor.withValues(alpha: 0.8)),
      hintStyle: TextStyle(color: lightTextSecondary.withValues(alpha: 0.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: lightCardColor,
      contentTextStyle: TextStyle(color: lightTextColor),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: goldColor.withValues(alpha: 0.2)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBackgroundColor,
      foregroundColor: goldColor,
      elevation: 0,
      shadowColor: goldColor.withValues(alpha: 0.1),
      titleTextStyle: TextStyle(
        color: goldColor,
        fontWeight: FontWeight.bold,
        fontSize: 22.sp,
      ),
      iconTheme: const IconThemeData(color: goldColor),
    ),
    cardTheme: CardThemeData(
      color: lightCardColor,
      elevation: 2,
      shadowColor: goldColor.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: goldColor.withValues(alpha: 0.1)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: lightCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: goldColor.withValues(alpha: 0.3), width: 1.5),
      ),
      titleTextStyle: TextStyle(
        color: goldColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: lightTextColor.withValues(alpha: 0.8),
        fontSize: 14.sp,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: lightDividerColor,
      thickness: 1,
      space: 1,
    ),
  );

  // تم تاریک
  static ThemeData darkGoldTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: goldColor,
    scaffoldBackgroundColor: darkBackgroundColor,
    colorScheme: const ColorScheme.dark(
      primary: Color(0xFFD4AF37), // طلایی اصلی
      secondary: Color(0xFFB8860B), // طلایی تیره
      surface: Color(0xFF1E1E1E), // کارت تاریک
      onPrimary: Color(0xFF0A0A0A), // متن تیره روی طلایی
      onSecondary: Color(0xFFFFFFFF), // سفید روی طلایی تیره
      onSurface: Color(0xFFFFFFFF), // متن سفید
      surfaceVariant: Color(0xFF0D0D0D), // سطح خیلی تیره
      onSurfaceVariant: Color(0xFFB0B0B0), // متن خاکستری روشن
    ),
    textTheme: ThemeData.dark().textTheme.apply(
      bodyColor: darkTextColor,
      displayColor: goldColor,
      fontFamily: fontFamily,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: goldColor,
        foregroundColor: onGoldColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        elevation: 4,
        shadowColor: goldColor.withValues(alpha: 0.3),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: darkCardColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: goldColor.withValues(alpha: 0.3)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: BorderSide(color: darkGreySeparator),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.r),
        borderSide: const BorderSide(color: goldColor, width: 2),
      ),
      labelStyle: TextStyle(color: goldColor.withValues(alpha: 0.8)),
      hintStyle: TextStyle(color: darkTextColor.withValues(alpha: 0.6)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: darkCardColor,
      contentTextStyle: TextStyle(color: darkTextColor),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: goldColor.withValues(alpha: 0.2)),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBackgroundColor,
      foregroundColor: goldColor,
      elevation: 0,
      shadowColor: goldColor.withValues(alpha: 0.1),
      titleTextStyle: TextStyle(
        color: goldColor,
        fontWeight: FontWeight.bold,
        fontSize: 22.sp,
      ),
      iconTheme: const IconThemeData(color: goldColor),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: darkCardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20.r),
        side: BorderSide(color: goldColor.withValues(alpha: 0.3), width: 1.5),
      ),
      titleTextStyle: TextStyle(
        color: goldColor,
        fontSize: 18.sp,
        fontWeight: FontWeight.bold,
      ),
      contentTextStyle: TextStyle(
        color: darkTextColor.withValues(alpha: 0.8),
        fontSize: 14.sp,
      ),
    ),
    dividerTheme: DividerThemeData(
      color: darkGreySeparator,
      thickness: 1,
      space: 1,
    ),
  );
}

// ============================================
// Extension برای دسترسی آسان به رنگ‌های تم
// ============================================
extension AppThemeExtension on BuildContext {
  // رنگ‌های اصلی بر اساس تم
  Color get backgroundColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkBackgroundColor
        : AppTheme.lightBackgroundColor;
  }

  Color get cardColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : AppTheme.lightCardColor;
  }

  Color get textColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextColor
        : AppTheme.lightTextColor;
  }

  Color get textSecondary {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextColor.withValues(alpha: 0.6)
        : AppTheme.lightTextSecondary;
  }

  // رنگ‌های جداکننده بر اساس تم
  Color get separatorColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkGreySeparator
        : AppTheme.lightDividerColor;
  }

  // رنگ‌های gradient بر اساس تم
  Color get gradientStartColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkGreyGradient
        : AppTheme.lightGoldGradient;
  }

  // رنگ پس‌زمینه خیلی تیره/روشن
  Color get veryDarkBackground {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.veryDarkBackground
        : AppTheme.lightSurfaceColor;
  }

  // رنگ‌های دکمه بر اساس تم
  Color get buttonBackground {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : AppTheme.lightButtonBackground;
  }

  Color get buttonText {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? AppTheme.darkTextColor
        : AppTheme.lightButtonText;
  }

  // رنگ‌های gradient طلایی بر اساس تم
  List<Color> get goldGradientColors {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? [AppTheme.darkGold, AppTheme.goldColor]
        : [AppTheme.lightGradientStart, AppTheme.lightGradientEnd];
  }

  // رنگ‌های placeholder برای تصاویر
  Color get placeholderColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppTheme.grey300 : Colors.grey[200]!;
  }

  Color get placeholderIconColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark ? AppTheme.grey600 : Colors.grey[400]!;
  }

  Color get headerShadowColor {
    final brightness = Theme.of(this).brightness;
    return brightness == Brightness.dark
        ? Colors.black.withValues(alpha: 0.35)
        : Colors.black.withValues(alpha: 0.06);
  }
}
