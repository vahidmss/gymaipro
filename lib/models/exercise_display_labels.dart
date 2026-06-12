/// برچسب فارسی برای کلیدهای انگلیسی متا (نمایش در UI).
class ExerciseDisplayLabels {
  ExerciseDisplayLabels._();

  static const Map<String, String> mainMuscle = {
    'chest': 'سینه',
    'chest_upper': 'سینه بالایی',
    'chest_middle': 'سینه میانی',
    'chest_lower': 'سینه پایینی',
    'back': 'پشت',
    'back_lat': 'زیربغل',
    'back_upper': 'پشت بالا',
    'back_lower': 'پشت پایین',
    'lats': 'زیربغل',
    'lat': 'زیربغل',
    'back_trap': 'ذوزنقه',
    'traps': 'ذوزنقه',
    'lower_back': 'کمر',
    'shoulder': 'سرشانه',
    'shoulders': 'سرشانه',
    'shoulder_anterior': 'سرشانه قدامی',
    'shoulder_lateral': 'سرشانه جانبی',
    'shoulder_posterior': 'سرشانه خلفی',
    'triceps': 'پشت‌بازو',
    'biceps': 'جلوبازو',
    'forearms': 'ساعد',
    'arms': 'بازو',
    'arm': 'بازو',
    'quads': 'چهارسر',
    'quadriceps': 'چهارسر',
    'hamstrings': 'همسترینگ',
    'glutes': 'باسن',
    'glute': 'باسن',
    'calf': 'ساق پا',
    'calves': 'ساق پا',
    'legs': 'پا',
    'leg': 'پا',
    'abs': 'شکم',
    'abdominals': 'شکم',
    'core': 'میان‌تنه',
    'obliques': 'پهلو',
    'hips': 'لگن',
    'hip': 'لگن',
    'neck': 'گردن',
    'full_body': 'کل بدن',
    'fullbody': 'کل بدن',
    'whole_body': 'کل بدن',
    'upper_body': 'بالا تنه',
    'lower_body': 'پایین تنه',
    'cardio': 'کاردیو',
    'کل_بدن': 'کل بدن',
  };

  static const Map<String, String> difficulty = {
    'beginner': 'مبتدی',
    'intermediate': 'متوسط',
    'advanced': 'پیشرفته',
    'expert': 'حرفه‌ای',
  };

  static const Map<String, String> movementPattern = {
    'horizontal_push': 'فشار افقی',
    'horizontal_pull': 'کشش افقی',
    'vertical_push': 'فشار عمودی',
    'vertical_pull': 'کشش عمودی',
    'squat': 'اسکوات',
    'lunge': 'لانج',
    'elbow_extension': 'پشت‌بازو / باز کردن آرنج',
    'elbow_flexion': 'جلوبازو',
    'hip_hinge': 'هیپ هینج',
    'anti_rotation': 'ضد چرخش',
    'anti_extension': 'ضد اکستنشن',
    'isometric_hold': 'ایزومتریک',
    'horizontal_adduction': 'فلای سینه',
    'knee_dominant_press': 'پرس پا',
  };

  static const Map<String, String> bodyEngagement = {
    'compound': 'مرکب',
    'isolation': 'ایزوله',
  };

  static const Map<String, String> exerciseType = {
    'strength': 'قدرتی',
    'cardio': 'کاردیو',
    'flexibility': 'کششی',
    'balance': 'تعادل',
  };

  static const Map<String, String> equipment = {
    'barbell': 'هالتر',
    'dumbbell': 'دمبل',
    'cable': 'سیم‌کش',
    'machine': 'دستگاه',
    'machine_stack': 'دستگاه',
    'bodyweight': 'وزن بدن',
    'kettlebell': 'کتل‌بل',
    'band': 'کش مقاومتی',
    'bench': 'نیمکت',
  };

  static String muscle(String? raw) => _label(mainMuscle, raw, normalizeKey: true);

  static String equipmentLabel(String? raw) => _label(equipment, raw);

  static String difficultyLabel(String? raw) => _label(difficulty, raw);

  static String movement(String? raw) =>
      _label(movementPattern, raw, normalizeKey: true);

  static String engagement(String? raw) => _label(bodyEngagement, raw);

  static String type(String? raw) => _label(exerciseType, raw);

  /// چند عضله با «،» — هر قطعه جدا ترجمه می‌شود.
  static String musclesCsv(String? raw) {
    if (raw == null || raw.trim().isEmpty) return '';
    final parts = raw.split(RegExp('[,،]'));
    return parts
        .map((p) => muscle(p.trim()))
        .where((s) => s.isNotEmpty)
        .join('، ');
  }

  /// برچسب‌های یکتا برای فیلتر عضله در لیست تمرینات.
  static List<String> uniqueMuscleCategories(Iterable<String> rawMuscles) {
    final seen = <String>{};
    final out = <String>[];
    for (final raw in rawMuscles) {
      final label = muscle(raw);
      if (label.isEmpty) continue;
      if (seen.add(label)) out.add(label);
    }
    out.sort((a, b) => a.compareTo(b));
    return out;
  }

  static bool muscleMatchesFilter(
    String filterLabel, {
    required String mainMuscle,
    required String secondaryMuscles,
  }) {
    if (filterLabel.isEmpty) return true;
    if (muscle(mainMuscle) == filterLabel || mainMuscle == filterLabel) {
      return true;
    }
    for (final part in secondaryMuscles.split(RegExp('[,،]'))) {
      final p = part.trim();
      if (p.isEmpty) continue;
      if (muscle(p) == filterLabel || p == filterLabel) return true;
    }
    return false;
  }

  static bool fieldMatchesFilter(
    String filterValue,
    String rawValue,
    String Function(String?) labelFn,
  ) {
    if (filterValue.isEmpty) return true;
    return labelFn(rawValue) == filterValue || rawValue == filterValue;
  }

  static String? _normalizeKey(String raw) {
    final lower = raw.trim().toLowerCase();
    if (lower.isEmpty) return null;
    return lower
        .replaceAll(RegExp(r'[\s\-]+'), '_')
        .replaceAll(RegExp('_+'), '_');
  }

  static String _label(
    Map<String, String> map,
    String? raw, {
    bool normalizeKey = false,
  }) {
    if (raw == null) return '';
    final t = raw.trim();
    if (t.isEmpty) return '';
    if (map.containsKey(t)) return map[t]!;

    if (normalizeKey) {
      final key = _normalizeKey(t);
      if (key != null && map.containsKey(key)) return map[key]!;
    }

    if (t.contains(RegExp(r'[\u0600-\u06FF]'))) return t;

    final fallbackKey = normalizeKey ? _normalizeKey(t) : t;
    if (fallbackKey != null && map.containsKey(fallbackKey)) {
      return map[fallbackKey]!;
    }

    return (fallbackKey ?? t).replaceAll('_', ' ');
  }
}
