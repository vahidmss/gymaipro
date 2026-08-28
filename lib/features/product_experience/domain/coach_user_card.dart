import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_profile_metrics.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';

/// Compact, never-dropped picture of THIS user for engines and LLM.
///
/// The raw JSON is for the model. [userFacingLines] is what the athlete can
/// see on Coach Home — not a debug dump.
class CoachUserCard {
  const CoachUserCard({
    required this.identityLine,
    required this.todayLine,
    required this.programLine,
    required this.lastSessionLine,
    required this.constraintLine,
    required this.nextFocusLine,
    required this.sparse,
  });

  static const String sectionId = 'user.card';

  static const String systemRule =
      'Read user.card first. Speak to THIS person with their own name and '
      'numbers. Do not give generic internet coaching. If a field is missing '
      'or marked unknown, do not invent it. If last session / next focus says '
      'not to add kg, do not add kg.';

  final String? identityLine;
  final String? todayLine;
  final String? programLine;
  final String? lastSessionLine;
  final String? constraintLine;
  final String? nextFocusLine;
  final bool sparse;

  factory CoachUserCard.fromContext(
    CoachContext context, {
    CoachRecoverySnapshot? recovery,
    Map<String, Object?>? decisionLock,
  }) {
    final identity = _identityLine(context);
    final program = _programLine(context);
    final lastSession = _memoryValue(context, 'last_completed_workout');
    final constraint = _constraintLine(context);
    final nextFocus = _nextFocusLine(decisionLock);
    final today = _todayLine(context, recovery);

    final knownCount = <String?>[
      identity,
      today,
      program,
      lastSession,
      constraint,
      nextFocus,
    ].where((line) => line != null && line.trim().isNotEmpty).length;

    return CoachUserCard(
      identityLine: identity,
      todayLine: today,
      programLine: program,
      lastSessionLine: lastSession,
      constraintLine: constraint,
      nextFocusLine: nextFocus,
      sparse: knownCount < 2,
    );
  }

  /// Lines the athlete may see (no lock jargon).
  List<String> get userFacingLines {
    return <String>[
      if (identityLine != null) identityLine!,
      if (constraintLine != null) constraintLine!,
      if (programLine != null) programLine!,
      if (lastSessionLine != null) lastSessionLine!,
    ];
  }

  /// Persian block the model must cite.
  String get promptText {
    final lines = <String>[
      if (identityLine != null) identityLine!,
      if (todayLine != null) todayLine!,
      if (programLine != null) programLine!,
      if (lastSessionLine != null) 'آخرین جلسه: $lastSessionLine',
      if (constraintLine != null) constraintLine!,
      if (nextFocusLine != null) 'تمرکز جلسه بعد: $nextFocusLine',
      if (sparse) 'پرونده هنوز ناقص است — چیزی که اینجاست را حدس نزن.',
    ];
    if (lines.isEmpty) {
      return 'هنوز کارت کاربر خالی است. عدد و آسیب اختراع نکن.';
    }
    return lines.join('\n');
  }

  Map<String, Object?> toPromptContent() {
    return <String, Object?>{
      'card_fa': promptText,
      'rule': systemRule,
      'sparse': sparse,
    };
  }

  static String? _identityLine(CoachContext context) {
    final profile = context.profile;
    final parts = <String>[];
    final name = profile['first_name']?.toString().trim();
    if (name != null && name.isNotEmpty && name != 'ورزشکار') {
      parts.add(name);
    }
    final age = _asInt(profile['age'] ?? profile['bb_age']);
    if (age != null && age > 10 && age < 90) {
      parts.add('$age ساله');
    }
    final weight = CoachProfileMetrics.readDouble(
      profile,
      CoachProfileMetrics.weightKeys,
    );
    if (weight != null) {
      parts.add('${_fmtKg(weight)} کیلو');
    }
    final goal = context.goals.isEmpty
        ? profile['goal']?.toString().trim()
        : context.goals.first.trim();
    if (goal != null && goal.isNotEmpty) {
      parts.add('هدف $goal');
    }
    if (parts.isEmpty) return null;
    return parts.join(' · ');
  }

  static String? _todayLine(
    CoachContext context,
    CoachRecoverySnapshot? recovery,
  ) {
    final guidance = recovery == null
        ? RecoveryGuidance.fromContext(context)
        : RecoveryGuidance.fromSnapshot(recovery);
    final headline = guidance.headline.trim();
    return headline.isEmpty ? null : headline;
  }

  static String? _programLine(CoachContext context) {
    final program = context.activeProgram;
    if (program == null || program.isEmpty) return null;
    final name =
        (program['name'] ?? program['program_name'] ?? program['title'])
            ?.toString()
            .trim();
    final day =
        (program['selected_session_day'] ??
                program['today_session_day'] ??
                program['session_day'] ??
                program['focus'])
            ?.toString()
            .trim();
    if (name != null && name.isNotEmpty && day != null && day.isNotEmpty) {
      return 'برنامه «$name» · جلسه $day';
    }
    if (name != null && name.isNotEmpty) {
      return 'برنامه فعال: $name';
    }
    return null;
  }

  static String? _constraintLine(CoachContext context) {
    final items = context.restrictions
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .toList(growable: false);
    if (items.isEmpty) return null;
    return 'محدودیت: ${items.join('، ')}';
  }

  static String? _memoryValue(CoachContext context, String key) {
    for (final memory in context.memories) {
      if (memory.key != key) continue;
      final value = memory.value.trim();
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  static String? _nextFocusLine(Map<String, Object?>? lock) {
    if (lock == null || lock.isEmpty) return null;
    final debrief = lock['debrief'];
    if (debrief is Map) {
      final focus = debrief['next_focus']?.toString().trim();
      if (focus != null && focus.isNotEmpty) return focus;
    }
    final decisions = lock['decisions'];
    if (decisions is List) {
      for (final item in decisions) {
        if (item is! Map) continue;
        if (item['incomplete_volume'] == true) {
          return 'ست ناقص بوده؛ وزنه را زیاد نکن.';
        }
      }
    }
    return null;
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static String _fmtKg(double kg) {
    if (kg == kg.roundToDouble()) return kg.round().toString();
    return kg.toStringAsFixed(1);
  }
}
