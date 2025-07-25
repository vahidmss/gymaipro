import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/food_log.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class MealLogService {
  final String _tableName = 'food_logs';

  MealLogService();

  /// Get food log for a specific date (from logs array in single user row)
  Future<FoodLog?> getLogForDate(DateTime date) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final dateString = date.toIso8601String().substring(0, 10);

      // فقط یک رکورد برای کاربر وجود دارد
      final response = await client
          .from(_tableName)
          .select('logs')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null && response['logs'] != null) {
        final List logs = response['logs'];
        final logMap = logs.firstWhere(
          (entry) => entry['log_date'] == dateString,
          orElse: () => null,
        );
        if (logMap != null) {
          return FoodLog.fromJson(logMap);
        }
      }
      return null;
    } catch (e) {
      debugPrint('Error getting food log for date: $e');
      return null;
    }
  }

  /// Save food log for a specific date (all logs in a jsonb array, one row per user)
  Future<void> saveLog(FoodLog log) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // 1. دریافت رکورد کاربر
      final existing = await client
          .from(_tableName)
          .select('id, logs')
          .eq('user_id', user.id)
          .maybeSingle();

      final logJson = log
          .toJson(); // باید فقط داده یک روز باشد (log_date, meals, supplements, ...)
      final dateString = log.logDate.toIso8601String().substring(0, 10);

      if (existing != null && existing['id'] != null) {
        // 2. اگر رکورد وجود داشت، آرایه logs را آپدیت کن
        List logs = List.from(existing['logs'] ?? []);
        // حذف روز قبلی (اگر وجود داشت)
        logs.removeWhere((entry) => entry['log_date'] == dateString);
        // اضافه کردن روز جدید
        logs.add(logJson);
        // آپدیت کل آرایه logs
        await client.from(_tableName).update({
          'logs': logs,
          'updated_at': DateTime.now().toIso8601String()
        }).eq('id', existing['id']);
      } else {
        // 3. اگر رکورد نبود، یک سطر جدید بساز
        await client.from(_tableName).insert({
          'user_id': user.id,
          'logs': [logJson],
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        });
      }
    } catch (e) {
      debugPrint('Error saving food log: $e');
      rethrow;
    }
  }

  /// Save food log locally for a specific date
  Future<void> saveLogLocal(FoodLog log) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = log.logDate.toIso8601String().substring(0, 10);
    await prefs.setString('food_log_ $dateString', jsonEncode(log.toJson()));
  }

  /// Load food log locally for a specific date
  Future<FoodLog?> loadLogLocal(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = date.toIso8601String().substring(0, 10);
    final jsonStr = prefs.getString('food_log_ $dateString');
    if (jsonStr == null) return null;
    final jsonMap = jsonDecode(jsonStr);
    return FoodLog.fromJson(jsonMap);
  }

  /// Save last selected session for a date
  Future<void> saveLastSessionLocal(DateTime date, int session) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = date.toIso8601String().substring(0, 10);
    await prefs.setInt('food_log_last_session_ $dateString', session);
  }

  /// Load last selected session for a date
  Future<int?> loadLastSessionLocal(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = date.toIso8601String().substring(0, 10);
    return prefs.getInt('food_log_last_session_ $dateString');
  }

  /// Save last selected plan for a date
  Future<void> saveLastPlanLocal(DateTime date, String planId) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = date.toIso8601String().substring(0, 10);
    await prefs.setString('food_log_last_plan_ $dateString', planId);
  }

  /// Load last selected plan for a date
  Future<String?> loadLastPlanLocal(DateTime date) async {
    final prefs = await SharedPreferences.getInstance();
    final dateString = date.toIso8601String().substring(0, 10);
    return prefs.getString('food_log_last_plan_ $dateString');
  }

  /// Get food logs for a date range
  Future<List<FoodLog>> getLogsForDateRange(
      DateTime startDate, DateTime endDate) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final startDateString = startDate.toIso8601String().substring(0, 10);
      final endDateString = endDate.toIso8601String().substring(0, 10);

      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .gte('log_date', startDateString)
          .lte('log_date', endDateString)
          .order('log_date');

      return response.map((json) => FoodLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting food logs for date range: $e');
      return [];
    }
  }

  /// Delete food log for a specific date
  Future<void> deleteLogForDate(DateTime date) async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final dateString = date.toIso8601String().substring(0, 10);

      await client
          .from(_tableName)
          .delete()
          .eq('user_id', user.id)
          .eq('log_date', dateString);
    } catch (e) {
      debugPrint('Error deleting food log: $e');
      rethrow;
    }
  }

  /// Get all food logs for current user
  Future<List<FoodLog>> getAllLogs() async {
    try {
      final client = Supabase.instance.client;
      final user = client.auth.currentUser;

      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', user.id)
          .order('log_date', ascending: false);

      return response.map((json) => FoodLog.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error getting all food logs: $e');
      return [];
    }
  }

  /// Get nutrition summary for a date range
  Future<Map<String, double>> getNutritionSummary(
      DateTime startDate, DateTime endDate) async {
    try {
      final logs = await getLogsForDateRange(startDate, endDate);

      double totalCalories = 0;
      double totalProtein = 0;
      double totalCarbs = 0;
      double totalFat = 0;

      for (final log in logs) {
        for (final meal in log.meals) {
          for (final foodItem in meal.foods) {
            // Note: This would need food data to calculate nutrition
            // For now, return placeholder values
            totalCalories += foodItem.amount * 0.1; // Placeholder calculation
            totalProtein += foodItem.amount * 0.02; // Placeholder calculation
            totalCarbs += foodItem.amount * 0.05; // Placeholder calculation
            totalFat += foodItem.amount * 0.01; // Placeholder calculation
          }
        }
      }

      return {
        'calories': totalCalories,
        'protein': totalProtein,
        'carbs': totalCarbs,
        'fat': totalFat,
      };
    } catch (e) {
      debugPrint('Error getting nutrition summary: $e');
      return {
        'calories': 0,
        'protein': 0,
        'carbs': 0,
        'fat': 0,
      };
    }
  }

  /// List all locally saved food log dates
  Future<List<DateTime>> listLocalLogDates() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final logKeys = keys.where((k) => k.startsWith('food_log_ ')).toList();
    return logKeys
        .map((k) {
          final dateStr = k.substring('food_log_ '.length);
          return DateTime.tryParse(dateStr) ?? DateTime(2000);
        })
        .where((d) => d.year > 2000)
        .toList();
  }

  /// Sync all local logs to database and remove them from local
  Future<void> syncAllLocalLogsToDatabase() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys();
    final logKeys = keys.where((k) => k.startsWith('food_log_ ')).toList();
    for (final key in logKeys) {
      final jsonStr = prefs.getString(key);
      if (jsonStr != null) {
        final jsonMap = jsonDecode(jsonStr);
        final log = FoodLog.fromJson(jsonMap);
        await saveLog(log);
        await prefs.remove(key);
      }
    }
  }
}
