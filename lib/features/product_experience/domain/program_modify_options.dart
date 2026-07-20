import 'package:gymaipro/ai/workout_modify/models/workout_modify_enums.dart';

/// User-facing modify goals shown as selective chips.
enum ProgramModifyGoal {
  replaceExercise,
  removeExercise,
  reduceVolume,
  increaseVolume,
  easierSession,
  harderSession,
  shorterSession,
  homeVersion,
  injuryAdapt,
  tiredAdapt,
}

extension ProgramModifyGoalX on ProgramModifyGoal {
  String get label => switch (this) {
        ProgramModifyGoal.replaceExercise => 'عوض کردن یک حرکت',
        ProgramModifyGoal.removeExercise => 'حذف یک حرکت',
        ProgramModifyGoal.reduceVolume => 'کم کردن ست',
        ProgramModifyGoal.increaseVolume => 'زیاد کردن ست',
        ProgramModifyGoal.easierSession => 'سبک‌تر کردن جلسه',
        ProgramModifyGoal.harderSession => 'سنگین‌تر کردن جلسه',
        ProgramModifyGoal.shorterSession => 'کوتاه‌تر کردن جلسه',
        ProgramModifyGoal.homeVersion => 'نسخه خانگی',
        ProgramModifyGoal.injuryAdapt => 'محدودیت / آسیب',
        ProgramModifyGoal.tiredAdapt => 'خسته‌ام؛ جلسه را سبک کن',
      };

  String get hint => switch (this) {
        ProgramModifyGoal.replaceExercise =>
          'یک حرکت را انتخاب کن و بگو چرا. مربی جایگزین پیشنهاد می‌دهد.',
        ProgramModifyGoal.removeExercise =>
          'کدام حرکت از این جلسه حذف شود؟',
        ProgramModifyGoal.reduceVolume =>
          'ست‌های همان حرکت کمتر می‌شود.',
        ProgramModifyGoal.increaseVolume =>
          'ست‌های همان حرکت کمی بیشتر می‌شود.',
        ProgramModifyGoal.easierSession =>
          'کل جلسه سبک‌تر می‌شود؛ حرکت‌های اصلی می‌مانند.',
        ProgramModifyGoal.harderSession =>
          'اگر منطقی باشد، جلسه کمی سنگین‌تر می‌شود.',
        ProgramModifyGoal.shorterSession =>
          'جلسه کوتاه‌تر می‌شود بدون حذف تمرکز اصلی.',
        ProgramModifyGoal.homeVersion =>
          'فقط همان روز را خانگی می‌کنم: هالتر/دستگاه/سیم‌کش → دمبل، کش یا وزن بدن.',
        ProgramModifyGoal.injuryAdapt =>
          'بگو کدام ناحیه؛ حرکت‌های پرریسک سبک یا عوض می‌شوند.',
        ProgramModifyGoal.tiredAdapt =>
          'بگو چرا خسته‌ای؛ فقط ست‌ها کم می‌شود و حرکت‌ها همان می‌مانند.',
      };

  bool get needsExercise => switch (this) {
        ProgramModifyGoal.replaceExercise ||
        ProgramModifyGoal.removeExercise ||
        ProgramModifyGoal.reduceVolume ||
        ProgramModifyGoal.increaseVolume => true,
        _ => false,
      };

  bool get needsReason => switch (this) {
        ProgramModifyGoal.replaceExercise ||
        ProgramModifyGoal.removeExercise ||
        ProgramModifyGoal.injuryAdapt ||
        ProgramModifyGoal.tiredAdapt => true,
        _ => false,
      };

  List<WorkoutModificationType> get engineTypes => switch (this) {
        ProgramModifyGoal.replaceExercise => <WorkoutModificationType>[
            WorkoutModificationType.replaceExercise,
          ],
        ProgramModifyGoal.removeExercise => <WorkoutModificationType>[
            WorkoutModificationType.removeExercise,
          ],
        ProgramModifyGoal.reduceVolume => <WorkoutModificationType>[
            WorkoutModificationType.reduceVolume,
          ],
        ProgramModifyGoal.increaseVolume => <WorkoutModificationType>[
            WorkoutModificationType.increaseVolume,
          ],
        ProgramModifyGoal.easierSession => <WorkoutModificationType>[
            WorkoutModificationType.reduceIntensity,
            WorkoutModificationType.reduceVolume,
          ],
        ProgramModifyGoal.harderSession => <WorkoutModificationType>[
            WorkoutModificationType.increaseIntensity,
            WorkoutModificationType.increaseVolume,
          ],
        ProgramModifyGoal.shorterSession => <WorkoutModificationType>[
            WorkoutModificationType.shortenSession,
          ],
        ProgramModifyGoal.homeVersion => <WorkoutModificationType>[
            WorkoutModificationType.homeVersion,
          ],
        ProgramModifyGoal.injuryAdapt => <WorkoutModificationType>[
            WorkoutModificationType.injuryAdaptation,
          ],
        ProgramModifyGoal.tiredAdapt => <WorkoutModificationType>[
            WorkoutModificationType.recoveryAdaptation,
          ],
      };

