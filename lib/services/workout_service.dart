import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout.dart';

class WorkoutService {
  static final WorkoutService _instance = WorkoutService._internal();

  factory WorkoutService() {
    return _instance;
  }

  WorkoutService._internal();

  Future<List<Workout>> getUserWorkouts(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('workouts')
          .select('*, exercises(*)')
          .eq('id', userId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((workout) => Workout.fromJson(workout as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting user workouts: $e');
      rethrow;
    }
  }

  Future<Workout> createWorkout(String userId, String name, String description,
      List<Exercise> exercises) async {
    try {
      final response = await Supabase.instance.client
          .from('workouts')
          .insert({
            'id': userId,
            'name': name,
            'description': description,
            'created_at': DateTime.now().toIso8601String(),
          })
          .select('*')
          .single();

      final workout = response;

      // Add exercises to the workout
      for (var exercise in exercises) {
        await Supabase.instance.client.from('workout_exercises').insert({
          'workout_id': workout['id'],
          'exercise_id': exercise.id,
        });
      }

      return Workout.fromJson(workout);
    } catch (e) {
      print('Error creating workout: $e');
      rethrow;
    }
  }

  Future<void> updateWorkout(Workout workout) async {
    try {
      await Supabase.instance.client.from('workouts').update({
        'name': workout.name,
        'description': workout.description,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', workout.id);

      // Update exercises
      await Supabase.instance.client
          .from('workout_exercises')
          .delete()
          .eq('workout_id', workout.id);

      for (var exercise in workout.exercises) {
        await Supabase.instance.client.from('workout_exercises').insert({
          'workout_id': workout.id,
          'exercise_id': exercise.id,
        });
      }
    } catch (e) {
      print('Error updating workout: $e');
      rethrow;
    }
  }

  Future<void> deleteWorkout(String workoutId) async {
    try {
      await Supabase.instance.client
          .from('workouts')
          .delete()
          .eq('id', workoutId);
    } catch (e) {
      print('Error deleting workout: $e');
      rethrow;
    }
  }

  Future<List<Exercise>> getAllExercises() async {
    try {
      final response = await Supabase.instance.client
          .from('exercises')
          .select('*')
          .order('name');

      return (response as List<dynamic>)
          .map(
              (exercise) => Exercise.fromJson(exercise as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting exercises: $e');
      rethrow;
    }
  }

  Future<List<Exercise>> searchExercises(String query) async {
    try {
      final response = await Supabase.instance.client
          .from('exercises')
          .select('*')
          .ilike('name', '%$query%')
          .order('name');

      return (response as List<dynamic>)
          .map(
              (exercise) => Exercise.fromJson(exercise as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error searching exercises: $e');
      rethrow;
    }
  }

  Future<List<Exercise>> getExercisesByMuscleGroup(String muscleGroup) async {
    try {
      final response = await Supabase.instance.client
          .from('exercises')
          .select('*')
          .eq('muscle_group', muscleGroup)
          .order('name');

      return (response as List<dynamic>)
          .map(
              (exercise) => Exercise.fromJson(exercise as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting exercises by muscle group: $e');
      rethrow;
    }
  }

  Future<WorkoutLog> startWorkout(String workoutId, String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('workout_logs')
          .insert({
            'workout_id': workoutId,
            'id': userId,
            'start_time': DateTime.now().toIso8601String(),
          })
          .select('*')
          .single();

      return WorkoutLog.fromJson(response);
    } catch (e) {
      print('Error starting workout: $e');
      rethrow;
    }
  }

  Future<void> endWorkout(String logId) async {
    try {
      await Supabase.instance.client.from('workout_logs').update({
        'end_time': DateTime.now().toIso8601String(),
      }).eq('id', logId);
    } catch (e) {
      print('Error ending workout: $e');
      rethrow;
    }
  }

  Future<void> logSet(String logId, WorkoutSet set) async {
    try {
      await Supabase.instance.client
          .from('workout_sets')
          .insert(set.toJson()..addAll({'log_id': logId}));
    } catch (e) {
      print('Error logging set: $e');
      rethrow;
    }
  }

  Future<List<WorkoutLog>> getUserWorkoutHistory(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('workout_logs')
          .select('*, sets(*)')
          .eq('id', userId)
          .order('start_time', ascending: false);

      return (response as List<dynamic>)
          .map((log) => WorkoutLog.fromJson(log as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting workout history: $e');
      rethrow;
    }
  }
}
