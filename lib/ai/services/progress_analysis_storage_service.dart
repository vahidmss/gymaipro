import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/models/progress_analysis.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت ذخیره‌سازی تحلیل‌های پیشرفت
class ProgressAnalysisStorageService {
  static const String _analysesKey = 'progress_analyses';
  static const String _currentAnalysisKey = 'progress_analysis_current';
  final SupabaseClient _supabase = Supabase.instance.client;
  final String _tableName = 'progress_analyses';

  /// ذخیره تحلیل در حافظه داخلی
  Future<void> saveAnalysisLocally(ProgressAnalysis analysis) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // دریافت لیست تحلیل‌های موجود
      final analysesJson = prefs.getString(_analysesKey);
      final List<Map<String, dynamic>> analyses = analysesJson != null
          ? (jsonDecode(analysesJson) as List<dynamic>)
              .map((e) => e as Map<String, dynamic>)
              .toList()
          : [];

      // اضافه کردن تحلیل جدید به ابتدای لیست
      analyses.insert(0, analysis.toLocalMap());

      // نگه داشتن فقط آخرین 10 تحلیل در حافظه داخلی
      final limitedAnalyses = analyses.take(10).toList();

      // ذخیره در SharedPreferences
      await prefs.setString(
        _analysesKey,
        jsonEncode(limitedAnalyses),
      );

      // ذخیره تحلیل فعلی
      await prefs.setString(
        _currentAnalysisKey,
        jsonEncode(analysis.toLocalMap()),
      );

      if (kDebugMode) {
        print('Progress Analysis: Saved locally: ${analysis.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving analysis locally: $e');
      }
    }
  }

  /// ذخیره تحلیل در دیتابیس
  Future<void> saveAnalysisToDatabase(ProgressAnalysis analysis) async {
    try {
      await _supabase.from(_tableName).insert(analysis.toJson());

      if (kDebugMode) {
        print('Progress Analysis: Saved to database: ${analysis.id}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('Error saving analysis to database: $e');
      }
      rethrow;
    }
  }

  /// ذخیره تحلیل در هر دو مکان (حافظه داخلی و دیتابیس)
  Future<void> saveAnalysis(ProgressAnalysis analysis) async {
    // ذخیره در حافظه داخلی (همیشه)
    await saveAnalysisLocally(analysis);

    // ذخیره در دیتابیس (در صورت اتصال)
    try {
      await saveAnalysisToDatabase(analysis);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to save to database, but saved locally: $e');
      }
      // ادامه می‌دهیم حتی اگر دیتابیس خطا بدهد
    }
  }

  /// دریافت تحلیل‌های از حافظه داخلی
  Future<List<ProgressAnalysis>> getLocalAnalyses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analysesJson = prefs.getString(_analysesKey);

      if (analysesJson == null) {
        return [];
      }

      final analysesList = jsonDecode(analysesJson) as List<dynamic>;
      return analysesList
          .map((e) => ProgressAnalysis.fromLocalMap(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting local analyses: $e');
      }
      return [];
    }
  }

  /// دریافت تحلیل‌های از دیتابیس
  Future<List<ProgressAnalysis>> getDatabaseAnalyses({
    int? limit,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        return [];
      }

      var query = _supabase
          .from(_tableName)
          .select()
          .eq('user_id', userId)
          .order('analysis_date', ascending: false);

      if (limit != null) {
        query = query.limit(limit);
      }

      final response = await query;
      return (response as List<dynamic>)
          .map((e) => ProgressAnalysis.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('Error getting database analyses: $e');
      }
      return [];
    }
  }

  /// دریافت تحلیل فعلی از حافظه داخلی
  Future<ProgressAnalysis?> getCurrentAnalysis() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentJson = prefs.getString(_currentAnalysisKey);

      if (currentJson == null) {
        return null;
      }

      final currentMap = jsonDecode(currentJson) as Map<String, dynamic>;
      return ProgressAnalysis.fromLocalMap(currentMap);
    } catch (e) {
      if (kDebugMode) {
        print('Error getting current analysis: $e');
      }
      return null;
    }
  }

  /// دریافت تمام تحلیل‌ها (اول از دیتابیس، اگر نبود از حافظه داخلی)
  Future<List<ProgressAnalysis>> getAllAnalyses() async {
    // اول تلاش می‌کنیم از دیتابیس بگیریم
    final databaseAnalyses = await getDatabaseAnalyses();
    
    if (databaseAnalyses.isNotEmpty) {
      // ذخیره در حافظه داخلی برای دسترسی سریع‌تر
      final prefs = await SharedPreferences.getInstance();
      final limited = databaseAnalyses.take(10).toList();
      await prefs.setString(
        _analysesKey,
        jsonEncode(limited.map((a) => a.toLocalMap()).toList()),
      );
      return databaseAnalyses;
    }

    // اگر دیتابیس خالی بود، از حافظه داخلی بگیر
    return getLocalAnalyses();
  }

  /// حذف تحلیل از حافظه داخلی
  Future<void> deleteLocalAnalysis(String analysisId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final analyses = await getLocalAnalyses();
      final updated = analyses.where((a) => a.id != analysisId).toList();

      await prefs.setString(
        _analysesKey,
        jsonEncode(updated.map((a) => a.toLocalMap()).toList()),
      );
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting local analysis: $e');
      }
    }
  }

  /// حذف تحلیل از دیتابیس
  Future<void> deleteDatabaseAnalysis(String analysisId) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', analysisId);
    } catch (e) {
      if (kDebugMode) {
        print('Error deleting database analysis: $e');
      }
      rethrow;
    }
  }

  /// حذف تحلیل از هر دو مکان
  Future<void> deleteAnalysis(String analysisId) async {
    await deleteLocalAnalysis(analysisId);
    try {
      await deleteDatabaseAnalysis(analysisId);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to delete from database: $e');
      }
    }
  }

  /// پاک کردن تمام تحلیل‌های محلی
  Future<void> clearLocalAnalyses() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_analysesKey);
      await prefs.remove(_currentAnalysisKey);
    } catch (e) {
      if (kDebugMode) {
        print('Error clearing local analyses: $e');
      }
    }
  }

  /// دریافت آخرین تحلیل بر اساس دوره زمانی
  Future<ProgressAnalysis?> getLatestAnalysisByPeriod(int periodDays) async {
    try {
      // اول از دیتابیس بگیریم
      final userId = _supabase.auth.currentUser?.id;
      if (userId != null) {
        try {
          final response = await _supabase
              .from(_tableName)
              .select()
              .eq('user_id', userId)
              .eq('period_days', periodDays)
              .order('analysis_date', ascending: false)
              .limit(1)
              .maybeSingle();

          if (response != null) {
            return ProgressAnalysis.fromJson(
                Map<String, dynamic>.from(response as Map));
          }
        } catch (e) {
          if (kDebugMode) {
            print('Error getting analysis from database: $e');
          }
        }
      }

      // اگر از دیتابیس پیدا نشد، از حافظه داخلی بگیریم
      final localAnalyses = await getLocalAnalyses();
      final matchingAnalysis = localAnalyses
          .where((a) => a.periodDays == periodDays)
          .toList()
        ..sort((a, b) => b.analysisDate.compareTo(a.analysisDate));

      return matchingAnalysis.isNotEmpty ? matchingAnalysis.first : null;
    } catch (e) {
      if (kDebugMode) {
        print('Error getting latest analysis by period: $e');
      }
      return null;
    }
  }
}

