import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// Save daily log - saves to both database and cache
  Future<WorkoutDailyLog?> saveDailyLog(WorkoutDailyLog log) async {
    try {
      final updatedLog = WorkoutDailyLog(
        id: log.id,
        userId: log.userId,
        logDate: log.logDate,
        sessions: log.sessions,
        createdAt: log.createdAt,
        updatedAt: DateTime.now(),
      );

      // Save to cache first (instant)
      await saveLogLocal(updatedLog);

      // Then save to database
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
          final dbUpdatedLog = WorkoutDailyLog(
            id: existingLog.id,
            userId: log.userId,
            logDate: log.logDate,
            sessions: log.sessions,
            createdAt: existingLog.createdAt,
            updatedAt: DateTime.now(),
          );

          await Supabase.instance.client
              .from(_tableName)
              .update(dbUpdatedLog.toJson())
              .eq('id', dbUpdatedLog.id);

          // Update cache with database response
          await saveLogLocal(dbUpdatedLog);
          return dbUpdatedLog;
        } else {
          // Create new log
          final validatedLog = _ensureValidUuids(updatedLog);
          final response = await Supabase.instance.client
              .from(_tableName)
              .insert(validatedLog.toJson())
              .select()
              .single();

          final dbLog = WorkoutDailyLog.fromJson(response);
          // Update cache with database response
          await saveLogLocal(dbLog);
          return dbLog;
        }
      } catch (e) {
        debugPrint('Error saving to database (cache is still saved): $e');
        // Cache is already saved, return cached version
        return updatedLog;
      }
    } catch (e) {
      debugPrint('Error saving daily log: $e');
      return null;
    }
  }

  /// Get daily log for a specific date - Cache-first strategy
  /// First loads from cache (instant), then updates from database in background
  Future<WorkoutDailyLog?> getDailyLogByDate(
    String userId,
    DateTime date, {
    bool preferRemote = false,
  }) async {
    try {
      final dateString = date.toIso8601String().substring(0, 10);

      if (!preferRemote) {
        // First, try to load from cache (instant)
        final cachedLog = await loadLogLocal(userId, date);
        if (cachedLog != null) {
          // Update from database in background (non-blocking)
          _updateFromDatabaseInBackground(userId, date, cachedLog);
          return cachedLog;
        }
      }

      // If not in cache, load from database
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateString)
          .maybeSingle();

      if (response != null) {
        final log = WorkoutDailyLog.fromJson(response);
        // Save to cache for next time
        await saveLogLocal(log);
        return log;
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching daily log by date: $e');
      // If database fails, try cache as fallback
      return loadLogLocal(userId, date);
    }
  }

  /// Update cache from database in background (non-blocking)
  Future<void> _updateFromDatabaseInBackground(
    String userId,
    DateTime date,
    WorkoutDailyLog cachedLog,
  ) async {
    try {
      final dateString = date.toIso8601String().substring(0, 10);
      final response = await Supabase.instance.client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateString)
          .maybeSingle();

      if (response != null) {
        final dbLog = WorkoutDailyLog.fromJson(response);
        // Only update cache if database version is newer
        if (dbLog.updatedAt.isAfter(cachedLog.updatedAt)) {
          await saveLogLocal(dbLog);
        }
      }
    } catch (e) {
      debugPrint('Error updating cache from database: $e');
      // Silently fail - cache is still valid
    }
  }

  /// Delete daily log - deletes from both database and cache
  Future<bool> deleteDailyLog(String logId) async {
    try {
      // First get the log to know which cache entry to delete
      final logResponse = await Supabase.instance.client
          .from(_tableName)
          .select('user_id, log_date')
          .eq('id', logId)
          .maybeSingle();

      // Delete from database
      await Supabase.instance.client.from(_tableName).delete().eq('id', logId);

      // Delete from cache if we found the log
      if (logResponse != null) {
        final userId = logResponse['user_id'] as String?;
        final logDateStr = logResponse['log_date'] as String?;
        if (userId != null && logDateStr != null) {
          final logDate = DateTime.parse(logDateStr);
          await deleteLogLocal(userId, logDate);
        }
      }

      return true;
    } catch (e) {
      debugPrint('Error deleting daily log: $e');
      return false;
    }
  }

  /// Update daily log - updates both database and cache
  Future<bool> updateDailyLog(WorkoutDailyLog log) async {
    try {
      final updatedLog = WorkoutDailyLog(
        id: log.id,
        userId: log.userId,
        logDate: log.logDate,
        sessions: log.sessions,
        createdAt: log.createdAt,
        updatedAt: DateTime.now(),
      );

      // Update cache first (instant)
      await saveLogLocal(updatedLog);

      // Then update database
      try {
        await Supabase.instance.client
            .from(_tableName)
            .update(updatedLog.toJson())
            .eq('id', log.id);
        return true;
      } catch (e) {
        debugPrint('Error updating database (cache is still updated): $e');
        // Cache is already updated, return true
        return true;
      }
    } catch (e) {
      debugPrint('Error updating daily log: $e');
      return false;
    }
  }

  /// Save workout log locally (cache) for a specific date
  Future<void> saveLogLocal(WorkoutDailyLog log) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = log.logDate.toIso8601String().substring(0, 10);
      final key = 'workout_log_${log.userId}_$dateString';
      await prefs.setString(key, jsonEncode(log.toJson()));
    } catch (e) {
      debugPrint('Error saving workout log to cache: $e');
    }
  }

  /// Load workout log locally (cache) for a specific date
  Future<WorkoutDailyLog?> loadLogLocal(String userId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = date.toIso8601String().substring(0, 10);
      final key = 'workout_log_${userId}_$dateString';
      final jsonStr = prefs.getString(key);
      if (jsonStr == null) return null;
      final jsonMap = jsonDecode(jsonStr) as Map<String, dynamic>;
      return WorkoutDailyLog.fromJson(jsonMap);
    } catch (e) {
      debugPrint('Error loading workout log from cache: $e');
      return null;
    }
  }

  /// Delete workout log from cache
  Future<void> deleteLogLocal(String userId, DateTime date) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dateString = date.toIso8601String().substring(0, 10);
      final key = 'workout_log_${userId}_$dateString';
      await prefs.remove(key);
    } catch (e) {
      debugPrint('Error deleting workout log from cache: $e');
    }
  }

  /// Clear all workout log cache for a user
  Future<void> clearAllCache(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final cacheKeys = keys.where((k) => 
        k.startsWith('workout_log_${userId}_')
      ).toList();
      
      for (final key in cacheKeys) {
        await prefs.remove(key);
      }
      debugPrint('Cleared ${cacheKeys.length} workout log cache entries');
    } catch (e) {
      debugPrint('Error clearing workout log cache: $e');
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
            note: exercise.note,
          );
        } else if (exercise is SupersetExerciseLog) {
          return SupersetExerciseLog(
            id: exercise.id.isEmpty ? const Uuid().v4() : exercise.id,
            tag: exercise.tag,
            style: exercise.style,
            exercises: exercise.exercises,
            note: exercise.note,
          );
        }
        return exercise;
      }).toList();

      return WorkoutSessionLog(
        id: session.id.isEmpty ? const Uuid().v4() : session.id,
        day: session.day,
        exercises: exercises,
        notes: session.notes,
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
