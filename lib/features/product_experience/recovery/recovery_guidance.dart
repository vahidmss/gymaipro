import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';

/// High-level coaching situation for recovery copy and CTAs.
enum RecoveryScenario {
  /// Meaningful workout already logged today — focus on recovery, not intensity.
  postSessionToday,

  /// Ready for a normal/hard session.
  readyToTrain,

  /// Can train, but with a warmer start / moderate intensity.
  trainCautiously,

  /// Better to lighten or rest before starting today's work.
  needsRestOrLighter,

  /// Several rest days — ease back in.
  returningAfterBreak,

  /// Not enough signals yet.
  unknown,
}

enum RecoveryBand { high, mid, low, unknown }

/// Local recovery coach copy — shared by Recovery screen and RecoverySkill.
class RecoveryGuidance {
  const RecoveryGuidance({
    required this.snapshot,
    required this.band,
    required this.scenario,
    required this.headline,
    required this.body,
    required this.tips,
    required this.suggestLighterSession,
    required this.suggestStartWorkout,
    this.daysSinceLastWorkout,
  });

  factory RecoveryGuidance.fromContext(CoachContext context) {
    final snapshot = ProductExperienceFormatter.recoverySnapshot(
      context: context,
    );
    return RecoveryGuidance.fromSnapshot(
      snapshot,
      daysSinceLastWorkout:
          snapshot.daysSinceLastWorkout ?? _daysSince(context),
    );
  }

  factory RecoveryGuidance.fromSnapshot(
    CoachRecoverySnapshot snapshot, {
    int? daysSinceLastWorkout,
  }) {
    final days = daysSinceLastWorkout ?? snapshot.daysSinceLastWorkout;
    final band = _bandFor(snapshot.readiness);
    final scenario = _scenarioFor(
      band: band,
      snapshot: snapshot,
      daysSinceLastWorkout: days,
    );

    return RecoveryGuidance(
      snapshot: snapshot,
      band: band,
      scenario: scenario,
      headline: _headlineFor(scenario),
      body: _bodyFor(
        scenario: scenario,
        snapshot: snapshot,
        daysSinceLastWorkout: days,
      ),
      tips: _tipsFor(
        scenario: scenario,
        snapshot: snapshot,
        daysSinceLastWorkout: days,
      ),
      suggestLighterSession: scenario == RecoveryScenario.needsRestOrLighter,
      suggestStartWorkout: scenario == RecoveryScenario.readyToTrain ||
          scenario == RecoveryScenario.trainCautiously ||
          scenario == RecoveryScenario.returningAfterBreak,
      daysSinceLastWorkout: days,
    );
  }

  final CoachRecoverySnapshot snapshot;
  final RecoveryBand band;
  final RecoveryScenario scenario;
  final String headline;
  final String body;
  final List<String> tips;
  final bool suggestLighterSession;
  final bool suggestStartWorkout;
  final int? daysSinceLastWorkout;

  bool get trainedToday =>
      scenario == RecoveryScenario.postSessionToday ||
      (daysSinceLastWorkout != null && daysSinceLastWorkout! <= 0);

  /// Full chat / skill message in Persian.
  String get chatMessage {
    final buffer = StringBuffer()
      ..writeln(headline)
      ..writeln()
      ..writeln(body);
    if (tips.isNotEmpty) {
      buffer.writeln();
      for (final tip in tips) {
        buffer.writeln('• $tip');
      }
    }
    return buffer.toString().trim();
  }

  static RecoveryBand _bandFor(int readiness) {
    if (readiness <= 0) return RecoveryBand.unknown;
    if (readiness >= 70) return RecoveryBand.high;
    if (readiness >= 45) return RecoveryBand.mid;
    return RecoveryBand.low;
  }

  static RecoveryScenario _scenarioFor({
    required RecoveryBand band,
    required CoachRecoverySnapshot snapshot,
    int? daysSinceLastWorkout,
  }) {
    // Already trained today: readiness drop is expected — never tell them to
    // "train lighter today" as if the session were still ahead.
    if (daysSinceLastWorkout != null && daysSinceLastWorkout <= 0) {
      return RecoveryScenario.postSessionToday;
    }

    if (band == RecoveryBand.unknown) {
      return RecoveryScenario.unknown;
    }

    if (daysSinceLastWorkout != null && daysSinceLastWorkout >= 4) {
      return RecoveryScenario.returningAfterBreak;
    }

    return switch (band) {
      RecoveryBand.high => RecoveryScenario.readyToTrain,
      RecoveryBand.mid =>
        snapshot.fatigue >= 65
            ? RecoveryScenario.needsRestOrLighter
            : RecoveryScenario.trainCautiously,
      RecoveryBand.low => RecoveryScenario.needsRestOrLighter,
      RecoveryBand.unknown => RecoveryScenario.unknown,
    };
  }

  static String _headlineFor(RecoveryScenario scenario) {
    return switch (scenario) {
      RecoveryScenario.postSessionToday => 'جلسه امروزت ثبت شد — حالا نوبت ریکاوری است',
      RecoveryScenario.readyToTrain => 'آمادگی امروز خوبه',
      RecoveryScenario.trainCautiously => 'آمادگی امروز متوسطه',
      RecoveryScenario.needsRestOrLighter => 'بدن امروز به فشار کمتر نیاز دارد',
      RecoveryScenario.returningAfterBreak => 'بعد از چند روز فاصله، آرام برگرد',
      RecoveryScenario.unknown => 'هنوز تصویر کامل از ریکاوری نداریم',
    };
  }

