import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/generator/llm_workout_muscle_tags.dart';
import 'package:gymaipro/ai/workout/labels/workout_session_labels.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';

/// Lightweight checks after LLM output (engines validate, they do not author).
abstract final class LlmWorkoutProgramValidator {
  const LlmWorkoutProgramValidator._();

  static List<String> validate(
    WorkoutProgram program, {
    required Set<int> allowedExerciseIds,
    required int expectedDaysPerWeek,
    TrainingGoal? goal,
    String? experience,
  }) {
    final issues = <String>[];

    if (program.name.trim().isEmpty) {
      issues.add('نام برنامه خالی است.');
    }
    final nameIssue = _badProgramName(program.name);
    if (nameIssue != null) issues.add(nameIssue);

    final days = program.allDays;
    if (days.isEmpty) {
      issues.add('هیچ جلسه تمرینی وجود ندارد.');
      return issues;
    }

    if (expectedDaysPerWeek > 0 && days.length != expectedDaysPerWeek) {
      issues.add(
        'تعداد جلسات باید دقیقاً $expectedDaysPerWeek باشد '
        '(الان ${days.length}).',
      );
    }

    final globalIds = <int>{};
    final daySignatures = <String>[];

    for (final day in days) {
      if (day.label.trim().isEmpty) {
        issues.add('برچسب روز خالی است.');
      }
      if (day.exercises.isEmpty) {
        issues.add('روز «${day.label}» بدون حرکت است.');
        continue;
      }

      final isCardioHeavy = _looksLikeCardioDay(day.label);
      final minExercises = isCardioHeavy ? 4 : 5;
      if (day.exercises.length < minExercises) {
        issues.add(
          'روز «${day.label}» حداقل $minExercises حرکت لازم دارد '
          '(الان ${day.exercises.length}).',
        );
      }

      final dayIds = <int>{};
      final muscles = <String>[];
      for (final exercise in day.exercises) {
        if (exercise.catalogExerciseId <= 0) {
          issues.add('حرکت «${exercise.name}» شناسه معتبر از کاتالوگ ندارد.');
          continue;
        }
        if (!allowedExerciseIds.contains(exercise.catalogExerciseId)) {
          issues.add(
            'حرکت id=${exercise.catalogExerciseId} در فهرست مجاز نیست.',
          );
        }
        if (!dayIds.add(exercise.catalogExerciseId)) {
          issues.add('حرکت تکراری در روز «${day.label}»: ${exercise.name}');
        }
        if (!globalIds.add(exercise.catalogExerciseId)) {
          issues.add(
            'حرکت تکراری در کل برنامه: ${exercise.name} '
            '(id=${exercise.catalogExerciseId}).',
          );
        }
        if (exercise.sets.isEmpty) {
          issues.add('حرکت «${exercise.name}» ست ندارد.');
        }
        final muscle = exercise.primaryMuscle.trim().toLowerCase();
        if (muscle.isNotEmpty) muscles.add(muscle);
      }
      daySignatures.add(muscles.join('|'));

      issues.addAll(_dayFocusIssues(day.label, muscles, day.exercises.length));
      issues.addAll(_dayVolumeIssues(day.label, day.exercises));
    }

    if (days.length >= 3 &&
        daySignatures.length >= 3 &&
        daySignatures.toSet().length == 1) {
      issues.add(
        'الگوی عضلات هر سه روز یکسان است؛ روزها باید متمایز و متنوع باشند.',
      );
    }

    final labels = days.map((d) => d.label.trim()).where((l) => l.isNotEmpty);
    if (WorkoutSessionLabels.hasDuplicateLabels(labels)) {
      issues.add(
        'نام جلسه‌ها تکراری است؛ هر روز باید نام یکتا داشته باشد '
        '(مثلاً «روز ۱ — بالاتنه ۱» و «روز ۳ — بالاتنه ۲»، نه دو تا «فشار»).',
      );
    }

    if (goal != null && experience != null && days.length >= 3) {
      issues.addAll(
        _weeklyVolumeIssues(program, goal: goal, experience: experience),
      );
    }

    return issues;
  }

