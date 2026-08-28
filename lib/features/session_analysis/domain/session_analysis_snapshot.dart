import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/exercise_coach_decision.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/session_analysis/domain/session_analysis_eligibility.dart';
import 'package:gymaipro/workout_log/models/previous_exercise_performance.dart';

/// Immutable payload for the end-of-session analysis screen.
class SessionAnalysisSnapshot {
  const SessionAnalysisSnapshot({
    required this.programKind,
    required this.focus,
    required this.programTitle,
    required this.sessionDay,
    required this.programId,
    required this.completedSets,
    required this.totalSets,
    required this.completedExercises,
    required this.plannedExercises,
    required this.totalVolumeKg,
    required this.durationMinutes,
    required this.skippedExerciseNames,
    required this.comparisons,
    required this.suggestions,
    required this.debrief,
    required this.observations,
    required this.decisionLock,
    this.estimatedCaloriesKcal,
    this.synced = true,
    this.coachNarrative,
  });

  final SessionAnalysisProgramKind programKind;
  final String focus;
  final String programTitle;
  final String? sessionDay;
  final String? programId;
  final int completedSets;
  final int totalSets;
  final int completedExercises;
  final int plannedExercises;
  final double totalVolumeKg;
  final int durationMinutes;
  final int? estimatedCaloriesKcal;
  final List<String> skippedExerciseNames;
  final List<SessionExerciseComparison> comparisons;
  final List<SessionNextSuggestion> suggestions;
  final SessionDebrief debrief;
  final List<CoachObservation> observations;
  final Map<String, Object?> decisionLock;
  final bool synced;
  final String? coachNarrative;

  bool get isIncomplete =>
      plannedExercises > 0 && completedExercises < plannedExercises;

  bool get canModifyProgram =>
      SessionAnalysisEligibility.canModifyProgram(programKind);

  bool get isStarter => programKind == SessionAnalysisProgramKind.starter;

  SessionAnalysisSnapshot copyWith({
    String? coachNarrative,
    bool? synced,
  }) {
    return SessionAnalysisSnapshot(
      programKind: programKind,
      focus: focus,
      programTitle: programTitle,
      sessionDay: sessionDay,
      programId: programId,
      completedSets: completedSets,
      totalSets: totalSets,
      completedExercises: completedExercises,
      plannedExercises: plannedExercises,
      totalVolumeKg: totalVolumeKg,
      durationMinutes: durationMinutes,
      estimatedCaloriesKcal: estimatedCaloriesKcal,
      skippedExerciseNames: skippedExerciseNames,
      comparisons: comparisons,
      suggestions: suggestions,
      debrief: debrief,
      observations: observations,
      decisionLock: decisionLock,
      synced: synced ?? this.synced,
      coachNarrative: coachNarrative ?? this.coachNarrative,
    );
  }

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'program_kind': programKind.name,
      'focus': focus,
      'program_title': programTitle,
      'session_day': sessionDay,
      'program_id': programId,
      'completed_sets': completedSets,
      'total_sets': totalSets,
      'completed_exercises': completedExercises,
      'planned_exercises': plannedExercises,
      'total_volume_kg': totalVolumeKg,
      'duration_minutes': durationMinutes,
      'estimated_calories_kcal': estimatedCaloriesKcal,
      'skipped_exercise_names': skippedExerciseNames,
      'comparisons':
          comparisons.map((c) => c.toJson()).toList(growable: false),
      'suggestions':
          suggestions.map((s) => s.toJson()).toList(growable: false),
      'debrief': debrief.toLockJson(),
      'observations':
          observations.map((o) => o.toLockJson()).toList(growable: false),
      'decision_lock': decisionLock,
      'synced': synced,
      if (coachNarrative != null && coachNarrative!.trim().isNotEmpty)
        'coach_narrative': coachNarrative,
    };
  }

  static SessionAnalysisSnapshot? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final debrief = SessionDebrief.tryParse(json['debrief']);
    if (debrief == null) return null;

    final kindName = json['program_kind']?.toString();
    final kindMatches = SessionAnalysisProgramKind.values.where(
      (e) => e.name == kindName,
    );
    final kind = kindMatches.isEmpty
        ? SessionAnalysisProgramKind.unsupported
        : kindMatches.first;

    final comparisons = <SessionExerciseComparison>[];
    final comparisonsRaw = json['comparisons'];
    if (comparisonsRaw is List) {
      for (final item in comparisonsRaw) {
        final parsed = SessionExerciseComparison.tryParse(item);
        if (parsed != null) comparisons.add(parsed);
      }
    }

    final suggestions = <SessionNextSuggestion>[];
    final suggestionsRaw = json['suggestions'];
    if (suggestionsRaw is List) {
      for (final item in suggestionsRaw) {
        final parsed = SessionNextSuggestion.tryParse(item);
        if (parsed != null) suggestions.add(parsed);
      }
    }

    final observations = <CoachObservation>[];
    final observationsRaw = json['observations'];
    if (observationsRaw is List) {
      for (final item in observationsRaw) {
        final parsed = CoachObservation.tryParse(item);
        if (parsed != null) observations.add(parsed);
      }
    }

    final lockRaw = json['decision_lock'];
    final lock = <String, Object?>{};
    if (lockRaw is Map) {
      for (final entry in lockRaw.entries) {
        lock[entry.key.toString()] = entry.value;
      }
    }

    return SessionAnalysisSnapshot(
      programKind: kind,
      focus: json['focus']?.toString() ?? '',
      programTitle: json['program_title']?.toString() ?? '',
      sessionDay: json['session_day']?.toString(),
      programId: json['program_id']?.toString(),
      completedSets: _asInt(json['completed_sets']) ?? 0,
      totalSets: _asInt(json['total_sets']) ?? 0,
      completedExercises: _asInt(json['completed_exercises']) ??
          debrief.completedExercises,
      plannedExercises: _asInt(json['planned_exercises']) ??
          debrief.plannedExercises,
      totalVolumeKg: _asDouble(json['total_volume_kg']) ?? 0,
      durationMinutes: _asInt(json['duration_minutes']) ?? 0,
      estimatedCaloriesKcal: _asInt(json['estimated_calories_kcal']),
      skippedExerciseNames: _stringList(json['skipped_exercise_names']),
      comparisons: comparisons,
      suggestions: suggestions,
      debrief: debrief,
      observations: observations,
      decisionLock: lock,
      synced: json['synced'] != false,
      coachNarrative: json['coach_narrative']?.toString(),
    );
  }

  static List<String> _stringList(Object? raw) {
    if (raw is! List) return const <String>[];
    return raw
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList(growable: false);
  }

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value?.toString() ?? '');
  }

  static double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}

