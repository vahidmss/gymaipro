import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Navigation constants and configurations for the GymAI app
class NavigationConstants {
  // Private constructor to prevent instantiation
  NavigationConstants._();

  // Navigation indices (updated)
  static const int chatIndex = 0; // AI Hub / Chat
  static const int academyIndex = 1;
  static const int dashboardIndex = 2; // central button
  static const int roleIndex =
      3; // role-based (athlete: ranking, trainer: dashboard)
  static const int profileIndex = 4;

  // Navigation labels
  static const String chatLabel = 'جیم‌آی';
  static const String academyLabel = 'آکادمی';
  static const String dashboardLabel = 'داشبورد';
  static const String roleLabel =
      'مربیان'; // generic label (trainer view will still work)
  static const String profileLabel = 'پروفایل';

  // Navigation icons
  static const IconData chatIcon = LucideIcons.bot;
  static const IconData academyIcon = LucideIcons.school;
  static const IconData dashboardIcon = LucideIcons.home;
  static const IconData roleIcon = LucideIcons.users;
  static const IconData profileIcon = LucideIcons.user;

  // Navigation routes
  static const String chatRoute = '/chat-main';
  static const String dashboardRoute = '/dashboard';
  static const String profileRoute = '/profile';
  // legacy routes kept for deep links within dashboard sections
  static const String workoutProgramBuilderRoute = '/workout-program-builder';
  static const String workoutLogRoute = '/workout-log';
  static const String exerciseListRoute = '/exercise-list';
  static const String exerciseDetailRoute = '/exercise-detail';
  static const String mealPlanBuilderRoute = '/meal-plan-builder';
  static const String mealLogRoute = '/meal-log';
  static const String foodListRoute = '/food-list';
  static const String favoriteFoodsRoute = '/favorite-foods';

  // Animation durations
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration navItemAnimationDuration = Duration(milliseconds: 200);
  static const Duration logoAnimationDuration = Duration(milliseconds: 500);

  // Animation curves
  static const Curve pageTransitionCurve = Curves.easeInOut;
  static const Curve navItemAnimationCurve = Curves.easeInOut;

  // Bottom navigation dimensions
  static const double bottomNavHeight = 90;
  static const double centralButtonSize = 70;
  static const double navItemIconSize = 20;
  static const double navItemFontSize = 10;

  // Spacing and padding
  static const double navItemPadding = 8;
  static const double navItemSpacing = 4;
  static const double centralButtonPadding = 15;

  // Action card configurations
  static const double actionCardPadding = 20;
  static const double actionCardBorderRadius = 16;
  static const double actionCardIconSize = 24;
  static const double actionCardSpacing = 16;

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
    'favorite_foods': {
      'title': 'غذاهای مورد علاقه',
      'subtitle': 'غذاهای مورد علاقه شما',
      'icon': Icons.favorite,
      'route': favoriteFoodsRoute,
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
    'favorite_foods': Color(0xFFE91E63), // Pink
  };

  // Navigation item configurations (used by some widgets)
  static const List<Map<String, dynamic>> navigationItems = [
    {
      'index': chatIndex,
      'label': chatLabel,
      'icon': chatIcon,
      'route': chatRoute,
    },
    {
      'index': academyIndex,
      'label': academyLabel,
      'icon': academyIcon,
      'route': null, // rendered as a tab page
    },
    {
      'index': dashboardIndex,
      'label': dashboardLabel,
      'icon': dashboardIcon,
      'route': dashboardRoute,
    },
    {
      'index': roleIndex,
      'label': roleLabel,
      'icon': roleIcon,
      'route': null, // role-based tab page
    },
    {
      'index': profileIndex,
      'label': profileLabel,
      'icon': profileIcon,
      'route': profileRoute,
    },
  ];

  // GymAI Logo configurations
  static const double defaultLogoSize = 40;
  static const double centralLogoSize = 25;
  static const bool defaultLogoAnimation = false;
  static const double logoBorderWidth = 1.5;
  static const double logoShadowBlur = 6;
  static const double logoShadowOffset = 2;

  // Error messages
  static const String navigationError = 'خطا در ناوبری';
  static const String routeNotFoundError = 'مسیر مورد نظر یافت نشد';
  static const String navigationTimeoutError =
      'زمان انتظار ناوبری به پایان رسید';

  // Success messages
  static const String navigationSuccess = 'ناوبری با موفقیت انجام شد';
  static const String pageTransitionSuccess = 'انتقال صفحه با موفقیت انجام شد';
}
