import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/models/workout_log.dart';
import 'package:gymaipro/models/workout_program.dart';

void main() {
  group('WorkoutLog JSON Model Tests', () {
    test('WorkoutLog should create with JSON data', () {
      // Create a workout log with the factory method
      final workoutLog = WorkoutLog.create(
        userId: 'test_user_id',
        programId: 'test_program_id',
        programName: 'Test Program',
        sessionId: 'test_session_id',
        sessionName: 'Test Session',
        exerciseId: 'test_exercise_id',
        exerciseName: 'Test Exercise',
        exerciseTag: 'Chest',
        exerciseType: ExerciseType.normal,
        sets: [
          WorkoutSet(reps: 10, weight: 50, isCompleted: true),
          WorkoutSet(reps: 8, weight: 60, isCompleted: true),
        ],
        notes: 'Test notes',
        durationSeconds: 300,
        caloriesBurned: 150,
        rating: 4,
        feeling: 'Great',
        isCompleted: true,
      );

      // Verify all properties are set correctly
      expect(workoutLog.userId, 'test_user_id');
      expect(workoutLog.programId, 'test_program_id');
      expect(workoutLog.programName, 'Test Program');
      expect(workoutLog.sessionId, 'test_session_id');
      expect(workoutLog.sessionName, 'Test Session');
      expect(workoutLog.exerciseId, 'test_exercise_id');
      expect(workoutLog.exerciseName, 'Test Exercise');
      expect(workoutLog.exerciseTag, 'Chest');
      expect(workoutLog.exerciseType, ExerciseType.normal);
      expect(workoutLog.sets.length, 2);
      expect(workoutLog.sets[0].reps, 10);
      expect(workoutLog.sets[0].weight, 50);
      expect(workoutLog.sets[0].isCompleted, true);
      expect(workoutLog.sets[1].reps, 8);
      expect(workoutLog.sets[1].weight, 60);
      expect(workoutLog.sets[1].isCompleted, true);
      expect(workoutLog.notes, 'Test notes');
      expect(workoutLog.durationSeconds, 300);
      expect(workoutLog.caloriesBurned, 150);
      expect(workoutLog.rating, 4);
      expect(workoutLog.feeling, 'Great');
      expect(workoutLog.isCompleted, true);
    });

    test('WorkoutLog should convert to JSON correctly', () {
      // Create a workout log
      final workoutLog = WorkoutLog.create(
        userId: 'test_user_id',
        programId: 'test_program_id',
        programName: 'Test Program',
        sessionId: 'test_session_id',
        sessionName: 'Test Session',
        exerciseId: 'test_exercise_id',
        exerciseName: 'Test Exercise',
        exerciseTag: 'Chest',
        exerciseType: ExerciseType.normal,
        sets: [
          WorkoutSet(reps: 10, weight: 50, isCompleted: true),
        ],
        notes: 'Test notes',
      );

      // Convert to JSON
      final json = workoutLog.toJson();

      // Verify JSON structure
      expect(json['id'], isNotNull);
      expect(json['user_id'], 'test_user_id');
      expect(json['workout_data'], isA<Map<String, dynamic>>());
      expect(json['workout_data']['program_id'], 'test_program_id');
      expect(json['workout_data']['program_name'], 'Test Program');
      expect(json['workout_data']['session_id'], 'test_session_id');
      expect(json['workout_data']['session_name'], 'Test Session');
      expect(json['workout_data']['exercise_id'], 'test_exercise_id');
      expect(json['workout_data']['exercise_name'], 'Test Exercise');
      expect(json['workout_data']['exercise_tag'], 'Chest');
      expect(json['workout_data']['exercise_type'], 'normal');
      expect(json['workout_data']['sets'], isA<List>());
      expect(json['workout_data']['sets'][0]['reps'], 10);
      expect(json['workout_data']['sets'][0]['weight'], 50);
      expect(json['workout_data']['sets'][0]['is_completed'], true);
      expect(json['workout_data']['notes'], 'Test notes');
    });

    test('WorkoutLog should handle conversion from JSON correctly', () {
      // Create a JSON object
      final json = {
        'id': 'test_id',
        'user_id': 'test_user_id',
        'created_at': '2023-05-19T23:02:50.000Z',
        'workout_data': {
          'program_id': 'test_program_id',
          'program_name': 'Test Program',
          'session_id': 'test_session_id',
          'session_name': 'Test Session',
          'exercise_id': 'test_exercise_id',
          'exercise_name': 'Test Exercise',
          'exercise_tag': 'Chest',
          'exercise_type': 'superset',
          'sets': [
            {
              'reps': 10,
              'weight': 50,
              'time_seconds': null,
              'is_completed': true
            }
          ],
          'notes': 'Test notes',
          'duration_seconds': 300,
          'calories_burned': 150,
          'rating': 4,
          'feeling': 'Great',
          'is_completed': true
        }
      };

      // Convert from JSON
      final workoutLog = WorkoutLog.fromJson(json);

      // Verify properties
      expect(workoutLog.id, 'test_id');
      expect(workoutLog.userId, 'test_user_id');
      expect(workoutLog.programId, 'test_program_id');
      expect(workoutLog.programName, 'Test Program');
      expect(workoutLog.sessionId, 'test_session_id');
      expect(workoutLog.sessionName, 'Test Session');
      expect(workoutLog.exerciseId, 'test_exercise_id');
      expect(workoutLog.exerciseName, 'Test Exercise');
      expect(workoutLog.exerciseTag, 'Chest');
      expect(workoutLog.exerciseType, ExerciseType.superset);
      expect(workoutLog.sets.length, 1);
      expect(workoutLog.sets[0].reps, 10);
      expect(workoutLog.sets[0].weight, 50);
      expect(workoutLog.sets[0].isCompleted, true);
      expect(workoutLog.notes, 'Test notes');
      expect(workoutLog.durationSeconds, 300);
      expect(workoutLog.caloriesBurned, 150);
      expect(workoutLog.rating, 4);
      expect(workoutLog.feeling, 'Great');
      expect(workoutLog.isCompleted, true);
    });

    test('WorkoutLog should handle legacy format', () {
      // Create a JSON object with the legacy format
      final legacyJson = {
        'id': 'test_id',
        'user_id': 'test_user_id',
        'created_at': '2023-05-19T23:02:50.000Z',
        'program_id': 'test_program_id',
        'program_name': 'Test Program',
        'session_id': 'test_session_id',
        'session_name': 'Test Session',
        'exercise_id': 'test_exercise_id',
        'exercise_name': 'Test Exercise',
        'exercise_tag': 'Chest',
        'exercise_type': 'triset',
        'sets': [
          {'reps': 10, 'weight': 50, 'time_seconds': null, 'is_completed': true}
        ],
        'notes': 'Test notes',
        'duration_seconds': 300,
        'calories_burned': 150,
        'rating': 4,
        'feeling': 'Great',
        'is_completed': true
      };

      // Convert from legacy JSON
      final workoutLog = WorkoutLog.fromJson(legacyJson);

      // Verify properties
      expect(workoutLog.id, 'test_id');
      expect(workoutLog.userId, 'test_user_id');
      expect(workoutLog.programId, 'test_program_id');
      expect(workoutLog.programName, 'Test Program');
      expect(workoutLog.sessionId, 'test_session_id');
      expect(workoutLog.sessionName, 'Test Session');
      expect(workoutLog.exerciseId, 'test_exercise_id');
      expect(workoutLog.exerciseName, 'Test Exercise');
      expect(workoutLog.exerciseTag, 'Chest');
      expect(workoutLog.exerciseType, ExerciseType.triset);
      expect(workoutLog.sets.length, 1);
      expect(workoutLog.sets[0].reps, 10);
      expect(workoutLog.sets[0].weight, 50);
      expect(workoutLog.sets[0].isCompleted, true);
      expect(workoutLog.notes, 'Test notes');
      expect(workoutLog.durationSeconds, 300);
      expect(workoutLog.caloriesBurned, 150);
      expect(workoutLog.rating, 4);
      expect(workoutLog.feeling, 'Great');
      expect(workoutLog.isCompleted, true);
    });

    test('WorkoutLog.toFullJson should return flattened JSON', () {
      // Create a workout log
      final workoutLog = WorkoutLog.create(
        userId: 'test_user_id',
        programId: 'test_program_id',
        exerciseId: 'test_exercise_id',
        sessionId: 'test_session_id',
        exerciseType: ExerciseType.normal,
        sets: [WorkoutSet(reps: 10, weight: 50)],
      );

      // Get full JSON
      final fullJson = workoutLog.toFullJson();

      // Verify the structure is flattened
      expect(fullJson['id'], isNotNull);
      expect(fullJson['user_id'], 'test_user_id');
      expect(fullJson['program_id'], 'test_program_id');
      expect(fullJson['exercise_id'], 'test_exercise_id');
      expect(fullJson['session_id'], 'test_session_id');
      expect(fullJson['exercise_type'], 'normal');
      expect(fullJson['sets'], isA<List>());
    });
  });
}
