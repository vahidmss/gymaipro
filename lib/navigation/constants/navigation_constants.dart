import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Navigation constants and configurations for the GymAI app
class NavigationConstants {
  // Private constructor to prevent instantiation
  NavigationConstants._();

  // ── IndexedStack tab indices (plus is an action, not a tab) ──────────
  static const int homeIndex = 0;
  static const int hubIndex = 1; // athlete: باشگاه من · trainer: میز کار
  static const int roleTabIndex = 2; // پیام‌ها (هر دو نقش)
  static const int moreIndex = 3;

  /// Legacy aliases — prefer the names above in new code.
  static const int dashboardIndex = homeIndex;
  static const int myClubIndex = hubIndex;
  static const int chatIndex = roleTabIndex; // messages / legacy coach alias
  static const int socialIndex = roleTabIndex; // messages

  // Navigation labels
  static const String homeLabel = 'خانه';
  static const String myClubLabel = 'باشگاه من';
  static const String deskLabel = 'میز کار';
  static const String coachLabel = 'مربی AI';
  static const String messagesLabel = 'پیام‌ها';
  static const String moreLabel = 'بیشتر';
  static const String plusLabel = 'افزودن';

  /// Legacy labels kept for older call sites / docs.
  static const String chatLabel = messagesLabel;
  static const String academyLabel = 'آکادمی';
  static const String dashboardLabel = homeLabel;
  static const String workoutLabel = myClubLabel;
  static const String socialLabel = messagesLabel;

  // Navigation icons
  static const IconData homeIcon = LucideIcons.house;
  static const IconData myClubIcon = LucideIcons.users;
  static const IconData deskIcon = LucideIcons.briefcase;
  static const IconData coachIcon = LucideIcons.bot;
  static const IconData messagesIcon = LucideIcons.messageCircle;
  static const IconData moreIcon = LucideIcons.ellipsis;
  static const IconData plusIcon = LucideIcons.plus;

  static const IconData chatIcon = messagesIcon;
  static const IconData academyIcon = LucideIcons.school;
  static const IconData dashboardIcon = homeIcon;
  static const IconData workoutIcon = myClubIcon;
  static const IconData socialIcon = messagesIcon;

  // Navigation routes
  static const String chatRoute = '/chat-main';
  static const String dashboardRoute = '/dashboard';
  static const String socialRoute = '/chat-main';
  static const String academyRoute = '/academy';
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
  static const double bottomNavHeight = 96;
  static const double centralButtonSize = 56;
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
      'title': 'ساخت برنامه',
      'subtitle': 'برنامه تمرین جدید بسازید',
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
    'workout_program': Color(0xFFFFD700),
    'workout_log': Color(0xFF2196F3),
    'exercise_list': Color(0xFF4CAF50),
    'meal_plan': Color(0xFFFF9800),
    'meal_log': Color(0xFF9C27B0),
    'food_list': Color(0xFF009688),
    'favorite_foods': Color(0xFFE91E63),
  };

  /// Bottom-nav slots excluding the center plus (for docs / tooling).
  static List<Map<String, dynamic>> navigationItemsForRole(String? role) {
    final isTrainer = role == 'trainer';
    return [
      {
        'index': homeIndex,
        'label': homeLabel,
        'icon': homeIcon,
        'route': dashboardRoute,
      },
      {
        'index': hubIndex,
        'label': isTrainer ? deskLabel : myClubLabel,
        'icon': isTrainer ? deskIcon : myClubIcon,
        'route': null,
      },
      {
        'index': roleTabIndex,
        'label': messagesLabel,
        'icon': messagesIcon,
        'route': socialRoute,
      },
      {
        'index': moreIndex,
        'label': moreLabel,
        'icon': moreIcon,
        'route': null,
      },
    ];
  }

  static const List<Map<String, dynamic>> navigationItems = [
    {
      'index': homeIndex,
      'label': homeLabel,
      'icon': homeIcon,
      'route': dashboardRoute,
    },
    {
      'index': hubIndex,
      'label': myClubLabel,
      'icon': myClubIcon,
      'route': null,
    },
    {
      'index': roleTabIndex,
      'label': messagesLabel,
      'icon': messagesIcon,
      'route': socialRoute,
    },
    {
      'index': moreIndex,
      'label': moreLabel,
      'icon': moreIcon,
      'route': null,
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
