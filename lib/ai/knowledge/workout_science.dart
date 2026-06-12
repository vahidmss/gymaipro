/// اصول علمی مورد استفاده در موتور برنامه‌نویسی محلی.
/// مراجع: ACSM Guidelines, Schoenfeld (حجم هفتگی)، NSCA Basics.
library;

/// هدف تمرینی استاندارد
enum TrainingGoal {
  hypertrophy,
  strength,
  fatLoss,
  endurance,
  general,
}

/// گروه عضلانی برای چیدمان برنامه
enum MuscleBucket {
  chest,
  back,
  shoulders,
  quads,
  hamstrings,
  glutes,
  biceps,
  triceps,
  core,
  calves,
  fullBody,
  cardio,
  other,
}

class WorkoutScience {
  WorkoutScience._();

  /// حجم هفتگی پیشنهادی به‌ازای هر گروه بزرگ (ست × نزدیک به failure)
  static bool isBeginnerExperience(String experience) {
    if (experience.contains('نیمه')) return false;
    return experience.contains('مبتدی');
  }

  static bool isAdvancedExperience(String experience) {
    return experience.contains('پیشرفته') || experience.contains('حرفه');
  }

  static Set<MuscleBucket> priorityBucketsFromText(String text) {
    final t = text.toLowerCase();
    final out = <MuscleBucket>{};
    if (t.contains('سینه') || t.contains('chest')) out.add(MuscleBucket.chest);
    if (t.contains('پشت') || t.contains('back')) out.add(MuscleBucket.back);
    if (t.contains('شانه') || t.contains('shoulder')) {
      out.add(MuscleBucket.shoulders);
    }
    if (t.contains('پا') || t.contains('ران') || t.contains('leg')) {
      out.add(MuscleBucket.quads);
      out.add(MuscleBucket.glutes);
    }
    if (t.contains('بازو') || t.contains('arm')) {
      out.add(MuscleBucket.biceps);
      out.add(MuscleBucket.triceps);
    }
    if (t.contains('شکم') || t.contains('core')) out.add(MuscleBucket.core);
    return out;
  }

  static int weeklySetsForGoal(TrainingGoal goal, String experience) {
    final isBeginner = isBeginnerExperience(experience);
    final isAdvanced = isAdvancedExperience(experience);
    switch (goal) {
      case TrainingGoal.strength:
        if (isBeginner) return 8;
        if (isAdvanced) return 14;
        return 12;
      case TrainingGoal.hypertrophy:
        if (isBeginner) return 10;
        if (isAdvanced) return 18;
        return 14;
      case TrainingGoal.fatLoss:
        return isBeginner ? 10 : 14;
      case TrainingGoal.endurance:
        return isBeginner ? 8 : 12;
      case TrainingGoal.general:
        return isBeginner ? 8 : 12;
    }
  }

  static int exercisesPerSession(String sessionVolumeHint) {
    if (sessionVolumeHint.contains('۵-۶') || sessionVolumeHint.contains('5-6')) {
      return 6;
    }
    if (sessionVolumeHint.contains('۴-۵') || sessionVolumeHint.contains('4-5')) {
      return 5;
    }
    return 4;
  }

  static int setCountForExercise(
    TrainingGoal goal,
    String experience,
    bool isCompound,
  ) {
    final isBeginner = isBeginnerExperience(experience);
    if (goal == TrainingGoal.strength) {
      return isCompound ? (isBeginner ? 4 : 5) : 3;
    }
    if (goal == TrainingGoal.fatLoss) {
      return isBeginner ? 3 : 3;
    }
    if (goal == TrainingGoal.endurance) {
      return 3;
    }
    return isCompound ? (isBeginner ? 3 : 4) : 3;
  }

