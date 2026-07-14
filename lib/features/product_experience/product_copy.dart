import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Persian product labels (EPIC 32) — formatting lives in [ProductExperienceFormatter].
abstract final class ProductCopy {
  static const String coachBriefTitle = 'خلاصه مربی';
  static const String whyThisSuggestion = 'چرا این پیشنهاد؟';
  static const String coachOpinion = 'نظر مربی';
  static const String mySuggestion = 'پیشنهاد من';
  static const String todayWorkout = 'تمرین امروز';
  static const String recovery = 'ریکاوری';
  static const String workoutSummary = 'خلاصه تمرین';
  static const String todayProgram = 'برنامه امروز';
  static const String exerciseTimeline = 'برنامه حرکات';
  static const String coachNotes = 'یادداشت مربی';
  static const String quickActions = 'دسترسی سریع';
  static const String startWorkout = 'شروع تمرین';
  static const String workoutSession = 'جلسه تمرین';
  static const String sets = 'ست‌ها';
  static const String restTimer = 'استراحت بین ست';
  static const String currentExercise = 'حرکت فعلی';
  static const String upcomingExercise = 'حرکت بعدی';
  static const String coachTips = 'نکته مربی';
  static const String progress = 'پیشرفت';
  static const String today = 'امروز';
  static const String coachName = 'مربی';
  static const String online = 'آنلاین';
  static const String typing = 'در حال نوشتن...';
  static const String thinking = 'در حال فکر کردن...';
  static const String emptyWorkoutTitle = 'هنوز برنامه‌ای برای امروز نداری.';
  static const String emptyWorkoutMessage = 'بزن تا برات بسازم.';
  static const String coachLoadFailed = 'بارگذاری اطلاعات مربی ناموفق بود.';
  @Deprecated('Use coachLoadFailed')
  static const String previewLoadFailed = coachLoadFailed;
  static const String buildProgram = 'ساخت برنامه';
  static const String difficultyLabel = 'سطح سختی';
  static const String exercisesCount = 'حرکت';
  static const String minutes = 'دقیقه';
  static const String completeSet = 'تکمیل ست';
  static const String nextExercise = 'حرکت بعدی';
  static const String finishWorkout = 'پایان تمرین';
  static const String skipRest = 'رد کردن استراحت';
  static const String effortLevel = 'شدت تلاش';
  static const String coachDisabledTitle = 'مربی هنوز فعال نیست';
  static const String retry = 'دوباره امتحان کن';
  static const String genericError = 'یه مشکلی پیش اومد';

  static String buildCoachBrief(CoachHomeState state) {
    if (state.coachBrief.trim().isNotEmpty) return state.coachBrief;
    return 'هنوز اطلاعات کافی برای جمع‌بندی ندارم؛ یک پیام به مربی بفرست.';
  }

  static String humanizeReason(String raw) =>
      ProductExperienceFormatter.humanizeReason(raw);

  static String localizeCardTitle(String title) =>
      ProductExperienceFormatter.localizeCardTitle(title);

  static String quickActionEmoji(String id) =>
      ProductExperienceFormatter.quickActionEmoji(id);

  static String defaultQuickChipLabel(String id, String fallback) =>
      ProductExperienceFormatter.quickActionLabel(id, fallback);

  static String localizePrimaryAction(String label) =>
      ProductExperienceFormatter.localizePrimaryAction(label);
}
