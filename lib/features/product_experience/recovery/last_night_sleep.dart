import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/features/product_experience/calendar_day.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Last night's restorative sleep — hours actually slept, not time in bed.
class LastNightSleepLog {
  const LastNightSleepLog({required this.hours, required this.dateKey});

  final double hours;
  final String dateKey;
}

/// Scoring and persistence for last-night useful sleep.
abstract final class LastNightSleep {
  static const double minHours = 3;
  static const double maxHours = 10;
  static const double step = 0.5;
  static const double defaultHours = 7;
  static const double neutralHours = 7.5;

  static const int sliderDivisions = 14; // (10 - 3) / 0.5

  static double snap(double hours) {
    final clamped = hours.clamp(minHours, maxHours);
    return (clamped * 2).round() / 2;
  }

  static int scoreFromHours(double hours) {
    return (snap(hours) / 8 * 100).round().clamp(0, 100);
  }

  /// Fatigue delta: short nights raise fatigue, long nights ease it.
  static int fatigueAdjustment(double hours) {
    return ((neutralHours - snap(hours)) * 6).round();
  }

  static String formatHours(double hours) {
    final snapped = snap(hours);
    if (snapped == snapped.roundToDouble()) {
      return '${snapped.toInt()}';
    }
    return snapped.toStringAsFixed(1);
  }

  static String formatHoursLabel(double hours) => '${formatHours(hours)} ساعت';

  static double suggestedHours(
    Map<String, Object?> preferences, {
    double? logged,
  }) {
    if (logged != null) return snap(logged);
    final raw =
        preferences['bb_sleep_hours'] ?? preferences['sleep_hours'];
    final parsed = raw is num
        ? raw.toDouble()
        : double.tryParse(raw?.toString() ?? '');
    return snap(parsed ?? defaultHours);
  }

  static CoachContext applyToContext(
    CoachContext context,
    LastNightSleepLog? log,
  ) {
    if (log == null) return context;
    return CoachContext(
      intent: context.intent,
      metadata: context.metadata,
      profile: context.profile,
      goals: context.goals,
      restrictions: context.restrictions,
      equipment: context.equipment,
      preferences: Map<String, Object?>.unmodifiable(<String, Object?>{
        ...context.preferences,
        'last_night_sleep_hours': log.hours,
        'sleep_hours': log.hours,
      }),
      activeProgram: context.activeProgram,
      workoutHistory: context.workoutHistory,
      weeklyHeatmap: context.weeklyHeatmap,
      nutrition: context.nutrition,
      memories: context.memories,
      apiUsage: context.apiUsage,
      currentQuestion: context.currentQuestion,
      conversationSummary: context.conversationSummary,
    );
  }
}

/// Local per-user log of last night's useful sleep for the current calendar day.
class LastNightSleepStore {
  LastNightSleepStore({
    SharedPreferences? preferences,
    DateTime Function()? clock,
  }) : _preferences = preferences,
       _clock = clock ?? DateTime.now;

  final SharedPreferences? _preferences;
  final DateTime Function() _clock;

  static String hoursKey(String userId) => 'last_night_sleep_hours_$userId';

  static String dateKey(String userId) => 'last_night_sleep_date_$userId';

  Future<LastNightSleepLog?> readToday(String userId) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) return null;

    final prefs = await _prefs();
    final storedDate = prefs.getString(dateKey(trimmed));
    if (storedDate != CalendarDay.dateKey(_clock())) return null;

    final hours = _readHours(prefs, hoursKey(trimmed));
    if (hours == null || hours <= 0) return null;

    return LastNightSleepLog(
      hours: LastNightSleep.snap(hours),
      dateKey: storedDate!,
    );
  }

  Future<LastNightSleepLog> save({
    required String userId,
    required double hours,
  }) async {
    final trimmed = userId.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('userId is required to save last-night sleep');
    }

    final snapped = LastNightSleep.snap(hours);
    final today = CalendarDay.dateKey(_clock());
    final prefs = await _prefs();
    await prefs.setDouble(hoursKey(trimmed), snapped);
    await prefs.setString(dateKey(trimmed), today);
    return LastNightSleepLog(hours: snapped, dateKey: today);
  }

  Future<SharedPreferences> _prefs() async {
    return _preferences ?? await SharedPreferences.getInstance();
  }

  static double? _readHours(SharedPreferences prefs, String key) {
    final direct = prefs.getDouble(key);
    if (direct != null) return direct;
    return double.tryParse(prefs.getString(key) ?? '');
  }
}
