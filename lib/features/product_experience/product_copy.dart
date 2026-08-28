import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// Persian product labels (EPIC 32) — formatting lives in [ProductExperienceFormatter].
abstract final class ProductCopy {
  static const String coachBriefTitle = 'خلاصه مربی';
  static const String knownAboutYouTitle = 'چیزی که از تو می‌دانم';
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
      'اینجا مشاوره می‌دم، نه اینکه برنامهٔ کامل چندجلسه‌ای یا رژیم کامل بنویسم.\n\n'
      'اگر برنامهٔ شخصی‌سازی‌شده می‌خوای:\n'
      '• «مربیان» → سفارش از مربی واقعی\n'
      '• «مربی من» → درخواست برنامه (برنامه مربی هوشمند)\n\n'
      'ولی سوال کوتاه درباره تمرین امروز، تغذیه، ریکاوری یا تکنیک رو همین‌جا بپرس — جواب می‌دم.';
  static const String chatDailyLimitReached =
      'سقف پیام‌های رایگان مشاوره امروز تموم شده.\n'
      'فردا دوباره بیا، یا بعد از ساخت «برنامه مربی هوشمند» بدون سقف روزانه مشاوره بگیر.';

  /// Free-tier remaining counter shown above the chat composer.
  static String chatDailyQuotaHint({
    required int remaining,
    required int limit,
  }) {
    if (remaining <= 0) {
      return 'امروز پیام رایگان نداری — فردا ریست می‌شه';
    }
    return 'امروز $remaining از $limit پیام رایگان باقی مانده';
  }

  static const String lastNightSleepTitle = 'خواب مفید دیشب';
  static const String lastNightSleepGateBody =
      'قبل از دیدن آمادگی امروز، بگو دیشب چند ساعت واقعاً خوابیدی — نه فقط زمانی که در رختخواب بودی.';
  static const String lastNightSleepHint =
      'با همین عدد، آمادگی و توصیه‌های امروز دقیق‌تر می‌شوند.';
  static const String lastNightSleepSubmit = 'نمایش ریکاوری';
  static const String lastNightSleepUpdate = 'به‌روز کردن ریکاوری';
  static const String lastNightSleepEdit = 'ویرایش خواب دیشب';
  static const String lastNightSleepRangeHint = 'از ۳ تا ۱۰ ساعت';

  static const String coachMonitorTitle = 'وضعیت امروز';
  static const String coachTipTitle = 'نکته مربی';
  static const String decisionCardTitle = 'تحلیل مربی';
  static const String sessionDebriefTitle = 'حرف مربی';
  static const String coachObservationsTitle = 'چیزایی که دیدم';
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
  static const String buildProgramCta = 'بساز برنامه‌ام';
  static const String buildProgramAlreadyPaidHint = 'قبلاً حساب شده';
  static const String buildProgramPayOnBuildHint =
      'با زدن «بساز»، هزینه گرفته می‌شه. '
      'اعتبار دوره‌ات از وقتی برنامه‌ات آماده بشه شروع می‌شه.';
  static const String manageAiProgramOrbit = 'برنامه‌ام';
  static const String existingAiProgramTitle = 'برنامه‌ات آماده‌ست';
  static const String existingAiProgramModifyHint =
      'حرکت عوض کن، حجم تنظیم کن، یا برنامه رو با مربی اصلاح کن.';
  static const String existingAiProgramTodayHint =
      'برو سراغ جلسه امروز و تمرینت رو شروع کن.';
  static const String existingAiProgramProgramsCta = 'برنامه‌های هوش مصنوعی';
  static const String existingAiProgramProgramsHint =
      'لیست برنامه‌هات رو ببین و برنامه فعال را عوض کن.';
  static const String existingAiProgramBuildNewCta =
      'می‌خوام برنامه جدید بسازم';
  static const String existingAiProgramBuildNewConfirmTitle =
      'ساخت برنامه جدید؟';
  static const String existingAiProgramBuildNewConfirmBody =
      'برنامه فعلی‌ات سر جاش می‌مونه. یک برنامه جدید از صفر ساخته می‌شه '
      'و می‌تونی بعداً همون را فعال کنی.';
  static const String programReadySnackbar =
      'برنامه‌ات آماده‌ست — برو تمرین امروز رو ببین.';
  static const String difficultyLabel = 'سطح سختی';
  static const String exercisesCount = 'حرکت';
  static const String minutes = 'دقیقه';
  static const String completeSet = 'تکمیل ست';
  static const String nextExercise = 'حرکت بعدی';
  static const String finishWorkout = 'پایان تمرین';
  static const String finishWorkoutAndAnalyze = 'تمرین تموم شد — تحلیلش کن';
  static const String finishWorkoutAndAnalyzeHint =
      'حداقل یه ست ثبت کن تا بتونم جمع‌بندی کنم.';
  static const String resumeSessionEditing = 'می‌خوام ست‌ها رو ویرایش کنم';
  static const String sessionAnalysisTitle = 'تحلیل جلسه';
  static const String sessionAnalysisThinking = 'دارم جلسه‌ت رو جمع می‌کنم...';
  static const String sessionLoggedWorkTitle = 'چی زدی';
  static const String sessionCompletionTitle = 'وضعیت تکمیل';
  static const String skippedExercisesTitle = 'حرکات انجام‌نشده';
  static const String skippedExercisesCoachNote =
      'حذف کردن حرکت یعنی برنامه سنگین بوده، نه اینکه تو ضعیف باشی.';
  static const String sessionCompareTitle = 'نسبت به قبل';
  static const String sessionSuggestionsTitle = 'جلسه بعد';
  static const String nextFocusTitle = 'برای جلسه بعد';
  static const String modifyProgramLockedTitle =
      'این‌جا نمی‌شه برنامه رو عوض کرد';
  static const String modifyProgramLockedBody =
      'این برنامه رایگانه و عمومی؛ برای همین اصلاح خودکار روش قفل شده. '
      'تحلیل جلسه رو داری. اگه بخوای برنامه خودش عوض بشه، باید برنامهٔ شخصی مربی هوشمند داشته باشی.';
  static const String modifyProgramLockedHint =
      'تحلیل هست؛ عوض کردن برنامه روی نسخهٔ عمومی قفل شده.';
  static const String modifyProgramLockedCta = 'اصلاح برنامه (قفل)';
  static const String skipRest = 'رد کردن استراحت';
  static const String effortLevel = 'شدت تلاش';
  static const String coachDisabledTitle = 'مربی هنوز فعال نیست';
  static const String retry = 'دوباره امتحان کن';
  static const String genericError = 'یه مشکلی پیش اومد';
  static const String askFormTip = 'فرم اجرا';
  static const String askFormPrompt =
      'تکنیک و فرم حرکتم رو چک کن و راهنمایی بده.';
  static const String weeklyFocusFallback =
      'این هفته روی ثبات تمرین تمرکز کن — کیفیت ست‌ها مهم‌تر از وزنه اضافیه.';
  static const String todayPrepHint =
      'این صفحه برای انتخاب برنامه و مرور جلسه‌ست. ثبت ست‌ها بعد از شروع.';
  static const String modifyProgramTitle = 'اصلاح برنامه';
  static const String modifyProgramHint =
      'انتخاب کن چه می‌خواهی. مربی یک پیشنهاد واضح می‌دهد؛ با تأیید روی برنامه ذخیره می‌شود.';

  static String estimatedCaloriesLabel(int kcal) =>
      'حدود $kcal کالری — تقریبیه';

  static String incompleteSessionHint({
    required int completed,
    required int planned,
  }) => 'جلسه کامل نشد — $completed از $planned حرکت.';

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
