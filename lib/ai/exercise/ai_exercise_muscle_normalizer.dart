/// Infers a reliable `main_muscle` key from the Persian/English exercise name.
///
/// Used to correct poisoned catalog tags (e.g. bench press stored as `triceps`)
/// without hardcoding full programs. Returns null when not confident.
abstract final class AiExerciseMuscleNormalizer {
  const AiExerciseMuscleNormalizer._();

  /// Canonical English keys aligned with `ai_exercises` live catalog.
  static String? inferMainMuscle(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return null;
    final n = name.toLowerCase();

    // --- Most specific compounds first ---
    if (_has(name, n, const ['پرس سینه', 'بالا سینه', 'بالاسینه', 'بنچ', 'bench press'])) {
      return 'chest';
    }
    if (_has(name, n, const ['قفسه سینه', 'کراس اور', 'کراس‌اور', 'کrossover', 'فلای سینه', 'پک دک'])) {
      return 'chest';
    }
    if (_has(name, n, const ['شنا سوئدی', 'شنای سوئدی', 'push.?up', 'push up'])) {
      return 'chest';
    }
    if (_has(name, n, const ['پول اور', 'پول‌اور', 'pullover'])) {
      return 'chest';
    }

    if (_has(name, n, const ['پرس سرشانه', 'آرنولد', 'overhead press', 'military press', 'ohp'])) {
      return 'shoulder_anterior';
    }
    if (_has(name, n, const ['نشر جانب', 'نشر از جانب', 'lateral raise'])) {
      return 'shoulder_lateral';
    }
    if (_has(name, n, const ['نشر پشت', 'فیس پول', 'فیس‌پول', 'face pull', 'rear delt'])) {
      return 'shoulder_posterior';
    }
    if (_has(name, n, const ['شراگ', 'کول هالتر', 'کول دمبل', 'shrug'])) {
      return 'traps';
    }

    if (_has(name, n, const ['جلو بازو', 'جلوبازو', 'bicep', 'curl']) &&
        !_has(name, n, const ['پشت بازو', 'پشت‌بازو', 'leg curl', 'همستر'])) {
      return 'biceps';
    }
    if (_has(name, n, const ['پشت بازو', 'پشت‌بازو', 'triceps', 'کرشر', 'اسکال', 'skull'])) {
      return 'triceps';
    }
    if (_has(name, n, const ['دیپ', 'dip']) &&
        !_has(name, n, const ['سینه', 'hip'])) {
      return 'triceps';
    }

    if (_has(name, n, const ['هیپ تراست', 'هیپ‌تراست', 'پل باسن', 'hip thrust', 'glute bridge'])) {
      return 'glutes';
    }

    if (_has(name, n, const ['پرس ساق', 'ساق پا', 'ساق ایستاده', 'ساق نشسته', 'ساق دونکی', 'calf'])) {
      return 'calves';
    }

    if (_has(name, n, const ['رومانیایی', 'پشت پا', 'همسترینگ', 'nordic', 'leg curl'])) {
      return 'hamstrings';
    }

    if (_has(name, n, const [
      'زیربغل',
      'بارفیکس',
      'لت پول',
      'لت‌پول',
      'پول دان',
      'پول‌دان',
      'رویینگ',
      'قایقی',
      'تی بار',
      'تی‌بار',
      'pulldown',
      'pull-up',
      'pull up',
      'chin',
      'row',
    ]) && !_has(name, n, const ['روئینگ', 'rowing', 'بایک'])) {
      return 'back_lat';
    }

    if (_has(name, n, const ['ددلیفت', 'deadlift']) &&
        !_has(name, n, const ['رومانیایی'])) {
      return 'lower_back';
    }

    if (_has(name, n, const [
      'اسکوات',
      'اسکات',
      'پرس پا',
      'جلو پا',
      'لانج',
      'لانگز',
      'هک اسکوات',
      'squat',
      'lunge',
      'leg press',
      'leg extension',
    ])) {
      return 'quads';
    }

    if (_has(name, n, const ['چرخش روسی', 'ابلیک', 'oblique', 'پهلو'])) {
      return 'obliques';
    }
    if (_has(name, n, const ['کرانچ', 'پلانک', 'زیرشکم', 'crunch', 'plank', 'leg raise'])) {
      return 'abs';
    }

    if (_has(name, n, const ['بورپی', 'برپی', 'فارمر', 'کلین', 'اسنچ', 'جرک', 'burpee'])) {
      return 'full_body';
    }

    return null;
  }

  /// Prefer inferred muscle when the stored tag conflicts or is empty.
  static String resolveMainMuscle({
    required String name,
    required String storedMainMuscle,
  }) {
    final inferred = inferMainMuscle(name);
    if (inferred == null) return storedMainMuscle;
    if (storedMainMuscle.trim().isEmpty) return inferred;
    if (!_compatible(storedMainMuscle, inferred)) return inferred;
    return storedMainMuscle.trim();
  }

  static bool _compatible(String stored, String inferred) {
    final s = stored.toLowerCase();
    final i = inferred.toLowerCase();
    if (s == i) return true;
    if (i.startsWith('shoulder') && (s.contains('shoulder') || s.contains('شانه'))) {
      return true;
    }
    if (i == 'chest' && (s.contains('chest') || s.contains('سینه'))) return true;
    if (i == 'back_lat' &&
        (s.contains('back') || s.contains('lat') || s.contains('زیربغل'))) {
      return true;
    }
    if (i == 'biceps' && (s.contains('bicep') || s.contains('جلو'))) return true;
    if (i == 'triceps' && (s.contains('tricep') || s.contains('پشت بازو'))) {
      return true;
    }
    if (i == 'quads' && (s.contains('quad') || s.contains('چهار'))) return true;
    if (i == 'hamstrings' && (s.contains('ham') || s.contains('پشت پا'))) {
      return true;
    }
    if (i == 'glutes' && (s.contains('glute') || s.contains('باسن'))) return true;
    if (i == 'calves' && (s.contains('calf') || s.contains('ساق'))) return true;
    if (i == 'abs' && (s.contains('abs') || s.contains('شکم') || s.contains('core'))) {
      return true;
    }
    if (i == 'obliques' && (s.contains('oblique') || s.contains('پهلو'))) {
      return true;
    }
    if (i == 'traps' && (s.contains('trap') || s.contains('کول'))) return true;
    if (i == 'lower_back' && (s.contains('lower') || s.contains('کمر'))) {
      return true;
    }
    if (i == 'full_body' && (s.contains('full') || s.contains('کل بدن'))) {
      return true;
    }
    return false;
  }

  static bool _has(String name, String lower, List<String> tokens) {
    for (final token in tokens) {
      if (token.contains('?') || token.contains('.')) {
        if (RegExp(token, caseSensitive: false).hasMatch(name) ||
            RegExp(token, caseSensitive: false).hasMatch(lower)) {
          return true;
        }
      } else if (name.contains(token) || lower.contains(token.toLowerCase())) {
        return true;
      }
    }
    return false;
  }
}
