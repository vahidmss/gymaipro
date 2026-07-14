import 'package:gymaipro/ai/memory/memory_category.dart';
import 'package:gymaipro/ai/memory/memory_manager.dart';
import 'package:gymaipro/ai/memory/memory_source.dart';
import 'package:gymaipro/ai/memory/memory_updater.dart';
import 'package:gymaipro/features/live_workout/application/live_workout_session_persistence.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_session.dart';
import 'package:gymaipro/features/live_workout/domain/session/workout_set_session_status.dart';
import 'package:gymaipro/features/live_workout/state/live_workout_completion_summary.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LiveWorkoutCompletionResult {
  const LiveWorkoutCompletionResult({
    required this.summary,
    required this.persistence,
  });

  final LiveWorkoutCompletionSummary summary;
  final LiveWorkoutPersistenceResult persistence;
}

/// Integrates completion side-effects: persist, memory, recovery, coach message.
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

  Future<LiveWorkoutCompletionResult> complete({
    required WorkoutSession session,
    required String userId,
    required List<String> coachTips,
    required List<String> explainability,
  }) async {
    final previousSets = await _persistence.countCompletedSetsForDate(
      userId: userId,
      date: session.startedAt.subtract(const Duration(days: 1)),
    );
    final currentSets = session.completedSets;
    final volume = _totalVolume(session);
    final durationMinutes = DateTime.now().difference(session.startedAt).inMinutes;

    final persistence = await _persistence.persistSession(
      session: session,
      userId: userId,
    );

    await _updateMemory(
      userId: userId,
      session: session,
      completedSets: currentSets,
      volume: volume,
    );
    await _updateRecovery(
      userId: userId,
      session: session,
      completedSets: currentSets,
    );

    final coachMessage = ProductExperienceFormatter.postWorkoutCoachMessage(
      sessionTitle: session.title,
      completedSets: currentSets,
      previousSessionSets: previousSets,
      totalVolumeKg: volume,
      coachTips: coachTips,
    );

    final summary = LiveWorkoutCompletionSummary(
      title: session.title,
      focus: session.focus,
      durationMinutes: durationMinutes.clamp(1, 999),
      completedExercises: session.finishedExercises,
      totalExercises: session.totalExercises,
      completedSets: currentSets,
      totalSets: session.totalSets,
      totalVolumeKg: volume,
      coachMessage: coachMessage,
      highlights: ProductExperienceFormatter.workoutCompletionHighlights(
        completedExercises: session.finishedExercises,
        totalExercises: session.totalExercises,
        completedSets: currentSets,
        totalSets: session.totalSets,
        totalVolumeKg: volume,
        explainability: explainability,
      ),
      synced: persistence.synced,
    );

    return LiveWorkoutCompletionResult(
      summary: summary,
      persistence: persistence,
    );
  }

  Future<void> _updateMemory({
    required String userId,
    required WorkoutSession session,
    required int completedSets,
    required double volume,
  }) async {
    try {
      await _memoryManager.addOrUpdateMemory(
        userId,
        MemoryUpdateRequest(
          key: 'last_completed_workout',
          value:
              '${session.focus}: $completedSets ست، حجم ${volume.toStringAsFixed(0)} کیلو',
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
        volume += set.effectiveReps * set.effectiveWeightKg;
      }
    }
    return volume;
  }
}