  static String? _badProgramName(String name) {
    final n = name.trim();
    if (_isGenericTemplateName(n)) {
      return 'نام برنامه قالبی و ضعیف است؛ یک نام طبیعی و مربی‌گونه بساز.';
    }
    final banned = <String>[
      'حرکات آشنا',
      'با حرکات پایه',
      'حرکات پایه',
      'حرکت آشنا',
      'آشنای باشگاهی',
      'حرکات رایج',
      'حرکت رایج',
      'برنامه جذاب',
      'جذاب با',
    ];
    for (final token in banned) {
      if (n.contains(token)) {
        return 'نام برنامه مصنوعی/تبلیغاتی است (مثل «حرکات آشنا»). '
            'نامی کوتاه و طبیعی مثل یک مربی باشگاه بگذار '
            '(مثلاً هدف + سبک، بدون توضیح متا).';
      }
    }
    if (n.length > 42) {
      return 'نام برنامه خیلی طولانی است؛ حداکثر حدود ۴۰ کاراکتر.';
    }
    return null;
  }

  static bool _isGenericTemplateName(String name) {
    final n = name.trim();
    final template = RegExp(
      r'^برنامه\s+.+\s*[—\-–]\s*\d+\s*روزه(\s*\(\d+/\d+\))?$',
    );
    return template.hasMatch(n);
  }

  static bool _looksLikeCardioDay(String label) {
    final t = label.toLowerCase();
    return t.contains('کاردیو') || t.contains('هوازی') || t.contains('cardio');
  }

  static bool _isPushDay(String label) {
    final t = label.toLowerCase();
    return t.contains('فشار') || (t.contains('سینه') && !t.contains('پشت'));
  }

  static bool _isPullDay(String label) {
    final t = label.toLowerCase();
    if (t.contains('کشش') || t.contains('پول') || t.contains('pull')) {
      return true;
    }
    if (RegExp(r'پشت\s*بازو').hasMatch(t) || t.contains('پشت‌بازو')) {
      return false;
    }
    return t.contains('پشت') && !t.contains('پا');
  }

  static bool _isLegDay(String label) {
    final t = label.toLowerCase();
    return t.contains('پا') ||
        t.contains('پایین') ||
        t.contains('لگ') ||
        t.contains('leg');
  }

  static List<String> _dayFocusIssues(
    String label,
    List<String> muscles,
    int exerciseCount,
  ) {
    if (muscles.isEmpty) return const <String>[];
    final issues = <String>[];

    int countWhere(bool Function(String) test) => muscles.where(test).length;

    if (_isPushDay(label)) {
      final ok = countWhere(LlmWorkoutMuscleTags.isPushOk);
      final foreign = countWhere(LlmWorkoutMuscleTags.isPushForeign);
      if (ok < 3) {
        issues.add('روز فشار باید عمدتاً سینه/سرشانه/پشت‌بازو باشد.');
      }
      if (foreign > 0) {
        issues.add(
          'روز فشار نباید حرکت پشت/جلوبازو/پا داشته باشد '
          '(الان $foreign حرکت نامرتبط).',
        );
      }
    }

    if (_isPullDay(label)) {
      final ok = countWhere(LlmWorkoutMuscleTags.isPullOk);
      final foreign = countWhere(LlmWorkoutMuscleTags.isPullForeign);
      if (ok < 3) {
        issues.add('روز کشش باید عمدتاً پشت/زیربغل/جلوبازو باشد.');
      }
      if (foreign > 0) {
        issues.add(
          'روز کشش نباید اسکوات/پا/سینه/پشت‌بازو داشته باشد '
          '(الان $foreign حرکت نامرتبط).',
        );
      }
    }

    if (_isLegDay(label)) {
      final ok = countWhere(LlmWorkoutMuscleTags.isLegDayOk);
      final foreign = countWhere(LlmWorkoutMuscleTags.isLegDayForeign);
      if (ok < 3) {
        issues.add('روز پا باید عمدتاً پایین‌تنه باشد.');
      }
      if (foreign > 0) {
        issues.add(
          'روز پا نباید سینه/زیربغل/سرشانه/بازو داشته باشد '
          '(الان $foreign حرکت نامرتبط).',
        );
      }
    }

    if (_looksLikeCardioDay(label) && exerciseCount < 1) {
      issues.add('روز کاردیو باید حرکت داشته باشد.');
    }

    return issues;
  }

