// Dashboard Widgets Barrel Export
// This file exports all dashboard widgets for easier imports

// Academy preview is a feature widget shown on dashboard
export '../../academy/widgets/academy_preview_section.dart';
// Common widgets (shared across dashboard)
export 'common_widgets.dart';
// Core dashboard widgets
export 'dashboard_analytics.dart';
export 'dashboard_nav.dart';
export 'dashboard_profile.dart';
export 'dashboard_welcome.dart';
export 'dashboard_workout.dart'
    show
        QuickActionButton,
        SplitItem,
        TodayWorkoutSection,
        WorkoutItem,
        WorkoutSplitSection;
export 'fitness_metrics.dart';
export 'latest_items_section.dart';
export 'meal_planning_section.dart';
export 'quick_shortcuts_grid.dart';
export 'section_nav_carousel.dart';
export 'section_nav_list.dart';
export 'weight_chart.dart';
export 'weight_height_display.dart';
