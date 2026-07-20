import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';

/// User-facing explanations for training metrics shown in Coach surfaces.
abstract final class TrainingMetricGuides {
  static const String readinessTitle = 'آمادگی تمرین';
  static const String rpeTitle = 'شدت تلاش';

  static String readinessExplanation({CoachRecoverySnapshot? snapshot}) {
    final readiness = snapshot?.readiness ?? 0;
    final readinessLine = readiness > 0
        ? 'امتیاز فعلی تو: $readiness٪.'
        : 'هنوز داده کافی برای محاسبه دقیق نداریم.';

    final postNote = snapshot?.daysSinceLastWorkout != null &&
            snapshot!.daysSinceLastWorkout! <= 0
        ? '\n\nاگر همین امروز تمرین کرده‌ای، پایین بودن این عدد طبیعیه و به‌معنی «باید دوباره سبک‌تر بزنی» نیست؛ یعنی بدنت در فاز ریکاوری است.'
        : '';

    return '''
$readinessLine

این عدد نشان می‌دهد بدن امروز چقدر برای تمرین آماده است؛ ترکیبی از:
• ریکاوری (خواب، استراحت، سابقه تمرین)
• خستگی عضلانی (تمرین‌های اخیر و نقشه عضلانی هفته)
• کیفیت خواب

بعد از هر جلسه ثبت‌شده، این عدد با توجه به ست‌های انجام‌شده به‌روز می‌شود.$postNote
'''.trim();
  }

  static const String rpeExplanation = '''
شدت تلاش یعنی حس خودت از سختی ست — نه عدد دستگاه.

مقیاس ۱ تا ۱۰:
• ۶ تا ۷: سنگین، ولی هنوز ۲–۳ تکرار ذخیره داری
• ۸: سخت؛ حدود ۱–۲ تکرار مانده
• ۹: خیلی سخت؛ شاید فقط ۱ تکرار مانده
• ۱۰: حداکثر توان — تکرار بیشتر ممکن نیست

اختیاری است. اگر مطمئن نیستی خالی بگذار. وقتی پر شود، مربی هوشمند شدت جلسات بعد را بهتر تنظیم می‌کند.
''';

  static String readinessHint(int readiness, {int? daysSinceLastWorkout}) {
    final guidance = RecoveryGuidance.fromSnapshot(
      CoachRecoverySnapshot(
        recovery: readiness,
        fatigue: readiness > 0 ? (100 - readiness).clamp(15, 85) : 0,
        sleep: 0,
        readiness: readiness,
        daysSinceLastWorkout: daysSinceLastWorkout,
      ),
      daysSinceLastWorkout: daysSinceLastWorkout,
    );
    return switch (guidance.scenario) {
      RecoveryScenario.postSessionToday =>
        'جلسه امروز ثبت شده؛ امشب روی ریکاوری تمرکز کن.',
      RecoveryScenario.readyToTrain => 'بدنت برای تمرین امروز آماده است.',
      RecoveryScenario.trainCautiously =>
        'می‌توانی تمرین کنی؛ روی فرم و شدت متوسط تمرکز کن.',
      RecoveryScenario.needsRestOrLighter =>
        'اگر هنوز تمرین نکرده‌ای، امروز سبک‌تر تمرین کن یا استراحت فعال داشته باش.',
      RecoveryScenario.returningAfterBreak =>
        'بعد از چند روز فاصله، با شدت متوسط برگرد.',
      RecoveryScenario.unknown =>
        'داده ریکاوری کامل نیست؛ با احساس خودت شدت را تنظیم کن.',
    };
  }
}
