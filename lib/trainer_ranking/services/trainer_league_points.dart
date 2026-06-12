import 'dart:math' as math;

/// ورودی خام برای امتیاز تجمعی (لیگ / تشویق تعامل).
///
/// فقط **[sentWorkoutPrograms]** برای برنامه شمرده می‌شود (ارسال‌شده؛ پیش‌نویس امتیاز ندارد).
class TrainerLeaguePointsInput {
  const TrainerLeaguePointsInput({
    required this.totalStudents,
    required this.sentWorkoutPrograms,
    required this.sumReviewStars,
    required this.medianDeliveryHours,
    required this.deliverySampleCount,
    required this.privateCustomExercises,
    required this.publicCustomExercises,
    required this.customMusicCount,
    required this.approvedCertificateCount,
    this.eventBonusPoints = 0,
  });

  /// همهٔ شاگردان ثبت‌شده در `trainer_clients`.
  final int totalStudents;

  /// فقط برنامه‌های **ارسال‌شده** (`sent_at` پر).
  final int sentWorkoutPrograms;

  /// جمع ستارهٔ هر نظر (۱…۵ به ازای هر ردیف `trainer_reviews`).
  final int sumReviewStars;

  final double medianDeliveryHours;
  final int deliverySampleCount;

  /// `visibility != 'public'` در `custom_exercises`.
  final int privateCustomExercises;

  /// `visibility == 'public'`.
  final int publicCustomExercises;

  final int customMusicCount;
  final int approvedCertificateCount;

  /// بونوس کمپین/چالش/روزانه از `TrainerLeagueBonusRegistry` (فعلاً معمولاً ۰).
  final int eventBonusPoints;
}

/// جزءبه‌جزء امتیازهای عددی (بدون درصد).
class TrainerLeaguePointsBreakdown {
  const TrainerLeaguePointsBreakdown({
    required this.studentPoints,
    required this.sentProgramPoints,
    required this.reviewStarPoints,
    required this.deliveryPoints,
    required this.musicPoints,
    required this.privateExercisePoints,
    required this.publicExercisePoints,
    required this.certificatePoints,
    required this.eventBonusPoints,
    required this.totalPoints,
    required this.deliverySkippedInsufficientData,
  });

  final int studentPoints;
  final int sentProgramPoints;
  final int reviewStarPoints;

  /// ۰ تا ۵ (طبق تعریف محصول؛ عمداً کوچک نگه داشته می‌شود نسبت به حجم تعامل).
  final int deliveryPoints;
  final int musicPoints;
  final int privateExercisePoints;
  final int publicExercisePoints;

  /// بونوس یک‌بارهٔ اعتماد (مدارک تأییدشده).
  final int certificatePoints;

  /// بونوس رویدادی / چالش (آینده).
  final int eventBonusPoints;

  final int totalPoints;
  final bool deliverySkippedInsufficientData;
}

/// امتیاز تجمعی مربی: **جمع ساده** + ضرایب ثابت (قابل تنظیم برای بالانس و A/B).
///
/// جهت‌گیری: اپ‌های پرمخاطب معمولاً **پیشرفت ملموس**، **چالش کوتاه‌مدت** و
/// **پاداش فوری بعد از اقدام** را ترکیب می‌کنند؛ اینجا پایهٔ «اقدام در اپ»
/// (تمرین، موزیک، ارسال برنامه) عمداً از «تحویل سریع» و «مدرک» قوی‌تر است
/// تا تعامل را تقویت کند — تحویل و مدرک همچنان در جمع هستند ولی سهم کوچک‌تری دارند.
class TrainerLeaguePoints {
  TrainerLeaguePoints._();

  // ——— تعامل و ارزش پلتفرم (بازتنظیم ۲۰۲۶) ———

  /// شاگرد = پیوستگی به پلتفرم؛ خطی ساده.
  static const int kPointsPerStudent = 4;

