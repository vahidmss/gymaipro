import 'package:gymaipro/my_club/models/program_activity_filter.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// روزهای دارای لاگ تمرین — فقط برای همان برنامه و بازه اعتبار.
class ProgramWorkoutActivityData {
  ProgramWorkoutActivityData({
    required this.logsByDay,
    required this.filter,
  });

  final Map<int, WorkoutDailyLog> logsByDay;
  final ProgramActivityFilter filter;

  int get loggedDayCount => logsByDay.length;

  WorkoutDailyLog? logForDate(DateTime date) => logsByDay[dayKey(date)];

  static int dayKey(DateTime date) {
    return ProgramActivityFilter.dateOnly(date).millisecondsSinceEpoch;
  }
}

class ProgramWorkoutActivityService {
  final WorkoutDailyLogService _logs = WorkoutDailyLogService();

  Future<ProgramWorkoutActivityData?> load(ProgramActivityFilter filter) async {
    final userId = await AuthHelper.getCurrentUserId();
    if (userId == null) return null;

    var effectiveFilter = filter;
    if (filter.sessionDays.isEmpty) {
      final days = await _loadSessionDaysFromDb(filter.programId);
      if (days.isNotEmpty) {
        effectiveFilter = ProgramActivityFilter(
          programId: filter.programId,
          validFrom: filter.validFrom,
          validTo: filter.validTo,
          sessionDays: days,
        );
      }
    }

    final all = await _logs.getUserDailyLogs(userId);
    final byDay = <int, WorkoutDailyLog>{};

    for (final log in all) {
      final filtered = effectiveFilter.filterWorkoutLog(log);
      if (filtered == null) continue;
      byDay[ProgramWorkoutActivityData.dayKey(filtered.logDate)] = filtered;
    }

    return ProgramWorkoutActivityData(logsByDay: byDay, filter: effectiveFilter);
  }

  Future<Set<String>> _loadSessionDaysFromDb(String programId) async {
    try {
      final row = await Supabase.instance.client
          .from('workout_programs')
          .select('data')
          .eq('id', programId)
          .maybeSingle();
      if (row == null) return {};
      return ProgramActivityFilter.extractWorkoutSessionDays(row['data']);
    } catch (_) {
      return {};
    }
  }
}
