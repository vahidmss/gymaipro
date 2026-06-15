import 'dart:convert';

/// متادیتای غنی تمرین (از `exercise_extended_json` و ستون‌های Supabase).
class ExerciseRichMeta {
  const ExerciseRichMeta({
    this.webSlug = '',
    this.setupSteps = const [],
    this.executionSteps = const [],
    this.breathing = '',
    this.commonMistakes = const [],
    this.recommendedSets = '',
    this.repRangeHypertrophy = '',
    this.repRangeStrength = '',
    this.repRangeEndurance = '',
    this.restSeconds = '',
    this.tempo = '',
    this.programmingGoal = '',
    this.movementPatternLabel = '',
    this.bodyEngagementLabel = '',
    this.mechanicsType = '',
    this.forceType = '',
  });

  factory ExerciseRichMeta.fromJson(dynamic raw) {
    final m = _parseJsonMap(raw);
    if (m.isEmpty) return const ExerciseRichMeta();
    List<String> strList(dynamic v) {
      if (v is List) return v.whereType<String>().toList();
      return [];
    }
    return ExerciseRichMeta(
      webSlug: m['webSlug']?.toString() ?? '',
      setupSteps: strList(m['setupSteps']),
      executionSteps: strList(m['executionSteps']),
      breathing: m['breathing']?.toString() ?? '',
      commonMistakes: strList(m['commonMistakes']),
      recommendedSets: m['recommendedSets']?.toString() ?? '',
      repRangeHypertrophy: m['repRangeHypertrophy']?.toString() ?? '',
      repRangeStrength: m['repRangeStrength']?.toString() ?? '',
      repRangeEndurance: m['repRangeEndurance']?.toString() ?? '',
      restSeconds: m['restSeconds']?.toString() ?? '',
      tempo: m['tempo']?.toString() ?? '',
      programmingGoal: m['programmingGoal']?.toString() ?? '',
      movementPatternLabel: m['movementPatternLabel']?.toString() ?? '',
      bodyEngagementLabel: m['bodyEngagementLabel']?.toString() ?? '',
      mechanicsType: m['mechanicsType']?.toString() ?? '',
      forceType: m['forceType']?.toString() ?? '',
    );
  }

  factory ExerciseRichMeta.fromSupabaseRow(Map<String, dynamic> row) {
    final ext = _parseJsonMap(row['exercise_extended_json']);
    final wpMeta = _parseJsonMap(ext['wp_meta']);
    final programming = _parseJsonMap(ext['programming']);
    final instructions = _parseJsonMap(ext['instructions']);
    final safety = _parseJsonMap(ext['safety']);
    final classification = _parseJsonMap(ext['classification']);

    List<String> linesFrom(dynamic v) {
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      final s = v?.toString().trim() ?? '';
      if (s.isEmpty) return [];
      return s.split(RegExp(r'[\n\r]+')).map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    }

    String pick(String key, {String wpFallback = ''}) {
      final fromProg = programming[key]?.toString().trim() ?? '';
      if (fromProg.isNotEmpty) return fromProg;
      final fromCls = classification[key]?.toString().trim() ?? '';
      if (fromCls.isNotEmpty) return fromCls;
      final fromWp = wpMeta[key]?.toString().trim() ?? '';
      if (fromWp.isNotEmpty) return fromWp;
      return wpFallback;
    }

    var setup = linesFrom(instructions['setup'] ?? wpMeta['setup']);
    var execution = linesFrom(
      instructions['execution'] ?? wpMeta['execution'],
    );
    var breathing = (instructions['breathing'] ?? wpMeta['breathing'] ?? '')
        .toString()
        .trim();
    if (setup.isEmpty && execution.isEmpty) {
      final fromLearn = _parseLearnSections(row['learn']?.toString() ?? '');
      if (setup.isEmpty) setup = fromLearn.setup;
      if (execution.isEmpty) execution = fromLearn.execution;
      if (breathing.isEmpty) breathing = fromLearn.breathing;
    }

    return ExerciseRichMeta(
      webSlug: (ext['slug'] ?? ext['slug_decoded'] ?? row['web_slug'] ?? '')
          .toString()
          .trim(),
      setupSteps: setup,
      executionSteps: execution,
      breathing: breathing,
      commonMistakes: linesFrom(
        safety['common_mistakes'] ?? wpMeta['common_mistakes'],
      ),
      recommendedSets: pick('recommended_sets'),
      repRangeHypertrophy: pick('rep_range_hypertrophy'),
      repRangeStrength: pick('rep_range_strength'),
      repRangeEndurance: pick('rep_range_endurance'),
      restSeconds: pick('rest_seconds'),
      tempo: pick('tempo'),
      programmingGoal: pick('goal', wpFallback: wpMeta['programming_goal']?.toString() ?? ''),
      movementPatternLabel: (classification['movement_pattern_label'] ??
              wpMeta['movement_pattern_label'] ??
              '')
          .toString()
          .trim(),
      bodyEngagementLabel: (classification['body_engagement_label'] ??
              wpMeta['body_engagement_label'] ??
              '')
          .toString()
          .trim(),
      mechanicsType: (classification['mechanics_type'] ??
              wpMeta['mechanics_type'] ??
              '')
          .toString()
          .trim(),
      forceType:
          (classification['force_type'] ?? wpMeta['force_type'] ?? '')
              .toString()
              .trim(),
    );
  }

