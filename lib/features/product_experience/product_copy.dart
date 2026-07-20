import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Persian product labels (EPIC 32) — formatting lives in [ProductExperienceFormatter].
abstract final class ProductCopy {
  static const String coachBriefTitle = 'خلاصه مربی';
  static const String whyThisSuggestion = 'چرا این پیشنهاد؟';
  static const String coachOpinion = 'نظر مربی';
  static const String mySuggestion = 'پیشنهاد من';
  static const String myCoachTitle = 'مربی من';
  static const String todayWorkout = 'تمرین امروز';
  static const String recovery = 'ریکاوری';
  static const String workoutSummary = 'خلاصه تمرین';
  static const String todayProgram = 'برنامه امروز';
  static const String exerciseTimeline = 'برنامه حرکات';
  static const String coachNotes = 'یادداشت مربی';
  static const String quickActions = 'دسترسی سریع';
  static const String quickTools = 'ابزارهای سریع';
  static const String progressAnalysis = 'تحلیل پیشرفت';
  static const String logWorkout = 'ثبت تمرین';
  static const String programOrbit = 'درخواست برنامه';
  static const String requestWorkoutProgram = 'درخواست برنامه تمرینی';
  static const String chatWithCoach = 'مشاوره با من';
  static const String mealPlanOrbit = 'برنامه غذایی';
  static const String mealPlanComingSoon = 'برنامه غذایی به‌زودی فعال می‌شود.';
  static const String chatNoProgramRedirect =
      'من داخل چت برنامه تمرینی یا غذایی کامل نمی‌دم.\n\n'
      'اگر می‌خوای برنامه بگیری:\n'
      '• از بخش «مربیان» مربی اختصاصی بگیر\n'
      '• یا از «مربی هوشمند» → درخواست برنامه تمرینی استفاده کن '
      '(با اشتراک و توکن ساخت)\n\n'
      'چت فقط برای مشاوره، تمرین امروز، ریکاوری و راهنمایی کوتاهه.';
  static const String coachMonitorTitle = 'وضعیت امروز';
  static const String coachTipTitle = 'نکته مربی';
  static const String coachGuideTitle = 'راهنمای سریع';
  static const String startWorkout = 'شروع ثبت ست‌ها';
  static const String goToTodayWorkout = 'برو به تمرین امروز';
  static const String workoutSession = 'ثبت ست‌ها';
  static const String liveSessionModeHint =
      'اینجا فقط ست‌ها را ثبت کن. برنامه و روز را از تمرین امروز عوض کن.';
  static const String liveSessionInProgress = 'در حال اجرا';
  static const String coachHelp = 'کمک مربی';
  static const String changeSessionInToday =
      'برای عوض کردن روز یا برنامه، به تمرین امروز برگرد.';
  static const String sets = 'ست‌ها';
  static const String restTimer = 'استراحت بین ست';
  static const String currentExercise = 'حرکت فعلی';
  static const String upcomingExercise = 'حرکت بعدی';
  static const String coachTips = 'نکته مربی';
  static const String progress = 'پیشرفت';
  static const String today = 'امروز';
  static const String todayOrbit = 'تمرین امروز';
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
  static const String programReadySnackbar =
      'برنامه‌ات آماده شد — از «تمرین امروز» یا لیست برنامه‌ها ببینش.';
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
  static const String askFormTip = 'فرم اجرا';
  static const String askFormPrompt = 'تکنیک و فرم حرکتم رو چک کن و راهنمایی بده.';
  static const String weeklyFocusFallback =
      'این هفته روی ثبات تمرین تمرکز کن — کیفیت ست‌ها مهم‌تر از وزنه اضافیه.';
  static const String todayPrepHint =
      'این صفحه برای انتخاب برنامه و مرور جلسه‌ست. ثبت ست‌ها بعد از شروع.';
  static const String modifyProgramTitle = 'اصلاح برنامه';
  static const String modifyProgramHint =
      'انتخاب کن چه می‌خواهی. مربی یک پیشنهاد واضح می‌دهد؛ با تأیید روی برنامه ذخیره می‌شود.';

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
