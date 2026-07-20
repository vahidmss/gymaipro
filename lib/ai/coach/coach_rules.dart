import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/ai/context/profile_age_resolver.dart';

/// Static validation rules for GymAI Coach v2.
///
/// Rules are intentionally local and deterministic. They do not call OpenAI,
/// services, databases, or UI layers.
class CoachRules {
  const CoachRules._();

  /// Profile fields required before generating a personalized workout program.
  static const Set<String> workoutGenerationProfileFields = <String>{
    'age',
    'height',
    'weight',
  };

  /// Ordered checklist for guided workout-generation Q&A.
  static const List<String> workoutGenerationFieldOrder = <String>[
    'age',
    'height',
    'weight',
    'goal',
    'equipment',
  ];

  /// Intents that can be routed to local handling when context is sufficient.
  static const Set<AIIntent> localCapableIntents = <AIIntent>{
    AIIntent.workoutToday,
    AIIntent.recovery,
    AIIntent.motivation,
    AIIntent.appHelp,
    AIIntent.bugReport,
    AIIntent.feedback,
  };

  /// Returns missing profile fields for workout generation (no equipment).
  static List<String> missingWorkoutGenerationData(CoachContext context) {
    final profile = _normalizedProfile(context.profile);
    final missing = <String>[];

    for (final field in workoutGenerationProfileFields) {
      final value = profile[field];
      final ok = switch (field) {
        'weight' => hasValidWeight(value),
        'height' => hasValidHeight(value),
        _ => _hasValue(value),
      };
      if (!ok) {
        missing.add(field);
      }
    }

    if (!_hasGoal(context, profile)) {
      missing.add('goal');
    }

    return List<String>.unmodifiable(missing);
  }

  /// Full missing list including equipment, in Q&A order.
  static List<String> missingWorkoutGenerationFields(CoachContext context) {
    final missing = <String>[
      ...missingWorkoutGenerationData(context),
      if (context.equipment.isEmpty) 'equipment',
    ];
    return List<String>.unmodifiable(
      workoutGenerationFieldOrder
          .where(missing.contains)
          .toList(growable: false),
    );
  }

  /// Next single field the coach should ask about.
  static String? nextWorkoutGenerationField(CoachContext context) {
    final missing = missingWorkoutGenerationFields(context);
    if (missing.isEmpty) return null;
    return missing.first;
  }

  /// Persian follow-up prompt for one generation field.
  static String followUpPromptFor(String field) {
    return switch (field) {
      'age' => 'برای ساخت برنامه دقیق، سنت چند سال است؟',
      'height' => 'قدت چند سانتی‌متر است؟',
      'weight' => 'وزنت حدوداً چند کیلو است؟',
      'goal' =>
        'هدفت از تمرین چیست؟ (مثلاً عضله‌سازی، چربی‌سوزی، قدرت یا عمومی)',
      'equipment' =>
        'با چه تجهیزاتی تمرین می‌کنی؟ (باشگاه کامل، دمبل در خانه، فقط وزن بدن، …)',
      'restrictions' || 'injuries' =>
        'محدودیت یا مصدومیتی داری که باید در برنامه لحاظ شود؟',
      _ => 'برای ادامه ساخت برنامه، لطفاً این مورد را مشخص کن: $field',
    };
  }

  static Map<String, Object?> _normalizedProfile(Map<String, Object?> profile) {
    final out = Map<String, Object?>.from(profile);
    final age = ProfileAgeResolver.resolve(out);
    if (age != null) out['age'] = age;
    return out;
  }

  static bool _hasGoal(CoachContext context, Map<String, Object?> profile) {
    if (context.goals.isNotEmpty) return true;

    return _hasValue(profile['fitness_goals']) || _hasValue(profile['goal']);
  }

  static bool _hasValue(Object? value) {
    if (value == null) return false;
    if (value is String) return value.trim().isNotEmpty;
    if (value is Iterable<Object?>) return value.isNotEmpty;
    return true;
  }

  /// Body-weight must be a plausible kg value (not days/age pollution).
  static bool hasValidWeight(Object? value) {
    if (value == null) return false;
    final n = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());
    if (n == null) return false;
    return n >= 30 && n <= 300;
  }

  /// Height in cm.
  static bool hasValidHeight(Object? value) {
    if (value == null) return false;
    final n = value is num
        ? value.toDouble()
        : double.tryParse(value.toString().trim());
    if (n == null) return false;
    return n >= 100 && n <= 250;
  }
}
