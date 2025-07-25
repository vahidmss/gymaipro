import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/workout_program_log.dart';

class WorkoutProgramLogService {
  final _tableName = 'workout_program_logs';

  WorkoutProgramLogService();

  Future<List<WorkoutProgramLog>> getUserProgramLogs(String userId) async {
    try {
      final client = Supabase.instance.client;

      final data = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false);

      return data.map((log) => WorkoutProgramLog.fromJson(log)).toList();
    } catch (e) {
      debugPrint('Error fetching workout program logs: $e');
      return [];
    }
  }

  Future<WorkoutProgramLog?> saveProgramLog(WorkoutProgramLog log) async {
    try {
      final client = Supabase.instance.client;

      // تولید UUID برای تمام فیلدهای id
      final logWithIds = _ensureValidUuids(log);

      // بررسی آیا برای این برنامه و روز، رکوردی در همان روز وجود دارد
      final logDate = logWithIds.logDate;

      // جستجوی لاگ‌های امروز با همین نام برنامه
      final existingLogs = await client
          .from(_tableName)
          .select()
          .eq('user_id', logWithIds.userId)
          .eq('program_name', logWithIds.programName)
          .eq('log_date',
              logWithIds.logDate.toIso8601String().substring(0, 10));

      if (existingLogs.isNotEmpty) {
        // لاگ قبلی وجود دارد - به‌روزرسانی آن
        debugPrint('آپدیت لاگ موجود به جای ایجاد لاگ جدید');
        final existingLog = WorkoutProgramLog.fromJson(existingLogs.first);

        // ادغام سشن‌های موجود با سشن‌های جدید
        final Map<String, WorkoutSessionLog> mergedSessions = {};

        // ابتدا سشن‌های موجود را اضافه می‌کنیم
        for (final session in existingLog.sessions) {
          mergedSessions[session.day] = session;
        }

        // سپس سشن‌های جدید را اضافه/به‌روزرسانی می‌کنیم
        for (final newSession in logWithIds.sessions) {
          if (mergedSessions.containsKey(newSession.day)) {
            // این سشن قبلاً وجود داشته - تمرین‌های جدید را به آن اضافه می‌کنیم
            final existingSession = mergedSessions[newSession.day]!;
            final Map<String, WorkoutExerciseLog> mergedExercises = {};

            // ابتدا تمرین‌های موجود را اضافه می‌کنیم
            for (final exercise in existingSession.exercises) {
              if (exercise is NormalExerciseLog) {
                mergedExercises['${exercise.exerciseId}'] = exercise;
              }
            }

            // سپس تمرین‌های جدید را اضافه/به‌روزرسانی می‌کنیم
            for (final newExercise in newSession.exercises) {
              if (newExercise is NormalExerciseLog) {
                final key = '${newExercise.exerciseId}';
                mergedExercises[key] = newExercise;
              }
            }

            // سشن به‌روزرسانی شده را ایجاد می‌کنیم
            mergedSessions[newSession.day] = WorkoutSessionLog(
              id: existingSession.id,
              day: existingSession.day,
              exercises: mergedExercises.values.toList(),
            );
          } else {
            // این یک سشن جدید است
            mergedSessions[newSession.day] = newSession;
          }
        }

        // لاگ به‌روزرسانی شده را ایجاد می‌کنیم
        final updatedLog = WorkoutProgramLog(
          id: existingLog.id,
          userId: existingLog.userId,
          programName: existingLog.programName,
          logDate: existingLog.logDate,
          sessions: mergedSessions.values.toList(),
          createdAt: existingLog.createdAt,
          updatedAt: DateTime.now(),
        );

        // به‌روزرسانی لاگ در دیتابیس
        await client
            .from(_tableName)
            .update(updatedLog.toJson())
            .eq('id', updatedLog.id);

        return updatedLog;
      } else {
        // رکورد جدید ایجاد می‌کنیم
        debugPrint('ایجاد لاگ جدید برای برنامه ${logWithIds.programName}');
        final data = await client
            .from(_tableName)
            .insert(logWithIds.toJson())
            .select()
            .single();

        return WorkoutProgramLog.fromJson({
          ...data,
          'log_date': logWithIds.logDate.toIso8601String().substring(0, 10),
        });
      }
    } catch (e) {
      debugPrint('خطا در ذخیره لاگ تمرین: $e');
      if (e is PostgrestException) {
        debugPrint(
            'جزئیات خطای Postgrest: ${e.code}, ${e.details}, ${e.message}');
      }
      return null;
    }
  }

  // تولید UUID برای تمام فیلدهای id که خالی هستند
  WorkoutProgramLog _ensureValidUuids(WorkoutProgramLog log) {
    final mainId = log.id.isEmpty
        ? DateTime.now().millisecondsSinceEpoch.toString()
        : log.id;

    // کپی کردن جلسات با تولید id های جدید
    final updatedSessions = log.sessions.map((session) {
      final sessionId = session.id.isEmpty
          ? DateTime.now().millisecondsSinceEpoch.toString()
          : session.id;

      // کپی کردن تمرین‌ها با تولید id های جدید
      final updatedExercises = session.exercises.map((exercise) {
        final exerciseId = exercise.id.isEmpty
            ? DateTime.now().millisecondsSinceEpoch.toString()
            : exercise.id;

        if (exercise is NormalExerciseLog) {
          return NormalExerciseLog(
            id: exerciseId,
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.exerciseName,
            tag: exercise.tag,
            style: exercise.style,
            sets: exercise.sets,
          );
        } else if (exercise is SupersetExerciseLog) {
          return SupersetExerciseLog(
            id: exerciseId,
            tag: exercise.tag,
            style: exercise.style,
            exercises: exercise.exercises,
          );
        } else {
          return exercise;
        }
      }).toList();

      return WorkoutSessionLog(
        id: sessionId,
        day: session.day,
        exercises: updatedExercises,
      );
    }).toList();

    return WorkoutProgramLog(
      id: mainId,
      userId: log.userId,
      programName: log.programName,
      logDate: log.logDate,
      sessions: updatedSessions,
      createdAt: log.createdAt,
      updatedAt: log.updatedAt,
    );
  }

  Future<bool> updateProgramLog(WorkoutProgramLog log) async {
    try {
      final client = Supabase.instance.client;

      await client.from(_tableName).update(log.toJson()).eq('id', log.id);

      return true;
    } catch (e) {
      debugPrint('Error updating workout program log: $e');
      return false;
    }
  }

  Future<bool> deleteProgramLog(String logId) async {
    try {
      final client = Supabase.instance.client;

      await client.from(_tableName).delete().eq('id', logId);

      return true;
    } catch (e) {
      debugPrint('Error deleting workout program log: $e');
      return false;
    }
  }

  Future<List<WorkoutProgramLog>> getLogsByProgramName(
      String userId, String programName) async {
    try {
      final client = Supabase.instance.client;

      final data = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('program_name', programName)
          .order('created_at', ascending: false);

      return data.map((log) => WorkoutProgramLog.fromJson(log)).toList();
    } catch (e) {
      debugPrint('Error fetching workout program logs: $e');
      return [];
    }
  }
}
