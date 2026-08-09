import 'package:gymaipro/workout_log/models/workout_program_log.dart';

/// شمارش‌های خالص برای «عملکرد من» / امتیاز — بدون وابستگی به شبکه.
class RankingActivityCounts {
  const RankingActivityCounts._();

  /// فقط وعده‌هایی که حداقل یک غذا دارند.
  /// شِل‌های خالیِ صبحانه/ناهار/... شمرده نمی‌شوند.
  static int countLoggedMeals(Iterable<dynamic> foodLogRows) {
    var total = 0;
    for (final row in foodLogRows) {
      if (row is! Map) continue;
      final meals = row['meals'];
      if (meals is! List) continue;
      for (final meal in meals) {
        if (meal is! Map) continue;
        final foods = meal['foods'];
        if (foods is List && foods.isNotEmpty) {
          total++;
        }
      }
    }
    return total;
  }

  /// فقط جلساتی که حداقل یک ست meaningful دارند.
  static int countMeaningfulWorkoutSessions(Iterable<dynamic> workoutLogRows) {
    var total = 0;
    for (final row in workoutLogRows) {
      if (row is! Map) continue;
      try {
        final log = WorkoutDailyLog.fromJson(
          Map<String, dynamic>.from(row),
        );
        for (final session in log.sessions) {
          final probe = WorkoutDailyLog(
            userId: log.userId,
            logDate: log.logDate,
            sessions: [session],
          );
          if (probe.hasMeaningfulLoggedSets) {
            total++;
          }
        }
      } catch (_) {
        // ردیف خراب را رد کن
      }
    }
    return total;
  }
}
