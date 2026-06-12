import 'dart:convert';

import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// محدوده و شناسه برنامه برای فیلتر پیش‌نمایش فعالیت.
class ProgramActivityFilter {
  const ProgramActivityFilter({
    required this.programId,
    required this.validFrom,
    required this.validTo,
    this.sessionDays = const {},
  });

  final String programId;
  final DateTime validFrom;
  final DateTime validTo;
  final Set<String> sessionDays;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static String normalizeDay(String day) {
    var s = day.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    const persian = '۰۱۲۳۴۵۶۷۸۹';
    const arabic = '٠١٢٣٤٥٦٧٨٩';
    for (var i = 0; i < 10; i++) {
      s = s.replaceAll(persian[i], '$i');
      s = s.replaceAll(arabic[i], '$i');
    }
    return s;
  }

  static String normalizeProgramId(String id) {
    final s = id.trim().toLowerCase();
    if (s.length == 32 && !s.contains('-')) {
      return '${s.substring(0, 8)}-${s.substring(8, 12)}-'
          '${s.substring(12, 16)}-${s.substring(16, 20)}-${s.substring(20)}';
    }
    return s;
  }

  static bool sameProgramId(String? a, String? b) {
    if (a == null || b == null || a.isEmpty || b.isEmpty) return false;
    return normalizeProgramId(a) == normalizeProgramId(b);
  }

  static Set<String> sessionDaysFrom(dynamic raw) {
    if (raw is Set<String>) return raw;
    if (raw is Iterable) {
      return raw.map((e) => normalizeDay(e.toString())).where((d) => d.isNotEmpty).toSet();
    }
    return const {};
  }

  static Set<String> extractWorkoutSessionDays(dynamic data) {
    final map = _parseDataMap(data);
    if (map == null) return {};
    final sessions = map['sessions'] as List?;
    if (sessions == null) return {};
    return sessions
        .map((s) => normalizeDay((s as Map)['day']?.toString() ?? ''))
        .where((d) => d.isNotEmpty)
        .toSet();
  }

  static Map<String, dynamic>? _parseDataMap(dynamic data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  bool containsDate(DateTime date) {
    final day = dateOnly(date);
    final from = dateOnly(validFrom);
    final to = dateOnly(validTo);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  /// فقط سشن‌های مربوط به همین برنامه (یا روزهای همان برنامه در لاگ‌های قدیمی).
  WorkoutDailyLog? filterWorkoutLog(WorkoutDailyLog log) {
    if (!containsDate(log.logDate)) return null;

    final sessions = log.sessions.where(_workoutSessionMatches).toList();
    if (sessions.isEmpty || !_sessionsHaveLoggedSets(sessions)) return null;

    return WorkoutDailyLog(
      id: log.id,
      userId: log.userId,
      logDate: log.logDate,
      sessions: sessions,
      createdAt: log.createdAt,
      updatedAt: log.updatedAt,
    );
  }

  bool _workoutSessionMatches(WorkoutSessionLog session) {
    final taggedProgramId = session.programId;
    final day = normalizeDay(session.day);
    final dayMatch = sessionDays.isNotEmpty && sessionDays.contains(day);

    if (taggedProgramId != null && taggedProgramId.isNotEmpty) {
      if (sameProgramId(taggedProgramId, programId)) return true;
      if (dayMatch) return true;
      return false;
    }

    if (dayMatch) return true;

    // لاگ قدیمی بدون program_id و بدون لیست روز — فقط داخل بازه اعتبار
    if (sessionDays.isEmpty) return true;

    return false;
  }

  FoodLog? filterMealLog(FoodLog log) {
    if (!containsDate(log.logDate)) return null;
    if (!_mealLogHasPlanFoods(log)) return null;
    return log;
  }

  bool _mealLogHasPlanFoods(FoodLog log) {
    for (final meal in log.meals) {
      for (final item in meal.foods) {
        final planId = item.mealPlanId;
        if (planId != null && sameProgramId(planId, programId)) return true;
      }
    }
    return false;
  }

  bool _sessionsHaveLoggedSets(List<WorkoutSessionLog> sessions) {
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise is NormalExerciseLog) {
          if (exercise.sets.any(_setHasValue)) return true;
        } else if (exercise is SupersetExerciseLog) {
          for (final item in exercise.exercises) {
            if (item.sets.any(_setHasValue)) return true;
          }
        }
      }
    }
    return false;
  }

  bool _setHasValue(ExerciseSetLog set) {
    return (set.reps != null && set.reps! > 0) ||
        (set.seconds != null && set.seconds! > 0) ||
        (set.weight != null && set.weight! > 0);
  }
}
