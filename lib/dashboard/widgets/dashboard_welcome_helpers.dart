import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class DashboardWelcomeHelpers {
  static String getWelcomeMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'صبح بخیر';
    if (hour < 17) return 'ظهر بخیر';
    if (hour < 20) return 'عصر بخیر';
    return 'شب بخیر';
  }

  static IconData getWelcomeIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return LucideIcons.sun;
    if (hour < 17) return LucideIcons.sun;
    if (hour < 20) return LucideIcons.sunset;
    return LucideIcons.moon;
  }
}