  /// تکرار به‌صورت میانه (برای ExerciseSet.reps)
  static int repsForGoal(TrainingGoal goal, String intensity, int setIndex) {
    if (goal == TrainingGoal.strength) {
      if (intensity == 'سنگین') return setIndex == 0 ? 5 : 4;
      return setIndex == 0 ? 6 : 5;
    }
    if (goal == TrainingGoal.fatLoss) {
      return intensity == 'سبک' ? 15 : 12;
    }
    if (goal == TrainingGoal.endurance) {
      return 15 + (setIndex % 3);
    }
    // hypertrophy / general
    if (intensity == 'سنگین') return setIndex == 0 ? 8 : 6;
    if (intensity == 'سبک') return setIndex == 0 ? 15 : 12;
    return setIndex == 0 ? 12 : 10;
  }

  static TrainingGoal goalFromProfile(List<String> goals, String profileText) {
    final blob = '${goals.join(' ')} $profileText'.toLowerCase();
    if (blob.contains('قدرت') || blob.contains('power')) {
      return TrainingGoal.strength;
    }
    if (blob.contains('چربی') ||
        blob.contains('لاغر') ||
        blob.contains('کاهش وزن')) {
      return TrainingGoal.fatLoss;
    }
    if (blob.contains('استقامت') || blob.contains('کاردیو')) {
      return TrainingGoal.endurance;
    }
    if (blob.contains('حجم') ||
        blob.contains('عضله') ||
        blob.contains('هایپرتروفی')) {
      return TrainingGoal.hypertrophy;
    }
    return TrainingGoal.general;
  }

  static MuscleBucket muscleBucket(String mainMuscle) {
    final m = mainMuscle.trim().toLowerCase();
    if (m.contains('سینه') || m.contains('chest')) return MuscleBucket.chest;
    if (m.contains('پشت') ||
        m.contains('کول') ||
        m.contains('back') ||
        m.contains('لت')) {
      return MuscleBucket.back;
    }
    if (m.contains('شانه') || m.contains('دلتو') || m.contains('shoulder')) {
      return MuscleBucket.shoulders;
    }
    if (m.contains('چهار') ||
        m.contains('ران') ||
        m.contains('quad') ||
        m.contains('پا') && !m.contains('پشت')) {
      return MuscleBucket.quads;
    }
    if (m.contains('همستر') || m.contains('hamstring') || m.contains('پشت پا')) {
      return MuscleBucket.hamstrings;
    }
    if (m.contains('گلوت') || m.contains('باسن')) return MuscleBucket.glutes;
    if (m.contains('دوسر') || m.contains('بایسپ') || m.contains('bicep')) {
      return MuscleBucket.biceps;
    }
    if (m.contains('سه‌سر') ||
        m.contains('سه سر') ||
        m.contains('tricep')) {
      return MuscleBucket.triceps;
    }
    if (m.contains('شکم') ||
        m.contains('کرانچ') ||
        m.contains('پهلو') ||
        m.contains('core') ||
        m.contains('شكم')) {
      return MuscleBucket.core;
    }
    if (m.contains('ساق') || m.contains('calf')) return MuscleBucket.calves;
    if (m.contains('کاردیو') ||
        m.contains('هوازی') ||
        m.contains('cardio')) {
      return MuscleBucket.cardio;
    }
    if (m.contains('تمام') || m.contains('full')) return MuscleBucket.fullBody;
    return MuscleBucket.other;
  }

  /// برچسب‌های روز برای هر تعداد جلسه در هفته
  static List<String> dayLabels(int daysPerWeek) {
    final d = daysPerWeek.clamp(2, 6);
    const names2 = ['روز الف — تمام‌بدن', 'روز ب — تمام‌بدن'];
    const names3 = ['روز ۱ — فشار', 'روز ۲ — کشش', 'روز ۳ — پا'];
    const names4 = [
      'روز ۱ — بالاتنه',
      'روز ۲ — پایین‌تنه',
      'روز ۳ — بالاتنه',
      'روز ۴ — پایین‌تنه',
    ];
    const names5 = [
      'روز ۱ — سینه/شانه/بازو',
      'روز ۲ — پشت',
      'روز ۳ — پا',
      'روز ۴ — بالاتنه',
      'روز ۵ — پایین‌تنه',
    ];
    const names6 = [
      'روز ۱ — فشار',
      'روز ۲ — کشش',
      'روز ۳ — پا',
      'روز ۴ — فشار',
      'روز ۵ — کشش',
      'روز ۶ — پا',
    ];
    switch (d) {
      case 2:
        return names2;
      case 3:
        return names3;
      case 4:
        return names4;
      case 5:
        return names5;
      default:
        return names6;
    }
  }

