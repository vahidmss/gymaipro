import 'package:flutter/material.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// GymAI typography tokens — RTL-first, project font family.
abstract final class GymTypography {
  static const String fontFamily = AppTheme.fontFamily;
  static const TextDirection direction = TextDirection.rtl;

  static const TextStyle display = TextStyle(
    fontFamily: fontFamily,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.6,
  );

  static const TextStyle headline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );

  static const TextStyle title = TextStyle(
    fontFamily: fontFamily,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 15,
    fontWeight: FontWeight.w500,
    height: 1.65,
  );

  static const TextStyle bodyStrong = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    height: 1.5,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static const TextStyle overline = TextStyle(
    fontFamily: fontFamily,
    fontSize: 11,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.6,
  );

  static const TextStyle metric = TextStyle(
    fontFamily: fontFamily,
    fontSize: 28,
    fontWeight: FontWeight.w900,
    height: 1.1,
  );

  static const TextStyle button = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.2,
  );

  static TextTheme textTheme = const TextTheme(
    displayLarge: display,
    displayMedium: headline,
    displaySmall: title,
    headlineMedium: title,
    titleLarge: title,
    titleMedium: bodyStrong,
    bodyLarge: body,
    bodyMedium: body,
    bodySmall: caption,
    labelLarge: button,
    labelMedium: caption,
    labelSmall: overline,
  );
}
