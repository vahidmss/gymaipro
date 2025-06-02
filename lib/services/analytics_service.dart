import 'dart:convert';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import '../models/workout_log.dart';
import 'workout_log_service.dart';

class AnalyticsService {
  final WorkoutLogService _workoutLogService;

  AnalyticsService({WorkoutLogService? workoutLogService})
      : _workoutLogService = workoutLogService ?? WorkoutLogService();

  // Export workout logs as JSON file
  Future<String> exportWorkoutLogsAsJson(String userId,
      {WorkoutLogFilter? filter, String? fileName}) async {
    try {
      // Fetch logs with the JSON structure
      final logs = await _workoutLogService.getWorkoutLogsForAnalytics(
        userId,
        filter: filter,
      );

      if (logs.isEmpty) {
        debugPrint('No workout logs found to export');
        return '';
      }

      // Create JSON string
      final jsonString = jsonEncode(logs);

      // Get temp directory
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/${fileName ?? 'workout_logs.json'}';

      // Write to file
      final file = File(filePath);
      await file.writeAsString(jsonString);

      return filePath;
    } catch (e) {
      debugPrint('Error exporting workout logs: $e');
      rethrow;
    }
  }

  // Generate analytics summary of workout logs
  Future<Map<String, dynamic>> generateWorkoutAnalyticsSummary(String userId,
      {WorkoutLogFilter? filter}) async {
    try {
      final logs = await _workoutLogService.getUserLogs(
        userId,
        filter: filter,
      );

      if (logs.isEmpty) {
        return {
          'total_workouts': 0,
          'total_exercises': 0,
          'total_sets': 0,
          'total_duration': 0,
          'most_trained_muscle': 'N/A',
          'favorite_exercise': 'N/A',
        };
      }

      // Calculate various metrics
      final totalWorkouts = logs.length;
      final exerciseIds = <String>{};
      var totalSets = 0;
      var totalDuration = 0;

      // Track muscle groups and exercises
      final muscleGroups = <String, int>{};
      final exercises = <String, int>{};

      for (final log in logs) {
        exerciseIds.add(log.exerciseId);
        totalSets += log.sets.length;

        if (log.durationSeconds != null) {
          totalDuration += log.durationSeconds!;
        }

        // Track muscle groups
        if (log.exerciseTag != null) {
          muscleGroups[log.exerciseTag!] =
              (muscleGroups[log.exerciseTag!] ?? 0) + 1;
        }

        // Track exercises
        if (log.exerciseName != null) {
          exercises[log.exerciseName!] =
              (exercises[log.exerciseName!] ?? 0) + 1;
        }
      }

      // Find most trained muscle group
      String mostTrainedMuscle = 'N/A';
      int maxMuscleCount = 0;
      muscleGroups.forEach((muscle, count) {
        if (count > maxMuscleCount) {
          maxMuscleCount = count;
          mostTrainedMuscle = muscle;
        }
      });

      // Find favorite exercise
      String favoriteExercise = 'N/A';
      int maxExerciseCount = 0;
      exercises.forEach((exercise, count) {
        if (count > maxExerciseCount) {
          maxExerciseCount = count;
          favoriteExercise = exercise;
        }
      });

      return {
        'total_workouts': totalWorkouts,
        'total_exercises': exerciseIds.length,
        'total_sets': totalSets,
        'total_duration': totalDuration,
        'most_trained_muscle': mostTrainedMuscle,
        'favorite_exercise': favoriteExercise,
        'muscle_groups': muscleGroups,
        'exercises': exercises,
      };
    } catch (e) {
      debugPrint('Error generating workout analytics: $e');
      return {'error': e.toString()};
    }
  }
}
