import 'package:gymaipro/ai/models/exercise_metadata_ai_models.dart';
import 'package:gymaipro/models/exercise_display_labels.dart';
import 'package:gymaipro/models/muscle_targets.dart';

/// تبدیل خروجی آزاد AI / کاتالوگ فارسی به کلیدهای استاندارد اپ.
///
/// هدف: هر چیزی که ذخیره یا در UI دستی نشان داده می‌شود
/// دقیقاً از واژه‌نامهٔ مجاز اپ باشد.
abstract final class ExerciseMetaNormalizer {
  const ExerciseMetaNormalizer._();

  /// الگوهای حرکت مجاز (کلید انگلیسی canonical).
  static const List<String> movementPatterns = [
    'horizontal_push',
    'horizontal_pull',
    'vertical_push',
    'vertical_pull',
    'squat',
    'lunge',
    'hip_hinge',
    'elbow_extension',
    'elbow_flexion',
    'shoulder_abduction',
    'shoulder_adduction',
    'shoulder_external_rotation',
    'shoulder_internal_rotation',
    'hip_abduction',
    'hip_adduction',
    'hip_extension',
    'anti_rotation',
    'anti_extension',
    'isometric_hold',
    'horizontal_adduction',
    'knee_dominant_press',
    'spinal_flexion',
    'spinal_extension',
    'rotation',
    'lateral_flexion',
    'carry',
    'gait',
    'cardio',
    'compound',
  ];

  static const List<String> bodyEngagements = ['compound', 'isolation'];
  static const List<String> mechanicsTypes = ['compound', 'isolation'];
  static const List<String> forceTypes = ['push', 'pull', 'static', 'dynamic'];

  static const List<String> mainMuscles = [
    'سینه',
    'پشت',
    'شانه',
    'پا',
    'بازو',
    'شکم',
    'سرینی',
    'ساعد',
    'کاردیو',
    'کل بدن',
  ];

  /// Alias → کلید canonical (انگلیسی + فارسی کاتالوگ).
  static const Map<String, String> _movementAliases = {
    // English common free-form
    'shoulder_abduction': 'shoulder_abduction',
    'shoulder_abduction_lateral_raise': 'shoulder_abduction',
    'lateral_raise': 'shoulder_abduction',
    'lateral_raises': 'shoulder_abduction',
    'side_raise': 'shoulder_abduction',
    'side_lateral_raise': 'shoulder_abduction',
    'abduction': 'shoulder_abduction',
    'shoulder_adduction': 'shoulder_adduction',
    'shoulder_external_rotation': 'shoulder_external_rotation',
    'external_rotation': 'shoulder_external_rotation',
    'shoulder_internal_rotation': 'shoulder_internal_rotation',
    'internal_rotation': 'shoulder_internal_rotation',
    'hip_abduction': 'hip_abduction',
    'hip_adduction': 'hip_adduction',
    'hip_extension': 'hip_extension',
    'glute_kickback': 'hip_extension',
    'kickback': 'hip_extension',
    'kick': 'hip_extension',
    'hinge': 'hip_hinge',
    'deadlift': 'hip_hinge',
    'rdl': 'hip_hinge',
    'romanian_deadlift': 'hip_hinge',
    'press': 'horizontal_push',
    'bench_press': 'horizontal_push',
    'chest_press': 'horizontal_push',
    'push_up': 'horizontal_push',
    'pushup': 'horizontal_push',
    'overhead_press': 'vertical_push',
    'shoulder_press': 'vertical_push',
    'military_press': 'vertical_push',
    'pull_up': 'vertical_pull',
    'pullup': 'vertical_pull',
    'chin_up': 'vertical_pull',
    'lat_pulldown': 'vertical_pull',
    'pulldown': 'vertical_pull',
    'row': 'horizontal_pull',
    'barbell_row': 'horizontal_pull',
    'seated_row': 'horizontal_pull',
    'fly': 'horizontal_adduction',
    'flye': 'horizontal_adduction',
    'chest_fly': 'horizontal_adduction',
    'pec_deck': 'horizontal_adduction',
    'curl': 'elbow_flexion',
    'bicep_curl': 'elbow_flexion',
    'biceps_curl': 'elbow_flexion',
    'extension': 'elbow_extension',
    'tricep_extension': 'elbow_extension',
    'triceps_extension': 'elbow_extension',
    'pushdown': 'elbow_extension',
    'leg_press': 'knee_dominant_press',
    'crunch': 'spinal_flexion',
    'sit_up': 'spinal_flexion',
    'back_extension': 'spinal_extension',
    'hyperextension': 'spinal_extension',
    'plank': 'isometric_hold',
    'hold': 'isometric_hold',
    'isometric': 'isometric_hold',
    'run': 'cardio',
    'running': 'cardio',
    'bike': 'cardio',
    'cycling': 'cardio',
    'aerobic': 'cardio',
    'walk': 'gait',
    'walking': 'gait',
    'farmer_carry': 'carry',
    'farmers_walk': 'carry',

    // Persian catalog / UI
    'فشار_افقی': 'horizontal_push',
    'فشار_عمودی': 'vertical_push',
    'کشش_افقی': 'horizontal_pull',
    'کشش_عمودی': 'vertical_pull',
    'اسکوات': 'squat',
    'لانج': 'lunge',
    'هیپ_هینج': 'hip_hinge',
    'هینج': 'hip_hinge',
    'لگد': 'hip_extension',
    'فلای': 'horizontal_adduction',
    'فلای_سینه': 'horizontal_adduction',
    'هوازی': 'cardio',
    'کاردیو': 'cardio',
    'حمل': 'carry',
    'چرخش': 'rotation',
    'خم_جانبی': 'lateral_flexion',
    'ایزومتریک': 'isometric_hold',
    'پرس_پا': 'knee_dominant_press',
    'مرکب': 'compound',
    'فانکشنال': 'compound',
    'نشر_جانب': 'shoulder_abduction',
    'نشر_جانبی': 'shoulder_abduction',
    'بالاآوردن_جانب': 'shoulder_abduction',
  };

