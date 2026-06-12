import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/meal_log/services/meal_log_service.dart';
import 'package:gymaipro/my_club/models/program_activity_filter.dart';

class ProgramMealActivityData {
  ProgramMealActivityData({
    required this.logsByDay,
    required this.filter,
  });

  final Map<int, FoodLog> logsByDay;
  final ProgramActivityFilter filter;

  int get loggedDayCount => logsByDay.length;

  FoodLog? logForDate(DateTime date) => logsByDay[dayKey(date)];

  static int dayKey(DateTime date) {
    return ProgramActivityFilter.dateOnly(date).millisecondsSinceEpoch;
  }
}

class ProgramMealActivityService {
  final MealLogService _mealLogs = MealLogService();

  Future<ProgramMealActivityData?> load(ProgramActivityFilter filter) async {
    final from = ProgramActivityFilter.dateOnly(filter.validFrom);
    final to = ProgramActivityFilter.dateOnly(filter.validTo);

    final all = await _mealLogs.getLogsForDateRange(from, to);
    final byDay = <int, FoodLog>{};

    for (final log in all) {
      final filtered = filter.filterMealLog(log);
      if (filtered == null) continue;
      byDay[ProgramMealActivityData.dayKey(filtered.logDate)] = filtered;
    }

    return ProgramMealActivityData(logsByDay: byDay, filter: filter);
  }
}
