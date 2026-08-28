import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';

/// Deterministic science prescription injected into the paid LLM prompt.
///
/// Numbers come from [WorkoutScience], not from the model. Citations live in
/// that class; this file only renders operational Persian constraints.
abstract final class LlmWorkoutScienceBrief {
  const LlmWorkoutScienceBrief._();

  static String build({
    required CoachContext context,
    required int daysPerWeek,
    required String experience,
  }) {
    final goal = WorkoutScience.goalFromProfile(
      context.goals,
      '$experience ${context.goals.join(' ')}',
    );
    final chest = WorkoutScience.weeklySetBand(
      goal: goal,
      experience: experience,
      bucket: MuscleBucket.chest,
    );
    final back = WorkoutScience.weeklySetBand(
      goal: goal,
      experience: experience,
      bucket: MuscleBucket.back,
    );
    final quads = WorkoutScience.weeklySetBand(
      goal: goal,
      experience: experience,
      bucket: MuscleBucket.quads,
    );
    final ham = WorkoutScience.weeklySetBand(
      goal: goal,
      experience: experience,
      bucket: MuscleBucket.hamstrings,
    );
    final freq = WorkoutScience.muscleFrequencyForDays(daysPerWeek);
    final (minReps, maxReps) = WorkoutScience.repRange(goal);
    final compoundRest = WorkoutScience.compoundRestSeconds(goal);
    final isolationRest = WorkoutScience.isolationRestSeconds(goal);
    final rir = WorkoutScience.rirGuidance(experience);
    final compoundSets = WorkoutScience.setCountForExercise(
      goal,
      experience,
      true,
    );
    final isolationSets = WorkoutScience.setCountForExercise(
      goal,
      experience,
      false,
    );
    final beginner = WorkoutScience.isBeginnerExperience(experience);
    final split = _splitLine(daysPerWeek: daysPerWeek, beginner: beginner);
    final compoundForSplit =
        (!beginner && daysPerWeek <= 3 && compoundSets < 4)
        ? 4
        : compoundSets;

    return '''
### نسخه علمی اجباری (از موتور داخلی — حدس نزن)
مراجع عملی: ACSM Position Stand 2009 (فرکانس/تکرار مبتدی)، Schoenfeld 2016–2017 (فرکانس و حجم هفتگی)، Helms/ISSN 2014 و پروتکل مربیان فیزیک مثل Helms و Israetel (۱۰–۲۰ ست سخت/عضله). حرکت‌ها باشگاهی ایران باشند؛ حجم و فرکانس از این جدول خارج نشود.

- هدف کدشده: ${goal.name}
- اسپلیت: $split
- فرکانس هر عضله بزرگ: ${freq}× در هفته${freq == 1 ? ' (۳روزه: حجم همان جلسه را بالا ببر تا به حداقل ست هفتگی برسی)' : ''}
- ست سخت هفتگی سینه: حداقل ${chest.min} / هدف ${chest.target} / سقف ${chest.max}
- ست سخت هفتگی پشت: حداقل ${back.min} / هدف ${back.target} / سقف ${back.max}
- ست سخت هفتگی چهارسر: حداقل ${quads.min} / هدف ${quads.target} / سقف ${quads.max}
- ست سخت هفتگی همسترینگ: حداقل ${ham.min} / هدف ${ham.target} (روز پا بدون پشت‌پا/هیپ ناقص است)
- ست هر حرکت مرکب: $compoundForSplit | ایزوله: $isolationSets
- تکرار هدف: $minReps–$maxReps (همه ست‌ها را یکی نکن)
- استراحت: مرکب ~${compoundRest}s | ایزوله ~${isolationRest}s
- شدت: $rir
- تعادل فشار/کشش: حجم پشت ≥ حدود ۸۰٪ حجم سینه (محافظت شانه)
- روز پا: حداقل یک حرکت زنجیره خلفی (لگ‌کرل / رومانیایی / هیپ‌تراست)
- مبتدی: اول مرکب آشنا، تکنیک بر حجم اضافه؛ پیشرفته: حجم بالاتر نه حرکت عجیب آزمایشگاهی
''';
  }

  static String _splitLine({required int daysPerWeek, required bool beginner}) {
    if (daysPerWeek <= 2) {
      return 'تمام‌بدن ${daysPerWeek} روز — هر عضله ۲ بار در هفته';
    }
    if (daysPerWeek == 3) {
      return beginner
          ? 'تمام‌بدن ۳ روز (ACSM مبتدی) — هر عضله ۳ بار'
          : 'فشار / کشش / پا — هر عضله ۱ بار؛ ست مرکب را ۴ تایی بگیر تا حجم هفتگی کم نیاید';
    }
    if (daysPerWeek == 4) {
      return 'بالاتنه / پایین‌تنه ×۲ — هر عضله ۲ بار (بهتر از اسپلیت ۱ جلسه‌ای)';
    }
    return 'فشار/کشش/پا ×۲ — هر عضله ۲ بار؛ اسپلیت سینه-تنها / پشت-تنها (۱× در هفته) ممنوع';
  }
}