  /// **فقط** برنامهٔ ارسال‌شده؛ محور اصلی همراست با درآمد/ارزش تحویل به شاگرد.
  static const int kPointsPerSentProgram = 12;

  static const int kPointsPerMusic = 6;
  static const int kPointsPerPrivateExercise = 12;
  static const int kPointsPerPublicExercise = 24;

  static const int kCertificateMinApproved = 3;
  static const int kCertificateBonusPoints = 45;

  static const int minDeliverySamplesForScore = 3;

  /// هستهٔ امتیاز بدون بونوس رویدادی (برای تست یا کش سرور).
  static TrainerLeaguePointsBreakdown computeCore(
    TrainerLeaguePointsInput in_,
  ) {
    return compute(
      TrainerLeaguePointsInput(
        totalStudents: in_.totalStudents,
        sentWorkoutPrograms: in_.sentWorkoutPrograms,
        sumReviewStars: in_.sumReviewStars,
        medianDeliveryHours: in_.medianDeliveryHours,
        deliverySampleCount: in_.deliverySampleCount,
        privateCustomExercises: in_.privateCustomExercises,
        publicCustomExercises: in_.publicCustomExercises,
        customMusicCount: in_.customMusicCount,
        approvedCertificateCount: in_.approvedCertificateCount,
      ),
    );
  }

  static TrainerLeaguePointsBreakdown compute(TrainerLeaguePointsInput in_) {
    final students = math.max(0, in_.totalStudents);
    final sent = math.max(0, in_.sentWorkoutPrograms);

    final studentPoints = students * kPointsPerStudent;
    final sentProgramPoints = sent * kPointsPerSentProgram;

    final reviewStarPoints = math.max(0, in_.sumReviewStars);

    final deliverySkipped = in_.deliverySampleCount < minDeliverySamplesForScore ||
        in_.medianDeliveryHours.isNaN ||
        in_.medianDeliveryHours.isInfinite;
    final deliveryPoints = deliverySkipped
        ? 0
        : _deliveryMedianToPoints(in_.medianDeliveryHours);

    final music = math.max(0, in_.customMusicCount);
    final musicPoints = music * kPointsPerMusic;

    final privEx = math.max(0, in_.privateCustomExercises);
    final pubEx = math.max(0, in_.publicCustomExercises);
    final privateExercisePoints = privEx * kPointsPerPrivateExercise;
    final publicExercisePoints = pubEx * kPointsPerPublicExercise;

    final cert = math.max(0, in_.approvedCertificateCount);
    final certificatePoints =
        cert >= kCertificateMinApproved ? kCertificateBonusPoints : 0;

    final bonus = math.max(0, in_.eventBonusPoints);

    final totalPoints = studentPoints +
        sentProgramPoints +
        reviewStarPoints +
        deliveryPoints +
        musicPoints +
        privateExercisePoints +
        publicExercisePoints +
        certificatePoints +
        bonus;

    return TrainerLeaguePointsBreakdown(
      studentPoints: studentPoints,
      sentProgramPoints: sentProgramPoints,
      reviewStarPoints: reviewStarPoints,
      deliveryPoints: deliveryPoints,
      musicPoints: musicPoints,
      privateExercisePoints: privateExercisePoints,
      publicExercisePoints: publicExercisePoints,
      certificatePoints: certificatePoints,
      eventBonusPoints: bonus,
      totalPoints: totalPoints,
      deliverySkippedInsufficientData: deliverySkipped,
    );
  }

  /// ۱ ضعیف‌ترین … ۵ بهترین؛ بر اساس میانهٔ ساعت تا `sent_at`.
  static int _deliveryMedianToPoints(double medianHours) {
    final h = medianHours.clamp(0.0, 500.0);
    if (h <= 12) return 5;
    if (h <= 24) return 4;
    if (h <= 48) return 3;
    if (h <= 96) return 2;
    return 1;
  }
}