  static const Map<String, String> _engagementAliases = {
    'compound': 'compound',
    'isolation': 'isolation',
    'isolat': 'isolation',
    'مرکب': 'compound',
    'ایزوله': 'isolation',
    'ایزوله_سازی': 'isolation',
    'تک_مفصلی': 'isolation',
    'چند_مفصلی': 'compound',
    'multi_joint': 'compound',
    'single_joint': 'isolation',
  };

  static const Map<String, String> _mechanicsAliases = {
    'compound': 'compound',
    'isolation': 'isolation',
    'مرکب': 'compound',
    'ایزوله': 'isolation',
    'چندمفصلی': 'compound',
    'تک_مفصلی': 'isolation',
    'تکمفصلی': 'isolation',
    'چند_مفصلی': 'compound',
  };

  static const Map<String, String> _forceAliases = {
    'push': 'push',
    'pull': 'pull',
    'static': 'static',
    'dynamic': 'dynamic',
    'هل_دادن': 'push',
    'هل': 'push',
    'فشار': 'push',
    'کشیدن': 'pull',
    'کشش': 'pull',
    'ایستا': 'static',
    'پویا': 'dynamic',
    'press': 'push',
    'row': 'pull',
  };

  static const Map<String, String> _mainMuscleAliases = {
    'سینه': 'سینه',
    'chest': 'سینه',
    'pec': 'سینه',
    'پشت': 'پشت',
    'back': 'پشت',
    'lat': 'پشت',
    'شانه': 'شانه',
    'سرشانه': 'شانه',
    'shoulder': 'شانه',
    'deltoid': 'شانه',
    'پا': 'پا',
    'leg': 'پا',
    'quad': 'پا',
    'بازو': 'بازو',
    'arm': 'بازو',
    'bicep': 'بازو',
    'tricep': 'بازو',
    'شکم': 'شکم',
    'abs': 'شکم',
    'core': 'شکم',
    'سرینی': 'سرینی',
    'باسن': 'سرینی',
    'glute': 'سرینی',
    'ساعد': 'ساعد',
    'forearm': 'ساعد',
    'کاردیو': 'کاردیو',
    'cardio': 'کاردیو',
    'کل_بدن': 'کل بدن',
    'full_body': 'کل بدن',
    'fullbody': 'کل بدن',
  };

  static String normalizeKey(String raw) {
    var s = raw.trim().toLowerCase();
    if (s.isEmpty) return '';
    s = s
        .replaceAll('ي', 'ی')
        .replaceAll('ك', 'ک')
        .replaceAll('ة', 'ه')
        .replaceAll('\u200c', ' ');
    s = s.replaceAll(RegExp(r'[\s\-/\\]+'), '_');
    s = s.replaceAll(RegExp(r'_+'), '_');
    return s.replaceAll(RegExp(r'^_|_$'), '');
  }

  static String? _aliasLookup(String raw, Map<String, String> aliases) {
    final key = normalizeKey(raw);
    if (key.isEmpty) return null;
    final exact = aliases[key];
    if (exact != null) return exact;

    // contains match — طولانی‌ترین کلید اول
    final keys = aliases.keys.toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    for (final k in keys) {
      if (k.length < 3) continue;
      if (key.contains(k) || k.contains(key)) return aliases[k];
    }
    return null;
  }

