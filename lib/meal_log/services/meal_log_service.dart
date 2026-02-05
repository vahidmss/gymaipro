import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:gymaipro/meal_log/models/food_log.dart';
import 'package:gymaipro/ranking/services/ranking_service.dart';
import 'package:gymaipro/ranking/services/ranking_tracker_helper.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MealLogService {
  MealLogService();
  final String _tableName = 'food_logs';

  /// در این پروژه food_logs.user_id به profiles.id اشاره دارد (نه auth.users.id)
  Future<String?> _getCurrentUserId() async {
    final profile = await SimpleProfileService.getCurrentProfile();
    if (profile != null) {
      final id = profile['id'] as String?;
      if (id != null && id.isNotEmpty) return id;
    }
    return Supabase.instance.client.auth.currentUser?.id;
  }

  /// Get food log for a specific date
  Future<FoodLog?> getLogForDate(DateTime date) async {
    try {
      final client = Supabase.instance.client;
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final dateString = date.toIso8601String().substring(0, 10);

      // If offline, skip network and return local
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        return await loadLogLocal(date);
      }

      // Get log for specific date
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .eq('log_date', dateString)
          .maybeSingle();

      if (response != null) {
        return FoodLog.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting food log for date: $e');
      return null;
    }
  }

  /// Save food log for a specific date
  Future<void> saveLog(FoodLog log) async {
    try {
      final client = Supabase.instance.client;
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final logJson = log.toJson();
      final dateString = log.logDate.toIso8601String().substring(0, 10);

      // If offline, save locally and return
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        await saveLogLocal(log);
        return;
      }

      // Retry mechanism for network operations
      int retryCount = 0;
      const maxRetries = 3;
      bool success = false;
      Map<String, dynamic>? existing;

      // Check if log exists for this date (with retry)
      while (!success && retryCount < maxRetries) {
        try {
          existing = await client
              .from(_tableName)
              .select('id')
              .eq('user_id', userId)
              .eq('log_date', dateString)
              .maybeSingle();
          success = true;
        } catch (e) {
          retryCount++;
          final errorString = e.toString();
          final isNetworkError =
              errorString.contains('SocketException') ||
              errorString.contains('ClientException') ||
              errorString.contains('Connection reset') ||
              errorString.contains('Connection refused');

          if (isNetworkError && retryCount < maxRetries) {
            debugPrint(
              'Network error checking existing log (attempt $retryCount/$maxRetries): $e',
            );
            await Future<void>.delayed(Duration(seconds: retryCount * 2));
          } else {
            // If it's not a network error or max retries reached, save locally and rethrow
            debugPrint('Error checking existing log: $e');
            await saveLogLocal(log);
            rethrow;
          }
        }
      }

      // Retry mechanism for update/insert operations
      retryCount = 0;
      success = false;

      while (!success && retryCount < maxRetries) {
        try {
          if (existing != null) {
            // Update existing log
            await client
                .from(_tableName)
                .update({
                  'meals': logJson['meals'],
                  'updated_at': DateTime.now().toIso8601String(),
                })
                .eq('id', existing['id'] as String);
            // ردیابی برای امتیاز رتبه‌بندی (وعده به روز موجود اضافه شده)
            try {
              await RankingTrackerHelper().trackMealLog();
              RankingService().updateCurrentUserRanking();
            } catch (_) {}
          } else {
            // Insert new log
            await client.from(_tableName).insert({
              'user_id': userId,
              'log_date': dateString,
              'meals': logJson['meals'],
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            });
          }
          success = true;
          // ردیابی برای امتیاز رتبه‌بندی: فعالیت روزانه + روزهای فعال + به‌روزرسانی امتیاز کل
          try {
            await RankingTrackerHelper().trackMealLog();
            RankingService().updateCurrentUserRanking();
          } catch (_) {}
        } catch (e) {
          retryCount++;
          final errorString = e.toString();
          final isNetworkError =
              errorString.contains('SocketException') ||
              errorString.contains('ClientException') ||
              errorString.contains('Connection reset') ||
              errorString.contains('Connection refused');

          if (isNetworkError && retryCount < maxRetries) {
            debugPrint(
              'Network error saving log (attempt $retryCount/$maxRetries): $e',
            );
            await Future<void>.delayed(Duration(seconds: retryCount * 2));
          } else {
            // If it's not a network error or max retries reached, save locally and rethrow
            debugPrint('Error saving food log: $e');
            await saveLogLocal(log);
            rethrow;
          }
        }
      }
    } catch (e) {
      debugPrint('Error saving food log: $e');
      // Save locally as fallback
      try {
        await saveLogLocal(log);
      } catch (localError) {
        debugPrint('Error saving log locally: $localError');
      }
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
    return FoodLog.fromJson(jsonMap as Map<String, dynamic>);
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
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final client = Supabase.instance.client;
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final startDateString = startDate.toIso8601String().substring(0, 10);
      final endDateString = endDate.toIso8601String().substring(0, 10);

      // If offline, return local aggregate (best-effort)
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        final dates = await listLocalLogDates();
        final inRange = dates.where(
          (d) =>
              !d.isBefore(DateTime.parse(startDateString)) &&
              !d.isAfter(DateTime.parse(endDateString)),
        );
        final logs = <FoodLog>[];
        for (final d in inRange) {
          final l = await loadLogLocal(d);
          if (l != null) logs.add(l);
        }
        return logs;
      }

      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .gte('log_date', startDateString)
          .lte('log_date', endDateString)
          .order('log_date');

      return response.map(FoodLog.fromJson).toList();
    } catch (e) {
      debugPrint('Error getting food logs for date range: $e');
      return [];
    }
  }

  /// Delete food log for a specific date
  Future<void> deleteLogForDate(DateTime date) async {
    try {
      final client = Supabase.instance.client;
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final dateString = date.toIso8601String().substring(0, 10);

      // If offline, remove local copy and return
      final isOnline = await ConnectivityService.instance.checkNow();
      if (!isOnline) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('food_log_ $dateString');
        return;
      }

      await client
          .from(_tableName)
          .delete()
          .eq('user_id', userId)
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
      final userId = await _getCurrentUserId();
      if (userId == null) throw Exception('User not authenticated');

      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('log_date', ascending: false);

      return response.map(FoodLog.fromJson).toList();
    } catch (e) {
      debugPrint('Error getting all food logs: $e');
      return [];
    }
  }

  /// Get nutrition summary for a date range
  Future<Map<String, double>> getNutritionSummary(
    DateTime startDate,
    DateTime endDate,
  ) async {
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
      return {'calories': 0, 'protein': 0, 'carbs': 0, 'fat': 0};
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
        final log = FoodLog.fromJson(jsonMap as Map<String, dynamic>);
        await saveLog(log);
        await prefs.remove(key);
      }
    }
  }
}