  static String _metricsLine(CoachRecoverySnapshot snapshot) {
    final metrics = <String>[];
    if (snapshot.readiness > 0) {
      metrics.add('آمادگی ${snapshot.readiness}٪');
    }
    if (snapshot.recovery > 0) {
      metrics.add('ریکاوری ${snapshot.recovery}');
    }
    if (snapshot.fatigue > 0) {
      metrics.add('خستگی ${snapshot.fatigue}');
    }
    if (snapshot.sleep > 0) {
      metrics.add('خواب ${snapshot.sleep}');
    }
    if (metrics.isEmpty) {
      return 'هنوز دادهٔ کافی از جلسهٔ اخیر نداریم.';
    }
    return 'وضعیت فعلی: ${metrics.join(' · ')}.';
  }

  static String _bodyFor({
    required RecoveryScenario scenario,
    required CoachRecoverySnapshot snapshot,
    int? daysSinceLastWorkout,
  }) {
    final metrics = _metricsLine(snapshot);

    return switch (scenario) {
      RecoveryScenario.postSessionToday =>
        '$metrics تمرین امروزت انجام شده و عدد آمادگی معمولاً بعد از جلسه پایین‌تر می‌آید — این یعنی بدنت وارد فاز ریکاوری شده، نه اینکه باید دوباره امروز سبک‌تر تمرین کنی. امشب روی خواب، آب و تغذیه تمرکز کن تا برای جلسه بعد آماده‌تر باشی.',
      RecoveryScenario.readyToTrain =>
        '$metrics می‌تونی جلسه را با شدت برنامه‌ریزی‌شده پیش ببری؛ روی فرم ست‌های اصلی تمرکز کن.',
      RecoveryScenario.trainCautiously =>
        '$metrics تمرین کردن مشکلی نداره؛ یکی دو ست اول را گرم‌تر بگیر و فشار را پله‌پله بالا ببر.',
      RecoveryScenario.needsRestOrLighter => () {
          final restGap = daysSinceLastWorkout == null
              ? ''
              : daysSinceLastWorkout == 1
              ? ' از آخرین تمرین حدود ۱ روز گذشته.'
              : ' از آخرین تمرین حدود $daysSinceLastWorkout روز گذشته.';
          return '$metrics$restGap اگر هنوز تمرین امروز را شروع نکرده‌ای، بهتر است حجم یا شدت را کم کنی؛ کیفیت فرم مهم‌تر از سنگینی است.';
        }(),
      RecoveryScenario.returningAfterBreak =>
        '$metrics حدود $daysSinceLastWorkout روز از آخرین تمرین گذشته. با شدت متوسط برگرد، نه با حداکثر توان — بدن دوباره هماهنگ می‌شود.',
      RecoveryScenario.unknown =>
        '$metrics بعد از ثبت چند جلسه، آمادگی دقیق‌تر محاسبه می‌شود. فعلاً با حس بدنت شدت را تنظیم کن.',
    };
  }

  static List<String> _tipsFor({
    required RecoveryScenario scenario,
    required CoachRecoverySnapshot snapshot,
    int? daysSinceLastWorkout,
  }) {
    final tips = <String>[];

    switch (scenario) {
      case RecoveryScenario.postSessionToday:
        tips
          ..add('امشب خواب کافی بگیر؛ ریکاوری واقعی از همین‌جا شروع می‌شود.')
          ..add('پروتئین و آب را جدی بگیر تا ترمیم عضله بهتر پیش برود.')
          ..add('اگر کوفتگی عادی داری طبیعیه؛ درد تیز یا غیرعادی را جدی بگیر.');
        if (snapshot.fatigue >= 65) {
          tips.add(
            'خستگی بالاست؛ فردا اگر جلسه سنگینی داری، با گرم‌کردن بیشتر شروع کن.',
          );
        } else {
          tips.add(
            'فردا بر اساس حس بدنت تصمیم بگیر؛ نیازی نیست همین امشب دوباره فشار اضافه کنی.',
          );
        }
      case RecoveryScenario.readyToTrain:
        tips
          ..add('ست‌های اصلی را کامل اجرا کن و RPE را واقع‌بینانه ثبت کن.')
          ..add('خواب و تغذیه امروز را مثل روز تمرین جدی بگیر.');
      case RecoveryScenario.trainCautiously:
        tips
          ..add('گرم‌کردن را کمی طولانی‌تر کن.')
          ..add('اگر وسط جلسه افت کردی، یک ست کم کن به‌جای رها کردن کامل.');
      case RecoveryScenario.needsRestOrLighter:
        tips
          ..add('حجم یا وزن را کم کن؛ کیفیت فرم مهم‌تر از سنگینی است.')
          ..add(
            'اگر درد یا کوفتگی شدید داری، استراحت فعال یا پیاده‌روی سبک بهتر است.',
          );
      case RecoveryScenario.returningAfterBreak:
        tips
          ..add('اولین جلسه برگشت را کوتاه‌تر یا سبک‌تر از حد معمول بگیر.')
          ..add('روی دامنه حرکتی و فرم تمرکز کن، نه رکورد زدن.');
        if (daysSinceLastWorkout != null && daysSinceLastWorkout >= 7) {
          tips.add(
            'بیش از یک هفته فاصله داشته‌ای؛ عجله نکن، ۲–۳ جلسه طول می‌کشد تا ریتم برگردد.',
          );
        }
      case RecoveryScenario.unknown:
        tips
          ..add('یک جلسه کامل ثبت کن تا آمادگی از دادهٔ واقعی به‌روز شود.')
          ..add('ساعت خواب را در پروفایل وارد کن تا تخمین دقیق‌تر شود.');
    }

    return tips;
  }

  static int? _daysSince(CoachContext context) {
    final raw = context.preferences['days_since_last_workout'];
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return int.tryParse(raw?.toString() ?? '');
  }
}