  /// Prevent brutal push days (5 heavy presses in a row).
  /// Isolation (fly / raise) does not count toward the 3-press cap.
  static List<String> _dayVolumeIssues(
    String label,
    List<WorkoutExercise> exercises,
  ) {
    if (exercises.isEmpty) return const <String>[];
    final issues = <String>[];

    if (_isPushDay(label)) {
      final chest = exercises
          .where((e) => LlmWorkoutMuscleTags.isChest(e.primaryMuscle))
          .length;
      final shoulder = exercises
          .where((e) => LlmWorkoutMuscleTags.isShoulder(e.primaryMuscle))
          .length;
      final presses = exercises
          .where(
            (e) => LlmWorkoutMuscleTags.isCompoundPress(
              e.name,
              e.primaryMuscle,
            ),
          )
          .length;
      if (chest > 3) {
        issues.add(
          'روز فشار حداکثر ۳ حرکت سینه (۲ پرس + ۱ ایزوله)؛ '
          'الان $chest تا است.',
        );
      }
      if (shoulder > 2) {
        issues.add(
          'روز فشار حداکثر ۲ حرکت سرشانه؛ الان $shoulder تا است '
          '(یکی را با نشر جانب یا پشت‌بازو عوض کن).',
        );
      }
      if (presses > 3) {
        issues.add(
          'روز فشار بیش از حد سنگین است ($presses پرس/فشار). '
          'حداکثر ۳ حرکت فشاری چندمفصلی؛ بقیه ایزوله/سبک‌تر.',
        );
      }
      final hasTriceps = exercises.any(
        (e) => LlmWorkoutMuscleTags.isTricep(e.primaryMuscle),
      );
      if (!hasTriceps && presses >= 3) {
        issues.add(
          'روز فشار بدون پشت‌بازو ناقص است؛ حداقل یک حرکت پشت‌بازو بگذار.',
        );
      }
    }

    if (_isLegDay(label)) {
      final quads = exercises
          .where((e) => LlmWorkoutMuscleTags.isQuad(e.primaryMuscle))
          .length;
      if (quads > 3) {
        issues.add(
          'روز پا بیش از حد چهارسرمحور است؛ همسترینگ/باسن/ساق را متعادل کن.',
        );
      }
    }

    return issues;
  }

  static List<String> _weeklyVolumeIssues(
    WorkoutProgram program, {
    required TrainingGoal goal,
    required String experience,
  }) {
    final sets = <MuscleBucket, int>{};
    for (final day in program.allDays) {
      for (final exercise in day.exercises) {
        final bucket = WorkoutScience.muscleBucket(exercise.primaryMuscle);
        final count = exercise.sets.isEmpty ? 3 : exercise.sets.length;
        sets[bucket] = (sets[bucket] ?? 0) + count;
      }
    }

    const majors = <MuscleBucket>[
      MuscleBucket.chest,
      MuscleBucket.back,
      MuscleBucket.quads,
    ];
    final labels = <MuscleBucket, String>{
      MuscleBucket.chest: 'سینه',
      MuscleBucket.back: 'پشت',
      MuscleBucket.quads: 'چهارسر',
    };
    final issues = <String>[];
    for (final bucket in majors) {
      if ((sets[bucket] ?? 0) == 0) continue;
      final band = WorkoutScience.weeklySetBand(
        goal: goal,
        experience: experience,
        bucket: bucket,
      );
      final actual = sets[bucket] ?? 0;
      final name = labels[bucket]!;
      if (actual < band.min) {
        issues.add(
          'حجم هفتگی $name خیلی کم است ($actual ست؛ حداقل ${band.min}، '
          'هدف ${band.target}). ست مرکب را زیاد کن یا یک حرکت اضافه کن.',
        );
      } else if (actual > band.max) {
        issues.add(
          'حجم هفتگی $name خیلی زیاد است ($actual ست؛ سقف ${band.max}).',
        );
      }
    }

    final ham = sets[MuscleBucket.hamstrings] ?? 0;
    final glute = sets[MuscleBucket.glutes] ?? 0;
    final quad = sets[MuscleBucket.quads] ?? 0;
    if (quad >= 6 && (ham + glute) < (quad * 0.4).ceil()) {
      issues.add(
        'زنجیره خلفی نسبت به چهارسر کم است؛ لگ‌کرل یا هیپ‌تراست اضافه کن.',
      );
    }
    return issues;
  }
}
