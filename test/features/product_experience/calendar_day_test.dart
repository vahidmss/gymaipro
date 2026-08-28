import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/context/coach_context.dart';
import 'package:gymaipro/ai/context/coach_context_metadata.dart';
import 'package:gymaipro/ai/context/context_models.dart';
import 'package:gymaipro/ai/context/intent_detector.dart';
import 'package:gymaipro/features/product_experience/calendar_day.dart';
import 'package:gymaipro/features/product_experience/product_experience_formatter.dart';
import 'package:gymaipro/features/product_experience/recovery/recovery_guidance.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';

void main() {
  group('CalendarDay', () {
    test('same calendar day is 0 even across many hours', () {
      final evening = DateTime(2026, 8, 9, 23, 10);
      final late = DateTime(2026, 8, 9, 23, 55);
      expect(CalendarDay.daysBetween(evening, late), 0);
    });

    test('after local midnight counts as a new day', () {
      final evening = DateTime(2026, 8, 9, 23, 10);
      final afterMidnight = DateTime(2026, 8, 10, 0, 30);
      expect(CalendarDay.daysBetween(evening, afterMidnight), 1);
    });

    test('Duration.inDays would wrongly stay 0 under 24h', () {
      final evening = DateTime(2026, 8, 9, 23, 10);
      final afterMidnight = DateTime(2026, 8, 10, 0, 30);
      expect(afterMidnight.difference(evening).inDays, 0);
      expect(CalendarDay.daysBetween(evening, afterMidnight), 1);
    });
  });

  group('hub recovery day awareness', () {
    test('formatter daysSince uses calendar days', () {
      final completedAt = DateTime(2026, 8, 9, 22);
      final buildTime = DateTime(2026, 8, 10, 1);
      final context = CoachContext(
        intent: AIIntent.workoutToday,
        metadata: CoachContextMetadata(
          buildTime: buildTime,
          sourceCount: 1,
          missingProviders: const <AIContextProviderKey>{},
          confidence: 1,
          contextVersion: CoachContext.contextVersion,
        ),
        preferences: <String, Object?>{
          'last_workout_completed_at': completedAt.toIso8601String(),
        },
      );

      final snapshot = ProductExperienceFormatter.recoverySnapshot(
        context: context,
      );
      expect(snapshot.daysSinceLastWorkout, 1);

      final guidance = RecoveryGuidance.fromSnapshot(snapshot);
      expect(guidance.scenario, isNot(RecoveryScenario.postSessionToday));
    });

    test('empty ghost log for today does not mean trained today', () {
      final today = DateTime(2026, 8, 10, 12);
      final context = CoachContext(
        intent: AIIntent.workoutToday,
        metadata: CoachContextMetadata(
          buildTime: today,
          sourceCount: 1,
          missingProviders: const <AIContextProviderKey>{},
          confidence: 1,
          contextVersion: CoachContext.contextVersion,
        ),
        workoutHistory: [
          WorkoutDailyLog(
            userId: 'u1',
            logDate: today,
            sessions: [
              WorkoutSessionLog(
                id: 's1',
                day: 'روز ۱',
                exercises: const [],
              ),
            ],
          ),
        ],
      );

      final snapshot = ProductExperienceFormatter.recoverySnapshot(
        context: context,
      );
      expect(snapshot.daysSinceLastWorkout, isNull);
      expect(snapshot.sessionCompletedToday, isFalse);

      final guidance = RecoveryGuidance.fromSnapshot(snapshot);
      expect(guidance.scenario, isNot(RecoveryScenario.postSessionToday));
    });

    test('incomplete sets today do not mark session completed', () {
      final today = DateTime(2026, 8, 10, 21);
      final context = CoachContext(
        intent: AIIntent.workoutToday,
        metadata: CoachContextMetadata(
          buildTime: today,
          sourceCount: 1,
          missingProviders: const <AIContextProviderKey>{},
          confidence: 1,
          contextVersion: CoachContext.contextVersion,
        ),
        workoutHistory: [
          WorkoutDailyLog(
            userId: 'u1',
            logDate: today,
            sessions: [
              WorkoutSessionLog(
                id: 's1',
                day: 'روز ۱',
                exercises: [
                  NormalExerciseLog(
                    id: 'ex1',
                    exerciseId: 1,
                    exerciseName: 'اسکوات',
                    tag: 'primary',
                    style: 'sets_reps',
                    sets: [
                      ExerciseSetLog(reps: 8, weight: 60),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      );

      final snapshot = ProductExperienceFormatter.recoverySnapshot(
        context: context,
      );
      expect(snapshot.daysSinceLastWorkout, 0);
      expect(snapshot.sessionCompletedToday, isFalse);

      final guidance = RecoveryGuidance.fromSnapshot(snapshot);
      expect(guidance.scenario, isNot(RecoveryScenario.postSessionToday));
    });

    test('last_workout_completed_at today marks session completed', () {
      final today = DateTime(2026, 8, 10, 21);
      final context = CoachContext(
        intent: AIIntent.workoutToday,
        metadata: CoachContextMetadata(
          buildTime: today,
          sourceCount: 1,
          missingProviders: const <AIContextProviderKey>{},
          confidence: 1,
          contextVersion: CoachContext.contextVersion,
        ),
        preferences: <String, Object?>{
          'last_workout_completed_at':
              DateTime(2026, 8, 10, 18).toIso8601String(),
          'recovery_score': 48,
        },
      );

      final snapshot = ProductExperienceFormatter.recoverySnapshot(
        context: context,
      );
      expect(snapshot.sessionCompletedToday, isTrue);
      expect(snapshot.daysSinceLastWorkout, 0);

      final guidance = RecoveryGuidance.fromSnapshot(snapshot);
      expect(guidance.scenario, RecoveryScenario.postSessionToday);
    });
  });
}