  /// گروه‌های عضلانی هدف هر روز
  static List<Set<MuscleBucket>> bucketsPerDay(int daysPerWeek) {
    final d = daysPerWeek.clamp(2, 6);
    switch (d) {
      case 2:
        return [
          {
            MuscleBucket.chest,
            MuscleBucket.back,
            MuscleBucket.quads,
            MuscleBucket.shoulders,
            MuscleBucket.core,
          },
          {
            MuscleBucket.back,
            MuscleBucket.hamstrings,
            MuscleBucket.glutes,
            MuscleBucket.biceps,
            MuscleBucket.triceps,
            MuscleBucket.core,
          },
        ];
      case 3:
        return [
          {MuscleBucket.chest, MuscleBucket.shoulders, MuscleBucket.triceps},
          {MuscleBucket.back, MuscleBucket.biceps, MuscleBucket.core},
          {
            MuscleBucket.quads,
            MuscleBucket.hamstrings,
            MuscleBucket.glutes,
            MuscleBucket.calves,
          },
        ];
      case 4:
        return [
          {MuscleBucket.chest, MuscleBucket.back, MuscleBucket.shoulders},
          {MuscleBucket.quads, MuscleBucket.hamstrings, MuscleBucket.glutes},
          {MuscleBucket.chest, MuscleBucket.back, MuscleBucket.biceps},
          {MuscleBucket.quads, MuscleBucket.glutes, MuscleBucket.calves},
        ];
      case 5:
        return [
          {MuscleBucket.chest, MuscleBucket.shoulders, MuscleBucket.triceps},
          {MuscleBucket.back, MuscleBucket.biceps},
          {MuscleBucket.quads, MuscleBucket.hamstrings, MuscleBucket.glutes},
          {MuscleBucket.chest, MuscleBucket.back},
          {MuscleBucket.hamstrings, MuscleBucket.glutes, MuscleBucket.calves},
        ];
      default:
        return [
          {MuscleBucket.chest, MuscleBucket.shoulders, MuscleBucket.triceps},
          {MuscleBucket.back, MuscleBucket.biceps},
          {MuscleBucket.quads, MuscleBucket.hamstrings, MuscleBucket.glutes},
          {MuscleBucket.chest, MuscleBucket.shoulders, MuscleBucket.triceps},
          {MuscleBucket.back, MuscleBucket.biceps},
          {MuscleBucket.quads, MuscleBucket.hamstrings, MuscleBucket.glutes},
        ];
    }
  }

  static bool isCompoundExercise(String name, String type) {
    final n = name.toLowerCase();
    if (type.contains('کاردیو') || type.contains('هوازی')) return false;
    const compounds = [
      'اسکوات',
      'ددلیفت',
      'پرس',
      'زیر بغل',
      'لانج',
      'چین',
      'پول',
      'row',
      'squat',
      'deadlift',
      'bench',
      'press',
    ];
    return compounds.any(n.contains);
  }

  static String restGuidance(TrainingGoal goal) {
    switch (goal) {
      case TrainingGoal.strength:
        return 'استراحت بین ست‌های اصلی: ۲–۳ دقیقه.';
      case TrainingGoal.fatLoss:
        return 'استراحت بین ست‌ها: ۴۵–۹۰ ثانیه؛ ضربان را بالا نگه دارید.';
      case TrainingGoal.endurance:
        return 'استراحت کوتاه (۳۰–۶۰ ثانیه) یا سوپرست سبک.';
      default:
        return 'استراحت بین ست‌ها: ۶۰–۹۰ ثانیه (حرکت‌های بزرگ تا ۱۲۰ ثانیه).';
    }
  }
}
