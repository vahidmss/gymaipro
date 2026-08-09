import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نام‌گذاری یکپارچه گیمیفیکیشن:
/// - [points]: تنها ارز — امتیاز لیگ (فعالیت + بونوس دستاورد)
/// - دستاورد = بج؛ پاداش unlock همان [points] است
abstract final class GamificationLabels {
  static const String points = 'امتیاز';
  static const String achievements = 'دستاوردها';
  static const String ranking = 'رتبه‌بندی';
  static const String league = 'لیگ';

  static const IconData pointsIcon = LucideIcons.sparkles;
  static const IconData achievementsIcon = LucideIcons.trophy;
  static const IconData rankingIcon = LucideIcons.medal;

  static String pointsUnit(int value) => '$value $points';
}
