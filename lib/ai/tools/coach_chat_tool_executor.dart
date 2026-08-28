import 'package:gymaipro/ai/context/adapters/workout_context_adapter.dart';
import 'package:gymaipro/ai/context/providers/recovery_context_provider.dart';
import 'package:gymaipro/ai/tools/coach_chat_tool_definitions.dart';
import 'package:gymaipro/features/product_experience/calendar_day.dart';
import 'package:gymaipro/features/product_experience/recovery/last_night_sleep.dart';
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/meal_log/utils/meal_log_utils.dart';
import 'package:gymaipro/meal_log/utils/meal_nutrition_targets.dart';
import 'package:gymaipro/meal_log/utils/nutrition_copy.dart';
import 'package:gymaipro/models/food.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/active_meal_plan_service.dart';
import 'package:gymaipro/services/food_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/weekly_muscle_heatmap_service.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Executes Coach chat tool calls against real GymAI app engines.
class CoachChatToolExecutor {
  CoachChatToolExecutor({
    WorkoutContextAdapter? workoutAdapter,
    MealLogService? mealLogService,
    ActiveMealPlanService? activeMealPlanService,
    WeeklyMuscleHeatmapService? heatmapService,
  }) : _workoutAdapterOrNull = workoutAdapter,
       _mealLogServiceOrNull = mealLogService,
       _activeMealPlanServiceOrNull = activeMealPlanService,
       _heatmapServiceOrNull = heatmapService;

  final WorkoutContextAdapter? _workoutAdapterOrNull;
  final MealLogService? _mealLogServiceOrNull;
  final ActiveMealPlanService? _activeMealPlanServiceOrNull;
  final WeeklyMuscleHeatmapService? _heatmapServiceOrNull;

  WorkoutContextAdapter? _lazyWorkoutAdapter;
  MealLogService? _lazyMealLogService;
  ActiveMealPlanService? _lazyActiveMealPlanService;
  WeeklyMuscleHeatmapService? _lazyHeatmapService;

  WorkoutContextAdapter get _workoutAdapter =>
      _workoutAdapterOrNull ??
      (_lazyWorkoutAdapter ??= WorkoutContextAdapter());
  MealLogService get _mealLogService =>
      _mealLogServiceOrNull ?? (_lazyMealLogService ??= MealLogService());
  ActiveMealPlanService get _activeMealPlanService =>
      _activeMealPlanServiceOrNull ??
      (_lazyActiveMealPlanService ??= ActiveMealPlanService());
  WeeklyMuscleHeatmapService get _heatmapService =>
      _heatmapServiceOrNull ??
      (_lazyHeatmapService ??= WeeklyMuscleHeatmapService());

  Future<String> execute({
    required String name,
    required String userId,
    Map<String, Object?> arguments = const <String, Object?>{},
  }) async {
    try {
      final result = switch (name) {
        'get_today_workout' => await _todayWorkout(),
        'get_nutrition_today' => await _nutritionToday(),
        'get_weight_trend' => await _weightTrend(userId),
        'get_muscle_heatmap' => await _heatmap(userId),
        'get_recovery_status' => await _recovery(userId),
        _ => <String, Object?>{
          'ok': false,
          'error': 'unknown_tool',
          'name': name,
        },
      };
      return CoachChatToolDefinitions.encodeToolResult(result);
    } on Object catch (error) {
      return CoachChatToolDefinitions.encodeToolResult(<String, Object?>{
        'ok': false,
        'error': error.toString(),
        'tool': name,
      });
    }
  }

  Future<Map<String, Object?>> _todayWorkout() async {
    final program = await _workoutAdapter.getActiveProgram();
    if (program == null || program.isEmpty) {
      return <String, Object?>{
        'ok': true,
        'has_active_program': false,
        'message': 'No active workout program.',
      };
    }
    return <String, Object?>{
      'ok': true,
      'has_active_program': true,
      'program': program,
    };
  }

