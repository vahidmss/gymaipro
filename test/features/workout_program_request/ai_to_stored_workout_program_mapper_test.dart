import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/ai/knowledge/workout_science.dart';
import 'package:gymaipro/ai/workout/models/workout_day.dart';
import 'package:gymaipro/ai/workout/models/workout_exercise.dart';
import 'package:gymaipro/ai/workout/models/workout_program.dart';
import 'package:gymaipro/ai/workout/models/workout_set.dart';
import 'package:gymaipro/ai/workout/models/workout_week.dart';
import 'package:gymaipro/features/workout_program_request/application/ai_to_stored_workout_program_mapper.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart'
    as stored;

void main() {
  test('AiToStoredWorkoutProgramMapper maps days to sessions', () {
    final now = DateTime(2026, 7, 17);
    final aiProgram = WorkoutProgram(
      id: 'ai-1',
      name: 'برنامه تست',
      goal: TrainingGoal.hypertrophy,
      experienceLevel: 'مبتدی',
      daysPerWeek: 3,
      weeks: <WorkoutWeek>[
        WorkoutWeek(
          id: 'w1',
          weekIndex: 0,
          days: <WorkoutDay>[
            WorkoutDay(
              id: 'd1',
              dayIndex: 0,
              label: 'سینه',
              exercises: <WorkoutExercise>[
                WorkoutExercise(
                  id: 'e1',
                  catalogExerciseId: 42,
                  name: 'پرس سینه',
                  primaryMuscle: 'سینه',
                  order: 0,
                  sets: const <WorkoutSet>[
                    WorkoutSet(
                      id: 's1',
                      order: 0,
                      type: WorkoutSetType.reps,
                      reps: 10,
                    ),
                    WorkoutSet(
                      id: 's2',
                      order: 1,
                      type: WorkoutSetType.reps,
                      reps: 10,
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ],
      createdAt: now,
      updatedAt: now,
    );

    final mapped = const AiToStoredWorkoutProgramMapper().map(
      aiProgram,
      userId: 'user-1',
      trainerId: 'trainer-1',
    );

    expect(mapped.name, 'برنامه تست');
    expect(mapped.isSelfServiceAi, isTrue);
    expect(mapped.sessions, hasLength(1));
    expect(mapped.sessions.first.day, 'سینه');
    final exercise = mapped.sessions.first.exercises.first as stored.NormalExercise;
    expect(exercise.exerciseId, 42);
    expect(exercise.sets, hasLength(2));
    expect(exercise.sets.first.reps, 10);
  });
}
