import 'package:gymaipro/ai/context/coach_context.dart';

/// Builds compact, citation-ready facts from existing app engines.
///
/// Pattern inspired by WHOOP Coach / MacroFactor: the LLM should quote
/// concrete numbers already computed by the app, not invent baselines.
class CoachEngineFacts {
  const CoachEngineFacts._();

  /// Returns a map ready to inject as a prompt section, or null when empty.
  static Map<String, Object?>? build(CoachContext context) {
    final facts = <String>[];

    _addProfileFacts(facts, context.profile);
    _addWorkoutFacts(facts, context.activeProgram);
    _addNutritionFacts(facts, context.nutrition);
    _addHeatmapFacts(facts, context);
    _addRecoveryFacts(facts, context.preferences);

    if (facts.isEmpty) return null;
    return <String, Object?>{
      'use_these_facts_in_answers': facts,
      'rule':
          'Cite these app-computed facts by number when relevant. '
          'Do not invent conflicting metrics.',
    };
  }

  static void _addProfileFacts(List<String> facts, Map<String, Object?> profile) {
    final height = _num(profile['height'] ?? profile['height_cm']);
    final weight = _num(
      profile['latest_recorded_weight_kg'] ??
          profile['weight'] ??
          profile['weight_kg'],
    );
    final bmi = _num(profile['bmi']);
    if (height != null && weight != null) {
      final bmiText = bmi == null ? '' : '، BMI حدود ${bmi.toStringAsFixed(1)}';
      facts.add(
        'قد ${height.round()} سانتی‌متر و وزن ${weight.toStringAsFixed(1)} کیلو$bmiText.',
      );
    }

    final change = _num(profile['weight_change_kg']);
    final since = profile['weight_change_since']?.toString();
    if (change != null && since != null && since.isNotEmpty) {
      final direction = change > 0
          ? 'افزایش'
          : change < 0
          ? 'کاهش'
          : 'بدون تغییر محسوس';
      facts.add(
        'از $since تا الان وزن حدود ${change.abs().toStringAsFixed(1)} کیلو $direction داشته.',
      );
    }

    final streak = _int(profile['current_streak_days']);
    if (streak != null && streak > 0) {
      facts.add('استریک فعلی $streak روز است.');
    }
  }

  static void _addWorkoutFacts(
    List<String> facts,
    Map<String, Object?>? activeProgram,
  ) {
    if (activeProgram == null || activeProgram.isEmpty) return;

    final name = activeProgram['program_name']?.toString().trim();
    final day = activeProgram['selected_session_day']?.toString().trim();
    final today = activeProgram['today_session'];
    if (name != null && name.isNotEmpty && day != null && day.isNotEmpty) {
      facts.add('برنامه فعال «$name»؛ جلسه امروز: $day.');
    } else if (name != null && name.isNotEmpty) {
      facts.add('برنامه فعال «$name» است.');
    }

    if (today is Map) {
      final count = _int(today['exercise_count']);
      if (count != null && count > 0) {
        facts.add('جلسه امروز $count حرکت دارد.');
      }
    }

    if (activeProgram['has_saved_log_today'] == true) {
      facts.add('برای امروز لاگ تمرین ثبت شده است.');
    } else if (activeProgram['has_live_draft'] == true) {
      facts.add('یک جلسه زنده ناتمام برای امروز وجود دارد.');
    }
  }

  static void _addNutritionFacts(
    List<String> facts,
    Map<String, Object?> nutrition,
  ) {
    if (nutrition.isEmpty) return;

    final targets = nutrition['daily_targets'];
    if (targets is Map) {
      final calories = _int(targets['calories_kcal']);
      final protein = _int(targets['protein_g']);
      final maintenance = _int(targets['maintenance_kcal']);
      final hasActiveGoal = targets['has_active_goal'] == true;
      if (calories != null) {
        final proteinText =
            protein == null ? '' : ' و حدود $protein گرم پروتئین';
        if (hasActiveGoal) {
          final maintText = maintenance == null
              ? ''
              : ' (برای حفظ وزن حدود $maintenance)';
          facts.add('هدف کالری حدود $calories$maintText$proteinText است.');
        } else {
          facts.add(
            'نیاز تقریبی روزانه برای حفظ وزن حدود $calories کالری$proteinText است '
            '(هنوز هدف کالری فعال نیست).',
          );
        }
      }
    }

    final today = nutrition['today'];
    if (today is Map) {
      if (today['logged'] == false) {
        facts.add('امروز هنوز غذایی ثبت نشده.');
      } else {
        final consumed = today['consumed'];
        if (consumed is Map) {
          final calories = _int(consumed['calories_kcal']);
          final protein = _int(consumed['protein_g']);
          if (calories != null) {
            final proteinText =
                protein == null ? '' : ' و $protein گرم پروتئین';
            facts.add('امروز تا الان حدود $calories کالری$proteinText ثبت شده.');
          }
        }
      }
    }

    final loggedDays = _int(nutrition['logged_days_last_7']);
    if (loggedDays != null) {
      facts.add('در ۷ روز اخیر $loggedDays روز لاگ غذا داشته.');
    }
  }

  static void _addHeatmapFacts(List<String> facts, CoachContext context) {
    final heatmap = context.weeklyHeatmap;
    if (heatmap == null) return;

    final balance = heatmap.balanceLine?.trim();
    final trend = heatmap.weekTrendLine?.trim();
    final gap = heatmap.programGapLine?.trim();
    final top = heatmap.topMuscleLabel?.trim();

    if (balance != null && balance.isNotEmpty) facts.add(balance);
    if (trend != null && trend.isNotEmpty) facts.add(trend);
    if (gap != null && gap.isNotEmpty) facts.add(gap);
    if (top != null && top.isNotEmpty) {
      facts.add('پرکارترین عضله این هفته: $top.');
    } else if (heatmap.sessionCount > 0) {
      facts.add(
        'این هفته ${heatmap.sessionCount} جلسه و ${heatmap.workoutDays} روز تمرین ثبت شده.',
      );
    }
  }

  static void _addRecoveryFacts(
    List<String> facts,
    Map<String, Object?> preferences,
  ) {
    final score = _int(preferences['recovery_score']);
    final daysSince = _int(preferences['days_since_last_workout']);
    if (score != null) {
      facts.add('امتیاز آمادگی/ریکاوری فعلی حدود $score از ۱۰۰ است.');
    }
    if (daysSince != null) {
      if (daysSince == 0) {
        facts.add('آخرین تمرین امروز ثبت شده است.');
      } else if (daysSince > 0) {
        facts.add('$daysSince روز از آخرین تمرین گذشته.');
      }
    }
  }

  static double? _num(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString().trim() ?? '');
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString().trim() ?? '');
  }
}