  final String webSlug;
  final List<String> setupSteps;
  final List<String> executionSteps;
  final String breathing;
  final List<String> commonMistakes;
  final String recommendedSets;
  final String repRangeHypertrophy;
  final String repRangeStrength;
  final String repRangeEndurance;
  final String restSeconds;
  final String tempo;
  final String programmingGoal;
  final String movementPatternLabel;
  final String bodyEngagementLabel;
  final String mechanicsType;
  final String forceType;

  bool get hasExecutionGuide =>
      setupSteps.isNotEmpty || executionSteps.isNotEmpty;

  bool get hasProgramming =>
      recommendedSets.isNotEmpty ||
      repRangeHypertrophy.isNotEmpty ||
      restSeconds.isNotEmpty;

  Map<String, dynamic> toJson() => {
        'webSlug': webSlug,
        'setupSteps': setupSteps,
        'executionSteps': executionSteps,
        'breathing': breathing,
        'commonMistakes': commonMistakes,
        'recommendedSets': recommendedSets,
        'repRangeHypertrophy': repRangeHypertrophy,
        'repRangeStrength': repRangeStrength,
        'repRangeEndurance': repRangeEndurance,
        'restSeconds': restSeconds,
        'tempo': tempo,
        'programmingGoal': programmingGoal,
        'movementPatternLabel': movementPatternLabel,
        'bodyEngagementLabel': bodyEngagementLabel,
        'mechanicsType': mechanicsType,
        'forceType': forceType,
      };

  static ({List<String> setup, List<String> execution, String breathing})
      _parseLearnSections(String learn) {
    if (learn.trim().isEmpty) {
      return (setup: <String>[], execution: <String>[], breathing: '');
    }
    final setup = <String>[];
    final execution = <String>[];
    var breathing = '';
    String? section;
    for (final line in learn.split(RegExp(r'[\n\r]+'))) {
      final t = line.trim();
      if (t.isEmpty) continue;
      if (t.startsWith('آماده‌سازی:') || t.startsWith('آماده سازی:')) {
        section = 'setup';
        final rest = t.replaceFirst(RegExp(r'^آماده.?سازی:\s*'), '').trim();
        if (rest.isNotEmpty) setup.add(rest);
        continue;
      }
      if (t.startsWith('اجرا:') || t.startsWith('اجرای حرکت:')) {
        section = 'execution';
        final rest = t
            .replaceFirst(RegExp(r'^اجرای?\s*حرکت?:\s*'), '')
            .trim();
        if (rest.isNotEmpty) execution.add(rest);
        continue;
      }
      if (t.startsWith('تنفس:')) {
        breathing = t.replaceFirst('تنفس:', '').trim();
        section = null;
        continue;
      }
      if (section == 'setup') {
        setup.add(t);
      } else if (section == 'execution') {
        execution.add(t);
      }
    }
    return (setup: setup, execution: execution, breathing: breathing);
  }

  static Map<String, dynamic> _parseJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    if (raw is String && raw.trim().isNotEmpty) {
      try {
        final d = jsonDecode(raw);
        if (d is Map) return Map<String, dynamic>.from(d);
      } catch (_) {}
    }
    return {};
  }
}
