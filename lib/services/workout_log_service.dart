import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_log.dart';
import 'supabase_service.dart';

class WorkoutLogService {
  final SupabaseService _supabaseService;
  final String _tableName = 'workout_logs';

  WorkoutLogService({SupabaseService? supabaseService})
      : _supabaseService = supabaseService ?? SupabaseService();

  /// Get all workout logs for a user with optional filtering
  Future<List<WorkoutLog>> getUserLogs(String userId,
      {WorkoutLogFilter? filter}) async {
    try {
      final client = Supabase.instance.client;
      var query = client.from(_tableName).select().eq('user_id', userId);

      // Apply filters if provided
      if (filter != null) {
        if (filter.startDate != null) {
          query = query.gte('created_at', filter.startDate!.toIso8601String());
        }
        if (filter.endDate != null) {
          query = query.lte('created_at', filter.endDate!.toIso8601String());
        }
        if (filter.programId != null) {
          query = query.eq('workout_data->>program_id', filter.programId!);
        }
        if (filter.exerciseTag != null) {
          query = query.eq('workout_data->>exercise_tag', filter.exerciseTag!);
        }
        if (filter.exerciseName != null) {
          query = query.ilike(
              'workout_data->>exercise_name', '%${filter.exerciseName}%');
        }
      }

      final data = await query.order('created_at', ascending: false);
      return data.map((log) => WorkoutLog.fromJson(log)).toList();
    } catch (e) {
      debugPrint('Error fetching workout logs: $e');
      return [];
    }
  }

  /// Save a new workout log to the database
  Future<WorkoutLog?> saveWorkoutLog(WorkoutLog log) async {
    try {
      final client = Supabase.instance.client;
      final data =
          await client.from(_tableName).insert(log.toJson()).select().single();
      return WorkoutLog.fromJson(data);
    } catch (e) {
      debugPrint('Error saving workout log: $e');
      return null;
    }
  }

  /// Update an existing workout log
  Future<bool> updateWorkoutLog(WorkoutLog log) async {
    try {
      final client = Supabase.instance.client;
      await client.from(_tableName).update(log.toJson()).eq('id', log.id);
      return true;
    } catch (e) {
      debugPrint('Error updating workout log: $e');
      return false;
    }
  }

  /// Delete a workout log by ID
  Future<bool> deleteWorkoutLog(String logId) async {
    try {
      final client = Supabase.instance.client;
      await client.from(_tableName).delete().eq('id', logId);
      return true;
    } catch (e) {
      debugPrint('Error deleting workout log: $e');
      return false;
    }
  }

  /// Get all logs for a specific workout program
  Future<List<WorkoutLog>> getLogsByProgram(
      String userId, String programId) async {
    final filter = WorkoutLogFilter(programId: programId);
    return getUserLogs(userId, filter: filter);
  }

  /// Get all logs for a specific exercise
  Future<List<WorkoutLog>> getLogsByExercise(
      String userId, String exerciseId) async {
    try {
      final client = Supabase.instance.client;
      final data = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('workout_data->>exercise_id', exerciseId)
          .order('created_at', ascending: false);

      return data.map((log) => WorkoutLog.fromJson(log)).toList();
    } catch (e) {
      debugPrint('Error fetching workout logs by exercise: $e');
      return [];
    }
  }

  /// Get workout logs in a format suitable for analytics
  Future<List<Map<String, dynamic>>> getWorkoutLogsForAnalytics(String userId,
      {WorkoutLogFilter? filter}) async {
    try {
      final logs = await getUserLogs(userId, filter: filter);
      return logs.map((log) => log.toFullJson()).toList();
    } catch (e) {
      debugPrint('Error fetching workout logs for analytics: $e');
      return [];
    }
  }
}
