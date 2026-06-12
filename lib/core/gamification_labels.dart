import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// نام‌گذاری یکپارچه:
/// - [points] / [pointsIcon]: امتیاز فعالیت کاربر (تمرین، تغذیه، استریک، لیگ)
/// - [stars] / [starsIcon]: ستارهٔ پاداش دستاوردها (فقط با باز شدن دستاورد)
abstract final class GamificationLabels {
  static const String points = 'امتیاز';
  static const String stars = 'ستاره';

  static const IconData pointsIcon = LucideIcons.sparkles;
  static const IconData starsIcon = LucideIcons.star;
  static const IconData achievementsIcon = LucideIcons.trophy;

  static String pointsUnit(int value) => '$value $points';
  static String starsUnit(int value) => '$value $stars';
}
