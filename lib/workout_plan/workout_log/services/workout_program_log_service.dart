import 'package:flutter/material.dart';
import 'package:gymaipro/workout_plan/workout_log/models/workout_program_log.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

class WorkoutDailyLogService {
  WorkoutDailyLogService();
  final _tableName = 'workout_daily_logs';

  Future<List<WorkoutDailyLog>> getUserDailyLogs(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false);

      return response.map(WorkoutDailyLog.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching user daily logs: $e');
      return [];
    }
  }

  Future<WorkoutDailyLog?> saveDailyLog(WorkoutDailyLog log) async {
    try {
      // Check if a log already exists for this date
      final existingLogs = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', log.userId)
          .eq('log_date', log.logDate.toIso8601String().substring(0, 10));

      if (existingLogs.isNotEmpty) {
        // Update existing log
        final existingLog = WorkoutDailyLog.fromJson(existingLogs.first);
        final updatedLog = WorkoutDailyLog(
          id: existingLog.id,
          userId: log.userId,
          logDate: log.logDate,
          sessions: log.sessions,
          createdAt: existingLog.createdAt,
          updatedAt: DateTime.now(),
        );

        await Supabase.instance.client
            .from(_tableName)
            .update(updatedLog.toJson())
            .eq('id', updatedLog.id);

        return updatedLog;
      } else {
        // Create new log
        final validatedLog = _ensureValidUuids(log);
        final response = await Supabase.instance.client
            .from(_tableName)
            .insert(validatedLog.toJson())
            .select()
            .single();

        return WorkoutDailyLog.fromJson(response);
      }
    } catch (e) {
      debugPrint('Error saving daily log: $e');
      return null;
    }
  }

  Future<WorkoutDailyLog?> getDailyLogByDate(
    String userId,
    DateTime date,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('log_date', date.toIso8601String().substring(0, 10))
          .maybeSingle();

      if (response != null) {
        return WorkoutDailyLog.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching daily log by date: $e');
      return null;
    }
  }

  Future<bool> deleteDailyLog(String logId) async {
    try {
      await Supabase.instance.client.from(_tableName).delete().eq('id', logId);
      return true;
    } catch (e) {
      debugPrint('Error deleting daily log: $e');
      return false;
    }
  }

  Future<bool> updateDailyLog(WorkoutDailyLog log) async {
    try {
      await Supabase.instance.client
          .from(_tableName)
          .update(log.toJson())
          .eq('id', log.id);
      return true;
    } catch (e) {
      debugPrint('Error updating daily log: $e');
      return false;
    }
  }

  Future<List<WorkoutDailyLog>> getLogsByDateRange(
    String userId,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('log_date', startDate.toIso8601String().substring(0, 10))
          .lte('log_date', endDate.toIso8601String().substring(0, 10))
          .order('log_date', ascending: false);

      return response.map(WorkoutDailyLog.fromJson).toList();
    } catch (e) {
      debugPrint('Error fetching logs by date range: $e');
      return [];
    }
  }

  WorkoutDailyLog _ensureValidUuids(WorkoutDailyLog log) {
    // Ensure all nested objects have valid UUIDs
    final sessions = log.sessions.map((session) {
      final exercises = session.exercises.map((exercise) {
        if (exercise is NormalExerciseLog) {
          return NormalExerciseLog(
            id: exercise.id.isEmpty ? const Uuid().v4() : exercise.id,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            tag: exercise.tag,
            style: exercise.style,
            sets: exercise.sets,
          );
        } else if (exercise is SupersetExerciseLog) {
          return SupersetExerciseLog(
            id: exercise.id.isEmpty ? const Uuid().v4() : exercise.id,
            tag: exercise.tag,
            style: exercise.style,
            exercises: exercise.exercises,
          );
        }
        return exercise;
      }).toList();

      return WorkoutSessionLog(
        id: session.id.isEmpty ? const Uuid().v4() : session.id,
        day: session.day,
        exercises: exercises,
      );
    }).toList();

    return WorkoutDailyLog(
      id: log.id.isEmpty ? const Uuid().v4() : log.id,
      userId: log.userId,
      logDate: log.logDate,
      sessions: sessions,
      createdAt: log.createdAt,
      updatedAt: log.updatedAt,
    );
  }
}