class SessionExerciseComparison {
  const SessionExerciseComparison({
    required this.exerciseName,
    required this.todaySets,
    this.previousSets = const <PreviousExerciseSet>[],
    this.previousLogDate,
    this.badge,
    this.comparisonLine,
    this.decision,
    this.isFirstLogged = false,
  });

  final String exerciseName;
  final List<PreviousExerciseSet> todaySets;
  final List<PreviousExerciseSet> previousSets;
  final DateTime? previousLogDate;
  final String? badge;
  final String? comparisonLine;
  final ExerciseDecision? decision;
  final bool isFirstLogged;

  bool get hasPreviousHistory =>
      previousSets.any((s) => s.hasMeaningfulData);

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'exercise_name': exerciseName,
      'today_sets': todaySets.map((s) => s.toJson()).toList(growable: false),
      'previous_sets':
          previousSets.map((s) => s.toJson()).toList(growable: false),
      if (previousLogDate != null)
        'previous_log_date': previousLogDate!.toIso8601String(),
      if (badge != null) 'badge': badge,
      if (comparisonLine != null) 'comparison_line': comparisonLine,
      if (decision != null) 'decision': decision!.toLockJson(),
      'is_first_logged': isFirstLogged,
    };
  }

  static SessionExerciseComparison? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final name = json['exercise_name']?.toString().trim() ?? '';
    if (name.isEmpty) return null;
    DateTime? previousDate;
    final dateRaw = json['previous_log_date']?.toString();
    if (dateRaw != null && dateRaw.isNotEmpty) {
      previousDate = DateTime.tryParse(dateRaw);
    }
    return SessionExerciseComparison(
      exerciseName: name,
      todaySets: _sets(json['today_sets']),
      previousSets: _sets(json['previous_sets']),
      previousLogDate: previousDate,
      badge: json['badge']?.toString(),
      comparisonLine: json['comparison_line']?.toString(),
      decision: ExerciseDecision.tryParse(json['decision']),
      isFirstLogged: json['is_first_logged'] == true,
    );
  }

  static List<PreviousExerciseSet> _sets(Object? raw) {
    if (raw is! List) return const <PreviousExerciseSet>[];
    return raw
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (item) => PreviousExerciseSet.fromJson(
            item.map((k, v) => MapEntry(k.toString(), v)),
          ),
        )
        .toList(growable: false);
  }
}

class SessionNextSuggestion {
  const SessionNextSuggestion({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  Map<String, Object?> toJson() {
    return <String, Object?>{
      'title': title,
      'body': body,
    };
  }

  static SessionNextSuggestion? tryParse(Object? raw) {
    if (raw is! Map) return null;
    final json = raw.map((k, v) => MapEntry(k.toString(), v));
    final title = json['title']?.toString().trim() ?? '';
    final body = json['body']?.toString().trim() ?? '';
    if (title.isEmpty && body.isEmpty) return null;
    return SessionNextSuggestion(title: title, body: body);
  }
}
