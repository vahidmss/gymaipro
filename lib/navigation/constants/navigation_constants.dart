import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Navigation constants and configurations for the GymAI app
class NavigationConstants {
  // Private constructor to prevent instantiation
  NavigationConstants._();

  // Navigation indices
  static const int chatIndex = 0;
  static const int workoutIndex = 1;
  static const int dashboardIndex = 2;
  static const int nutritionIndex = 3;
  static const int profileIndex = 4;

  // Navigation labels
  static const String chatLabel = 'چت';
  static const String workoutLabel = 'تمرین';
  static const String dashboardLabel = 'داشبورد';
  static const String nutritionLabel = 'تغذیه';
  static const String profileLabel = 'پروفایل';

  // Navigation icons
  static const IconData chatIcon = LucideIcons.messageCircle;
  static const IconData workoutIcon = LucideIcons.dumbbell;
  static const IconData dashboardIcon = LucideIcons.home;
  static const IconData nutritionIcon = LucideIcons.apple;
  static const IconData profileIcon = LucideIcons.user;

  // Navigation routes
  static const String chatRoute = '/chat-main';
  static const String workoutProgramBuilderRoute = '/workout-program-builder';
  static const String workoutLogRoute = '/workout-log';
  static const String exerciseListRoute = '/exercise-list';
  static const String dashboardRoute = '/dashboard';
  static const String mealPlanBuilderRoute = '/meal-plan-builder';
  static const String mealLogRoute = '/meal-log';
  static const String foodListRoute = '/food-list';
  static const String profileRoute = '/profile';

  // Animation durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration navItemAnimationDuration = Duration(milliseconds: 200);
  static const Duration logoAnimationDuration = Duration(milliseconds: 500);

  // Animation curves
  static const Curve pageTransitionCurve = Curves.easeInOut;
  static const Curve navItemAnimationCurve = Curves.easeInOut;

  // Bottom navigation dimensions
  static const double bottomNavHeight = 90.0;
  static const double centralButtonSize = 70.0;
  static const double navItemIconSize = 20.0;
  static const double navItemFontSize = 10.0;

  // Spacing and padding
  static const double navItemPadding = 8.0;
  static const double navItemSpacing = 4.0;
  static const double centralButtonPadding = 15.0;

  // Action card configurations
  static const double actionCardPadding = 20.0;
  static const double actionCardBorderRadius = 16.0;
  static const double actionCardIconSize = 24.0;
  static const double actionCardSpacing = 16.0;

  // Workout section action cards
  static const Map<String, Map<String, dynamic>> workoutActions = {
    'program_builder': {
      'title': 'ساخت برنامه تمرینی',
      'subtitle': 'برنامه تمرینی جدید بسازید',
      'icon': Icons.fitness_center,
      'route': workoutProgramBuilderRoute,
    },
    'workout_log': {
      'title': 'ثبت برنامه تمرینی',
      'subtitle': 'تمرینات خود را ثبت کنید',
      'icon': Icons.edit_note,
      'route': workoutLogRoute,
    },
    'exercise_list': {
      'title': 'لیست تمرینات',
      'subtitle': 'مشاهده تمام تمرینات',
      'icon': Icons.list_alt,
      'route': exerciseListRoute,
    },
  };

  // Nutrition section action cards
  static const Map<String, Map<String, dynamic>> nutritionActions = {
    'meal_plan_builder': {
      'title': 'ساخت برنامه غذایی',
      'subtitle': 'برنامه غذایی جدید بسازید',
      'icon': Icons.restaurant_menu,
      'route': mealPlanBuilderRoute,
    },
    'meal_log': {
      'title': 'ثبت برنامه غذایی',
      'subtitle': 'غذاهای خود را ثبت کنید',
      'icon': Icons.edit_note,
      'route': mealLogRoute,
    },
    'food_list': {
      'title': 'لیست غذاها',
      'subtitle': 'مشاهده تمام غذاها',
      'icon': Icons.list_alt,
      'route': foodListRoute,
    },
  };

  // Color configurations for action cards
  static const Map<String, Color> actionCardColors = {
    'workout_program': Color(0xFFFFD700), // Gold
    'workout_log': Color(0xFF2196F3), // Blue
    'exercise_list': Color(0xFF4CAF50), // Green
    'meal_plan': Color(0xFFFF9800), // Orange
    'meal_log': Color(0xFF9C27B0), // Purple
    'food_list': Color(0xFF009688), // Teal
  };

  // Navigation item configurations
  static const List<Map<String, dynamic>> navigationItems = [
    {
      'index': chatIndex,
      'label': chatLabel,
      'icon': chatIcon,
      'route': chatRoute,
    },
    {
      'index': workoutIndex,
      'label': workoutLabel,
      'icon': workoutIcon,
      'route': null, // Custom section
    },
    {
      'index': dashboardIndex,
      'label': dashboardLabel,
      'icon': dashboardIcon,
      'route': dashboardRoute,
    },
    {
      'index': nutritionIndex,
      'label': nutritionLabel,
      'icon': nutritionIcon,
      'route': null, // Custom section
    },
    {
      'index': profileIndex,
      'label': profileLabel,
      'icon': profileIcon,
      'route': profileRoute,
    },
  ];

  // GymAI Logo configurations
  static const double defaultLogoSize = 40.0;
  static const double centralLogoSize = 25.0;
  static const bool defaultLogoAnimation = false;
  static const double logoBorderWidth = 1.5;
  static const double logoShadowBlur = 6.0;
  static const double logoShadowOffset = 2.0;

  // Error messages
  static const String navigationError = 'خطا در ناوبری';
  static const String routeNotFoundError = 'مسیر مورد نظر یافت نشد';
  static const String navigationTimeoutError =
      'زمان انتظار ناوبری به پایان رسید';

  // Success messages
  static const String navigationSuccess = 'ناوبری با موفقیت انجام شد';
  static const String pageTransitionSuccess = 'انتقال صفحه با موفقیت انجام شد';
}