  static String movementPattern(String? raw, {String fallback = 'compound'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final key = normalizeKey(raw);
    if (movementPatterns.contains(key)) return key;
    final mapped = _aliasLookup(raw, _movementAliases);
    if (mapped != null && movementPatterns.contains(mapped)) return mapped;

    // match against display labels (Persian)
    for (final entry in ExerciseDisplayLabels.movementPattern.entries) {
      if (normalizeKey(entry.value) == key) {
        final canon = entry.key == 'hinge' ? 'hip_hinge' : entry.key;
        if (movementPatterns.contains(canon)) return canon;
      }
    }

    for (final allowed in movementPatterns) {
      if (key.contains(allowed) || allowed.contains(key)) return allowed;
    }
    return fallback;
  }

  static String bodyEngagement(String? raw, {String fallback = 'compound'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final key = normalizeKey(raw);
    if (bodyEngagements.contains(key)) return key;
    return _aliasLookup(raw, _engagementAliases) ?? fallback;
  }

  static String mechanicsType(String? raw, {String? engagementFallback}) {
    final fb = engagementFallback != null &&
            bodyEngagements.contains(engagementFallback)
        ? engagementFallback
        : 'compound';
    if (raw == null || raw.trim().isEmpty) return fb;
    final key = normalizeKey(raw);
    if (mechanicsTypes.contains(key)) return key;
    return _aliasLookup(raw, _mechanicsAliases) ?? fb;
  }

  static String forceType(String? raw, {String fallback = 'push'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final key = normalizeKey(raw);
    if (forceTypes.contains(key)) return key;
    return _aliasLookup(raw, _forceAliases) ?? fallback;
  }

  static String mainMuscle(String? raw, {String fallback = 'کل بدن'}) {
    if (raw == null || raw.trim().isEmpty) return fallback;
    final t = raw.trim();
    if (mainMuscles.contains(t)) return t;
    final mapped = _aliasLookup(raw, _mainMuscleAliases);
    if (mapped != null) return mapped;
    // از روی برچسب عضله heatmap
    final heatKey = MuscleTargets.keyForTag(t);
    if (heatKey != null) {
      return _groupForHeatKey(heatKey) ?? fallback;
    }
    return fallback;
  }

  static String? _groupForHeatKey(String key) {
    const map = <String, String>{
      'chest_upper': 'سینه',
      'chest_middle': 'سینه',
      'chest_lower': 'سینه',
      'shoulder_anterior': 'شانه',
      'shoulder_lateral': 'شانه',
      'shoulder_posterior': 'شانه',
      'triceps': 'بازو',
      'biceps': 'بازو',
      'forearms': 'ساعد',
      'back_lat': 'پشت',
      'back_trap': 'پشت',
      'lower_back': 'پشت',
      'quads': 'پا',
      'hamstrings': 'پا',
      'glutes': 'سرینی',
      'calf': 'پا',
      'abs': 'شکم',
    };
    return map[key];
  }

  /// نرمال‌سازی کامل پروفایل قبل از اعمال در UI / ذخیره.
  static GeneratedMuscleProfile normalizeProfile(GeneratedMuscleProfile meta) {
    final engagement = bodyEngagement(meta.bodyEngagement);
    final pattern = movementPattern(meta.movementPattern);
    final mechanics = mechanicsType(
      meta.mechanicsType,
      engagementFallback: engagement,
    );
    final force = forceType(meta.forceType);
    final main = mainMuscle(meta.mainMuscle);

    final met = (meta.met ?? 4.5).clamp(1.5, 16.0).toDouble();
    final rpe = (meta.typicalRpe ?? 7.0).clamp(4.0, 10.0).toDouble();
    final cal = (meta.caloriesPer1000kg ?? 30).clamp(5, 200);

    // عضلات فرعی را به برچسب فارسی استاندارد نزدیک کن
    final secondary = meta.secondaryMuscles
        .split(RegExp('[,،]'))
        .map((p) => p.trim())
        .where((p) => p.isNotEmpty)
        .map((p) => ExerciseDisplayLabels.muscle(p))
        .where((p) => p.isNotEmpty)
        .join('، ');

    return GeneratedMuscleProfile(
      mainMuscle: main,
      secondaryMuscles: secondary.isNotEmpty ? secondary : meta.secondaryMuscles,
      muscleTargets: Map<String, int>.from(meta.muscleTargets),
      met: double.parse(met.toStringAsFixed(1)),
      typicalRpe: double.parse(rpe.toStringAsFixed(1)),
      movementPattern: pattern,
      bodyEngagement: engagement,
      mechanicsType: mechanics,
      forceType: force,
      caloriesPer1000kg: cal,
      source: meta.source,
      catalogExerciseId: meta.catalogExerciseId,
      catalogExerciseName: meta.catalogExerciseName,
    );
  }
}
