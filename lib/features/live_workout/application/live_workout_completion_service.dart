import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_persistence.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/product_experience/domain/coach_observation.dart';
import 'package:gymaipro/features/product_experience/domain/session_debrief.dart';
import 'package:gymaipro/features/product_experience/domain/workout_exercise_coach_feedback.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/services/muscle_heatmap_aggregate.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveWorkoutCompletionResult {
  const LiveWorkoutCompletionResult({
    required this.summary,
    required this.persistence,
    this.debrief,
    this.observations = const <CoachObservation>[],
  });

  final LiveWorkoutCompletionSummary summary;
  final LiveWorkoutPersistenceResult persistence;
  final SessionDebrief? debrief;
  final List<CoachObservation> observations;
}

/// Integrates completion side-effects: persist, memory, recovery, summary.
class LiveWorkoutCompletionService {
  LiveWorkoutCompletionService({
    LiveWorkoutSessionPersistence? persistence,
    MemoryManager? memoryManager,
    SharedPreferences? preferences,
  }) : _persistence = persistence ?? LiveWorkoutSessionPersistence(),
       _memoryManager = memoryManager ?? MemoryManager(),
       _preferences = preferences;

  final LiveWorkoutSessionPersistence _persistence;
  final MemoryManager _memoryManager;
  final SharedPreferences? _preferences;

  static const _observationsPrefsKeyPrefix = 'coach_observations_';

  Future<LiveWorkoutCompletionResult> complete({
    required WorkoutSession session,
    required String userId,
    Map<int, Exercise> exerciseById = const <int, Exercise>{},
    Map<String, WorkoutExerciseCoachFeedback> feedbackByExerciseKey =
        const <String, WorkoutExerciseCoachFeedback>{},
  }) async {
    final currentSets = session.completedSets;
    final volume = _totalVolume(session);

    final persistence = await _persistence.persistSession(
      session: session,
      userId: userId,
    );

    final debrief = SessionDebriefEngine.build(
      session: session,
      feedbackByExerciseKey: feedbackByExerciseKey,
    );

    await _updateMemory(
      userId: userId,
      session: session,
      completedSets: currentSets,
      volume: volume,
      debrief: debrief,
    );
    await _updateRecovery(
      userId: userId,
      session: session,
      completedSets: currentSets,
    );

    final observations = CoachObservationDetector.fromDebrief(debrief);
    await _persistObservations(userId: userId, observations: observations);

    final summary = buildSummary(
      session: session,
      exerciseById: exerciseById,
      synced: persistence.synced,
      debrief: debrief,
    );

    return LiveWorkoutCompletionResult(
      summary: summary,
      persistence: persistence,
      debrief: debrief,
      observations: observations,
    );
  }

  /// Rebuilds the on-screen completion card without re-running side effects.
  LiveWorkoutCompletionSummary buildSummary({
    required WorkoutSession session,
    Map<int, Exercise> exerciseById = const <int, Exercise>{},
    bool synced = true,
    SessionDebrief? debrief,
    Map<String, WorkoutExerciseCoachFeedback> feedbackByExerciseKey =
        const <String, WorkoutExerciseCoachFeedback>{},
  }) {
    final heatmap = MuscleHeatmapAggregate.fromLiveSession(
      session,
      exerciseById,
    );
    final resolvedDebrief =
        debrief ??
        SessionDebriefEngine.build(
          session: session,
          feedbackByExerciseKey: feedbackByExerciseKey,
        );
    return LiveWorkoutCompletionSummary.fromSessionStats(
      focus: session.focus,
      completedSets: session.completedSets,
      totalSets: session.totalSets,
      totalVolumeKg: _totalVolume(session),
      heatmap: heatmap,
      synced: synced,
      debrief: resolvedDebrief,
    );
  }

  Future<List<CoachObservation>> loadStoredObservations(String userId) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final raw = prefs.getStringList('$_observationsPrefsKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return const <CoachObservation>[];
    return raw
        .map((line) {
          final parts = line.split('|');
          if (parts.length < 2) return null;
          final matches = CoachObservationCode.values.where(
            (c) => c.name == parts.first,
          );
          if (matches.isEmpty) return null;
          final code = matches.first;
          return CoachObservation(
            code: code,
            severity: CoachObservationSeverity.watch,
            severityLabel: 'پیگیری',
            evidence: const <String>['stored'],
            message: parts.sublist(1).join('|'),
          );
        })
        .whereType<CoachObservation>()
        .toList(growable: false);
  }

  Future<void> _persistObservations({
    required String userId,
    required List<CoachObservation> observations,
  }) async {
    if (observations.isEmpty) return;
    try {
      final prefs = _preferences ?? await SharedPreferences.getInstance();
      final lines = observations
          .map((o) => '${o.code.name}|${o.message}')
          .toList(growable: false);
      await prefs.setStringList('$_observationsPrefsKeyPrefix$userId', lines);
    } on Object {
      // Best-effort local cache for coach home.
    }
  }

  Future<void> _updateMemory({
    required String userId,
    required WorkoutSession session,
    required int completedSets,
    required double volume,
    SessionDebrief? debrief,
  }) async {
    try {
      final bits = <String>[
        '${session.focus}: $completedSets ست، حجم ${volume.toStringAsFixed(0)} کیلو',
      ];
      final focus = debrief?.nextFocus.trim();
      if (focus != null && focus.isNotEmpty) {
        bits.add(focus);
      }
      final holds = debrief?.heldCount ?? 0;
      final improved = debrief?.improvedCount ?? 0;
      if (holds > 0 && improved == 0) {
        bits.add('وزنه را همین جلسه زیاد نکن.');
      }
      await _memoryManager.addOrUpdateMemory(
        userId,
        MemoryUpdateRequest(
          key: 'last_completed_workout',
          value: bits.join(' — '),
          category: MemoryCategory.workout,
          source: MemorySource.user,
          confidence: 0.95,
        ),
      );
    } on Object {
      // Memory is best-effort; session persistence already succeeded locally.
    }
  }

  Future<void> _updateRecovery({
    required String userId,
    required WorkoutSession session,
    required int completedSets,
  }) async {
    final prefs = _preferences ?? await SharedPreferences.getInstance();
    final fatigue = (completedSets * 2).clamp(0, 40);
    final previous =
        int.tryParse(prefs.getString('recovery_score_$userId') ?? '') ?? 70;
    final next = (previous - fatigue).clamp(15, 100);
    await prefs.setString('recovery_score_$userId', '$next');
    await prefs.setString(
      'last_workout_completed_at_$userId',
      DateTime.now().toIso8601String(),
    );
  }

  double _totalVolume(WorkoutSession session) {
    var volume = 0.0;
    for (final exercise in session.exercises) {
      for (final set in exercise.sets) {
        if (set.status != WorkoutSetSessionStatus.completed &&
            set.status != WorkoutSetSessionStatus.failed) {
          continue;
        }
        volume += (set.actualReps ?? 0) * (set.actualWeightKg ?? 0);
      }
    }
    return volume;
  }
}
