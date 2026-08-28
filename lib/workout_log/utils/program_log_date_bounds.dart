import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';
import 'package:shamsi_date/shamsi_date.dart';

/// بازهٔ مجاز تاریخ ثبت تمرین روی یک برنامه.
///
/// از روز شروع مالکیت (min sent_at/created_at) تا min(انقضا، امروز).
/// قبل از خرید/ارسال و روزهای آینده / بعد از انقضا مجاز نیست.
class ProgramLogDateBounds {
  const ProgramLogDateBounds({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  static DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static ProgramLogDateBounds? forProgram(
    WorkoutProgram? program, {
    DateTime? now,
  }) {
    if (program == null) return null;
    final today = dateOnly(now ?? DateTime.now());
    final startCandidates = <DateTime>[
      if (program.sentAt != null) program.sentAt!,
      program.createdAt,
    ];
    final from = dateOnly(
      startCandidates.reduce((a, b) => a.isBefore(b) ? a : b),
    );

    var to = today;
    final expiry = program.expiryDate;
    if (expiry != null) {
      final exp = dateOnly(expiry);
      if (exp.isBefore(to)) to = exp;
    }

    if (to.isBefore(from)) {
      return ProgramLogDateBounds(from: from, to: from);
    }
    return ProgramLogDateBounds(from: from, to: to);
  }

  bool contains(DateTime date) {
    final day = dateOnly(date);
    return !day.isBefore(from) && !day.isAfter(to);
  }

  bool containsJalali(Jalali date) {
    final g = date.toGregorian();
    return contains(DateTime(g.year, g.month, g.day));
  }

  Jalali clampJalali(Jalali date) {
    final g = date.toGregorian();
    final day = DateTime(g.year, g.month, g.day);
    if (day.isBefore(from)) {
      return Gregorian.fromDateTime(from).toJalali();
    }
    if (day.isAfter(to)) {
      return Gregorian.fromDateTime(to).toJalali();
    }
    return date;
  }
}