  Future<Map<String, Object?>> _nutritionToday() async {
    final profile = await SimpleProfileService.getCurrentProfile();
    final targets = MealNutritionTargets.fromProfile(profile);
    final nutrition = <String, Object?>{
      'ok': true,
      'daily_targets': NutritionCopy.dailyTargetsMap(targets),
    };

    final log = await _mealLogService.getLogForDate(DateTime.now());
    final today = await _todaySnapshot(log);
    nutrition['today'] = today;

    final targetCalories = targets.calorieTarget.round();
    final targetProtein = targets.proteinTarget.round();
    final consumed = today['consumed'];
    if (consumed is Map) {
      final usedCal = _asInt(consumed['calories_kcal']) ?? 0;
      final usedPro = _asInt(consumed['protein_g']) ?? 0;
      nutrition['remaining'] = <String, Object?>{
        'calories_kcal': (targetCalories - usedCal).clamp(0, targetCalories),
        'protein_g': (targetProtein - usedPro).clamp(0, targetProtein),
      };
    }

    nutrition['summary_fa'] = NutritionCopy.summaryFa(
      targets: targets,
      today: today,
    );

    final activeMealPlanId = await _activeMealPlanService.getActiveMealPlanId();
    nutrition['has_active_meal_plan'] =
        activeMealPlanId != null && activeMealPlanId.isNotEmpty;
    return nutrition;
  }

  Future<Map<String, Object?>> _todaySnapshot(FoodLog? log) async {
    if (log == null) {
      return <String, Object?>{'logged': false};
    }
    final hasFood = log.meals.any((meal) => meal.foods.isNotEmpty);
    if (!hasFood) {
      return <String, Object?>{'logged': false};
    }
    final snapshot = <String, Object?>{
      'logged': true,
      'meals': <Object?>[
        for (final meal in log.meals)
          if (meal.foods.isNotEmpty)
            <String, Object?>{
              'title': meal.title,
              'items': meal.foods.length,
            },
      ],
    };
    try {
      List<Food>? foods = FoodService().peekCachedFoods();
      foods ??= await FoodService().getFoods().timeout(
        const Duration(seconds: 4),
      );
      if (foods.isNotEmpty) {
        final totals = MealLogUtils.calculateTotals(log.meals, foods);
        snapshot['consumed'] = <String, Object?>{
          'calories_kcal': (totals['calories'] ?? 0).round(),
          'protein_g': (totals['protein'] ?? 0).round(),
          'carbs_g': (totals['carbs'] ?? 0).round(),
          'fat_g': (totals['fat'] ?? 0).round(),
        };
      }
    } on Object {
      // Totals are optional.
    }
    return snapshot;
  }

  Future<Map<String, Object?>> _weightTrend(String userId) async {
    final stats = await WeeklyWeightService.getWeightStats(userId);
    final history = await WeeklyWeightService.getFullWeightHistory(userId);
    final recent = history.length <= 5
        ? history
        : history.sublist(history.length - 5);
    return <String, Object?>{
      'ok': true,
      'stats': stats,
      'recent_weigh_ins': <Object?>[
        for (final row in recent)
          <String, Object?>{
            'date': row['recorded_at']?.toString().substring(0, 10),
            'weight_kg': row['weight'],
          },
      ],
      'summary_fa': _weightTrendSummaryFa(
        Map<String, Object?>.from(stats),
        recent,
      ),
    };
  }

  static String _weightTrendSummaryFa(
    Map<String, Object?> stats,
    List<Map<String, dynamic>> recent,
  ) {
    final buffer = StringBuffer();
    if (recent.isNotEmpty) {
      final latest = recent.last['weight'];
      if (latest != null) {
        buffer.write('آخرین وزن ثبت‌شده: $latest کیلو. ');
      }
      if (recent.length >= 2) {
        final first = recent.first['weight'];
        final last = recent.last['weight'];
        if (first is num && last is num) {
          final delta = last - first;
          if (delta > 0.2) {
            buffer.write(
              'در ${recent.length} وزن‌کشی اخیر حدود '
              '${delta.abs().toStringAsFixed(1)} کیلو افزایش داشته. ',
            );
          } else if (delta < -0.2) {
            buffer.write(
              'در ${recent.length} وزن‌کشی اخیر حدود '
              '${delta.abs().toStringAsFixed(1)} کیلو کاهش داشته. ',
            );
          } else {
            buffer.write('در وزن‌کشی‌های اخیر تقریباً ثابت بوده. ');
          }
        }
      }
    }
    final trend = stats['trend']?.toString().trim();
    if (trend != null && trend.isNotEmpty) {
      buffer.write('روند کلی: $trend.');
    }
    final text = buffer.toString().trim();
    return text.isEmpty
        ? 'هنوز روند وزن قابل استنادی ثبت نشده.'
        : text;
  }

