/// Shared calendar-day helpers for coach recovery / workout-today surfaces.
///
/// Prefer calendar midnights over [Duration.inDays] so a workout at 23:00 and
/// opening the hub at 00:30 counts as a new day (daysSince == 1).
abstract final class CalendarDay {
  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String dateKey(DateTime value) =>
      dateOnly(value).toIso8601String().substring(0, 10);

  /// Whole local calendar days from [from] to [to] (can be negative).
  static int daysBetween(DateTime from, DateTime to) =>
      dateOnly(to).difference(dateOnly(from)).inDays;
}