  String buildRequestText({
    String? exerciseName,
    String? reasonLabel,
    String? sessionDay,
  }) {
    final day = (sessionDay != null && sessionDay.isNotEmpty)
        ? 'در $sessionDay'
        : '';
    final exercise = (exerciseName != null && exerciseName.isNotEmpty)
        ? 'حرکت «$exerciseName»'
        : 'جلسه';
    final reason = (reasonLabel != null && reasonLabel.isNotEmpty)
        ? '؛ دلیل: $reasonLabel'
        : '';
    return switch (this) {
      ProgramModifyGoal.replaceExercise =>
        '$exercise را $day نمی‌توانم بزنم؛ جایگزین مناسب بده و روی برنامه اعمال کن$reason',
      ProgramModifyGoal.removeExercise =>
        '$exercise را $day از برنامه حذف کن$reason',
      ProgramModifyGoal.reduceVolume =>
        'حجم/ست‌های $exercise را $day کم کن$reason',
      ProgramModifyGoal.increaseVolume =>
        'حجم/ست‌های $exercise را $day کمی زیاد کن$reason',
      ProgramModifyGoal.easierSession =>
        'جلسه $day را سبک‌تر کن$reason',
      ProgramModifyGoal.harderSession =>
        'جلسه $day را کمی سنگین‌تر کن$reason',
      ProgramModifyGoal.shorterSession =>
        'جلسه $day را کوتاه‌تر کن$reason',
      ProgramModifyGoal.homeVersion =>
        'نسخه خانگی برای جلسه $day بساز$reason',
      ProgramModifyGoal.injuryAdapt =>
        'برنامه $day را برای آسیب تطبیق بده$reason',
      ProgramModifyGoal.tiredAdapt =>
        'به‌خاطر خستگی/ریکاوری پایین، جلسه $day را سبک‌تر کن$reason',
    };
  }
}

class ProgramModifyReasonOption {
  const ProgramModifyReasonOption({
    required this.id,
    required this.label,
  });

  final String id;
  final String label;
}

abstract final class ProgramModifyOptions {
  static const List<ProgramModifyGoal> goals = ProgramModifyGoal.values;

  static const List<ProgramModifyReasonOption> replaceReasons =
      <ProgramModifyReasonOption>[
        ProgramModifyReasonOption(id: 'cant_do', label: 'نمی‌توانم انجام دهم'),
        ProgramModifyReasonOption(id: 'pain', label: 'درد / ناراحتی'),
        ProgramModifyReasonOption(id: 'no_equipment', label: 'تجهیزات ندارم'),
        ProgramModifyReasonOption(id: 'too_hard', label: 'خیلی سخت است'),
        ProgramModifyReasonOption(id: 'boring', label: 'دوست ندارم / خسته‌کننده'),
      ];

  static const List<ProgramModifyReasonOption> injuryReasons =
      <ProgramModifyReasonOption>[
        ProgramModifyReasonOption(id: 'shoulder', label: 'شانه'),
        ProgramModifyReasonOption(id: 'knee', label: 'زانو'),
        ProgramModifyReasonOption(id: 'back', label: 'کمر'),
        ProgramModifyReasonOption(id: 'wrist', label: 'مچ'),
        ProgramModifyReasonOption(id: 'elbow', label: 'آرنج'),
        ProgramModifyReasonOption(id: 'other', label: 'سایر'),
      ];

  static const List<ProgramModifyReasonOption> tiredReasons =
      <ProgramModifyReasonOption>[
        ProgramModifyReasonOption(id: 'sleep', label: 'خواب کم'),
        ProgramModifyReasonOption(id: 'sore', label: 'کوفتگی عضلانی'),
        ProgramModifyReasonOption(id: 'busy', label: 'روز شلوغ'),
        ProgramModifyReasonOption(id: 'low_energy', label: 'انرژی پایین'),
      ];

  static const List<ProgramModifyReasonOption> removeReasons =
      <ProgramModifyReasonOption>[
        ProgramModifyReasonOption(id: 'pain', label: 'درد / ناراحتی'),
        ProgramModifyReasonOption(id: 'cant_do', label: 'نمی‌توانم انجام دهم'),
        ProgramModifyReasonOption(id: 'no_equipment', label: 'تجهیزات ندارم'),
        ProgramModifyReasonOption(id: 'too_hard', label: 'خیلی سخت است'),
        ProgramModifyReasonOption(id: 'boring', label: 'دوست ندارم / حوصله ندارم'),
      ];

  static List<ProgramModifyReasonOption> reasonsFor(ProgramModifyGoal goal) {
    return switch (goal) {
      ProgramModifyGoal.replaceExercise => replaceReasons,
      ProgramModifyGoal.removeExercise => removeReasons,
      ProgramModifyGoal.injuryAdapt => injuryReasons,
      ProgramModifyGoal.tiredAdapt => tiredReasons,
      _ => const <ProgramModifyReasonOption>[],
    };
  }
}

class ProgramModifyExerciseOption {
  const ProgramModifyExerciseOption({
    required this.catalogExerciseId,
    required this.name,
    this.meta,
  });

  final int catalogExerciseId;
  final String name;
  final String? meta;
}

class ProgramModifySessionOption {
  const ProgramModifySessionOption({
    required this.day,
    required this.exercises,
  });

  final String day;
  final List<ProgramModifyExerciseOption> exercises;
}

class ProgramModifyContext {
  const ProgramModifyContext({
    required this.programId,
    required this.programName,
    required this.sessions,
    this.selectedDay,
  });

  final String programId;
  final String programName;
  final List<ProgramModifySessionOption> sessions;
  final String? selectedDay;

  ProgramModifySessionOption? sessionFor(String? day) {
    if (day == null || day.isEmpty) {
      return sessions.isEmpty ? null : sessions.first;
    }
    for (final session in sessions) {
      if (session.day == day) return session;
    }
    return sessions.isEmpty ? null : sessions.first;
  }
}