  Future<Map<String, Object?>> _heatmap(String userId) async {
    final result = await _heatmapService.loadForUser(userId);
    final labeled = <String, int>{
      for (final entry in result.targets.entries)
        if (entry.value > 0) MuscleTargets.label(entry.key): entry.value,
    };
    final sortedAsc = MuscleTargets.sortedEntries(result.targets).reversed
        .where((e) => e.value >= 0)
        .take(5)
        .toList(growable: false);
    return <String, Object?>{
      'ok': true,
      'has_heatmap_data': result.hasHeatmapData,
      'targets_fa': labeled,
      'lowest_muscles_fa': <Object?>[
        for (final entry in sortedAsc)
          <String, Object?>{
            'muscle': MuscleTargets.label(entry.key),
            'stimulus': entry.value,
          },
      ],
      'workout_days': result.workoutDays,
      'session_count': result.sessionCount,
      'stimulus_total': result.stimulusTotal,
      if (result.topMuscleLabel != null) 'top_muscle': result.topMuscleLabel,
      if (result.lightMuscleLabel != null)
        'light_muscle': result.lightMuscleLabel,
      if (result.balanceLine != null) 'balance_line': result.balanceLine,
      if (result.weekTrendLine != null) 'week_trend_line': result.weekTrendLine,
      if (result.programGapLine != null)
        'program_gap_line': result.programGapLine,
      'activity_line': result.activityLine,
      'rule_fa':
          'فقط از نام‌های فارسی همین لیست استفاده کن؛ عضله اختراع نکن '
          '(مثلاً پیشانی وجود ندارد — ساعد درست است).',
    };
  }

  Future<Map<String, Object?>> _recovery(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final rawScore = prefs.getString(
      RecoveryContextProvider.recoveryScoreKey(userId),
    );
    final rawCompletedAt = prefs.getString(
      RecoveryContextProvider.lastWorkoutCompletedAtKey(userId),
    );
    var score = int.tryParse(rawScore ?? '');
    final completedAt = DateTime.tryParse(rawCompletedAt ?? '');
    int? daysSince;
    if (completedAt != null) {
      daysSince = CalendarDay.daysBetween(completedAt, DateTime.now());
      if (score != null && daysSince > 0) {
        score = (score + daysSince * 10).clamp(score, 100);
      } else if (score == null && daysSince >= 0) {
        score = (45 + daysSince * 12).clamp(35, 95);
      }
    }
    final sleepLog = await LastNightSleepStore(
      preferences: prefs,
    ).readToday(userId);
    final sleepHours = sleepLog?.hours;
    final sleepLabel = sleepHours == null
        ? ''
        : '؛ خواب مفید دیشب حدود ${LastNightSleep.formatHoursLabel(sleepHours)} بوده.';
    return <String, Object?>{
      'ok': true,
      if (score != null) 'recovery_score': score,
      if (completedAt != null)
        'last_workout_completed_at': completedAt.toIso8601String(),
      if (daysSince != null) 'days_since_last_workout': daysSince,
      if (sleepHours != null) 'last_night_sleep_hours': sleepHours,
      if (score == null && completedAt == null && sleepHours == null)
        'available': false,
      if (score != null || sleepHours != null)
        'summary_fa':
            '${score == null ? 'آمادگی امروز هنوز از جلسه تمرین کامل نشده' : 'امتیاز آمادگی/ریکاوری فعلی حدود $score از ۱۰۰ است'}'
            '${daysSince == null ? '' : daysSince == 0 ? '؛ آخرین تمرین امروز ثبت شده.' : '؛ $daysSince روز از آخرین تمرین گذشته.'}'
            '$sleepLabel',
    };
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }
}
