import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/config/ai_engine_config.dart';
import 'package:gymaipro/ai/models/ai_chat_message.dart';
import 'package:gymaipro/ai/models/progress_analysis.dart';
import 'package:gymaipro/ai/services/openai_service.dart';
import 'package:gymaipro/ai/services/rule_based_progress_analysis_engine.dart';
import 'package:gymaipro/ai/services/progress_analysis_limit_service.dart';
import 'package:gymaipro/ai/services/progress_analysis_storage_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/weekly_weight_service.dart';
import 'package:gymaipro/workout_log/models/workout_program_log.dart';
import 'package:gymaipro/workout_log/services/workout_program_log_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس تحلیل پیشرفت با هوش مصنوعی
class AIProgressAnalysisService {
  final OpenAIService _openAIService = OpenAIService();
  final WorkoutDailyLogService _workoutLogService = WorkoutDailyLogService();
  final ProgressAnalysisStorageService _storageService =
      ProgressAnalysisStorageService();
  final ProgressAnalysisLimitService _limitService =
      ProgressAnalysisLimitService();

  /// دریافت تحلیل پیشرفت کاربر
  Future<ProgressAnalysis> analyzeProgress({
    int? days = 30, // تعداد روزهای گذشته برای تحلیل
  }) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        throw Exception('کاربر لاگین نشده است');
      }

      // بررسی محدودیت استفاده
      final limitCheck = await _limitService.canUseAnalysis();
      if (!limitCheck.canUse) {
        throw ProgressAnalysisLimitException(
          limitCheck.message ?? 'محدودیت استفاده',
        );
      }

      // جمع‌آوری داده‌ها
      final progressData = await _collectProgressData(userId, days ?? 30);
      final analysisText = await _generateAnalysisText(progressData);

      final analysis = ProgressAnalysis(
        userId: userId,
        analysisResult: analysisText,
        periodDays: days ?? 30,
        analysisDate: DateTime.now(),
      );

      // ذخیره تحلیل
      await _storageService.saveAnalysis(analysis);

      // ثبت استفاده (فقط بعد از ذخیره موفقیت‌آمیز تحلیل)
      try {
        await _limitService.recordUsage();
      } catch (e) {
        // اگر ثبت استفاده خطا داد، تحلیل را ذخیره کرده‌ایم اما استفاده ثبت نشده
        // این حالت نباید رخ دهد، اما برای اطمینان لاگ می‌کنیم
        if (kDebugMode) {
          print('Warning: Analysis saved but usage not recorded: $e');
        }
        // تحلیل را برمی‌گردانیم چون ذخیره شده است
      }

      return analysis;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تحلیل پیشرفت: $e');
      }
      if (e is ProgressAnalysisLimitException) {
        rethrow;
      }
      throw Exception('خطا در تحلیل پیشرفت: $e');
    }
  }

  /// بررسی محدودیت استفاده
  Future<ProgressAnalysisLimitResult> checkLimit() async {
    return _limitService.canUseAnalysis();
  }

  /// دریافت آمار استفاده
  Future<ProgressAnalysisLimitStats> getUsageStats() async {
    return _limitService.getUsageStats();
  }

  Future<String> _generateAnalysisText(Map<String, dynamic> progressData) async {
    if (!AiEngineConfig.canAttemptOpenAi) {
      return RuleBasedProgressAnalysisEngine().buildReport(progressData);
    }
    try {
      final prompt = _buildAnalysisPrompt(progressData);
      final response = await _openAIService.sendMessage(
        messages: [ChatMessage.user(content: prompt)],
        systemPrompt: _getSystemPrompt(),
      );
      return response.content;
    } catch (e) {
      if (kDebugMode) {
        print('OpenAI progress analysis failed, using local engine: $e');
      }
      return RuleBasedProgressAnalysisEngine().buildReport(progressData);
    }
  }

  /// جمع‌آوری داده‌های پیشرفت
  Future<Map<String, dynamic>> _collectProgressData(
    String userId,
    int days,
  ) async {
    final endDate = DateTime.now();
    final startDate = endDate.subtract(Duration(days: days));

    // دریافت لاگ‌های تمرینات
    final workoutLogs = await _workoutLogService.getLogsByDateRange(
      userId,
      startDate,
      endDate,
    );

    // دریافت تاریخچه وزن
    final weightHistory = await WeeklyWeightService.getFullWeightHistory(
      userId,
    );
    final weightStats = await WeeklyWeightService.getWeightStats(userId);

    // دریافت اطلاعات پروفایل و اندازه‌گیری‌های بدن
    final profileData = await _getUserProfile(userId);
    final bodyMeasurements = await _getBodyMeasurements(userId);

    // محاسبه آمار تمرینات
    final workoutStats = _calculateWorkoutStats(workoutLogs);

    return {
      'period_days': days,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'workout_stats': workoutStats,
      'weight_history': weightHistory.take(20).toList(), // آخرین 20 رکورد
      'weight_stats': weightStats,
      'body_measurements': bodyMeasurements,
      'profile': profileData,
    };
  }

  /// محاسبه آمار تمرینات
  Map<String, dynamic> _calculateWorkoutStats(List<WorkoutDailyLog> logs) {
    if (logs.isEmpty) {
      return {
        'total_workouts': 0,
        'total_sessions': 0,
        'total_exercises': 0,
        'average_workouts_per_week': 0.0,
        'workout_days': <String>[],
      };
    }

    int totalSessions = 0;
    int totalExercises = 0;
    final workoutDays = <String>[];

    for (final log in logs) {
      workoutDays.add(log.logDate.toIso8601String().substring(0, 10));
      totalSessions += log.sessions.length;
      for (final session in log.sessions) {
        totalExercises += session.exercises.length;
      }
    }

    final daysDiff = logs.first.logDate.difference(logs.last.logDate).inDays;
    final weeks = daysDiff > 0 ? daysDiff / 7.0 : 1.0;
    final avgWorkoutsPerWeek = logs.length / weeks;

    return {
      'total_workouts': logs.length,
      'total_sessions': totalSessions,
      'total_exercises': totalExercises,
      'average_workouts_per_week': avgWorkoutsPerWeek,
      'workout_days': workoutDays,
    };
  }

  /// دریافت اطلاعات پروفایل کاربر
  Future<Map<String, dynamic>> _getUserProfile(String userId) async {
    try {
      final response = await ProfileRepository.instance.fetchProfile(userId);
      return response ?? {};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت پروفایل: $e');
      }
      return {};
    }
  }

  /// دریافت اندازه‌گیری‌های بدن
  Future<Map<String, dynamic>> _getBodyMeasurements(String userId) async {
    try {
      final response = await Supabase.instance.client
          .from('confidential_user_info')
          .select('body_measurements')
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null && response['body_measurements'] != null) {
        final bm = response['body_measurements'];
        if (bm is Map) {
          return Map<String, dynamic>.from(bm);
        } else if (bm is String) {
          try {
            final decoded = jsonDecode(bm) as Map<String, dynamic>;
            return Map<String, dynamic>.from(decoded);
          } catch (_) {
            return {};
          }
        }
      }
      return {};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت اندازه‌گیری‌های بدن: $e');
      }
      return {};
    }
  }

  /// ساخت prompt برای تحلیل
  String _buildAnalysisPrompt(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    buffer.writeln(
      'لطفاً پیشرفت من را در ${data['period_days']} روز گذشته تحلیل کن.',
    );
    buffer.writeln();

    // آمار تمرینات
    final workoutStats = data['workout_stats'] as Map<String, dynamic>;
    buffer.writeln('📊 آمار تمرینات:');
    buffer.writeln('- تعداد کل تمرینات: ${workoutStats['total_workouts']}');
    buffer.writeln('- تعداد جلسات: ${workoutStats['total_sessions']}');
    buffer.writeln('- تعداد تمرینات: ${workoutStats['total_exercises']}');
    buffer.writeln(
      '- میانگین تمرینات در هفته: ${(workoutStats['average_workouts_per_week'] as num).toStringAsFixed(1)}',
    );
    buffer.writeln();

    // آمار وزن
    final weightStats = data['weight_stats'] as Map<String, dynamic>;
    if (weightStats['total_records'] as int > 0) {
      buffer.writeln('⚖️ آمار وزن:');
      buffer.writeln('- تعداد رکوردها: ${weightStats['total_records']}');
      buffer.writeln(
        '- میانگین وزن: ${(weightStats['average_weight'] as num).toStringAsFixed(1)} کیلوگرم',
      );
      buffer.writeln(
        '- کمترین وزن: ${(weightStats['min_weight'] as num).toStringAsFixed(1)} کیلوگرم',
      );
      buffer.writeln(
        '- بیشترین وزن: ${(weightStats['max_weight'] as num).toStringAsFixed(1)} کیلوگرم',
      );
      buffer.writeln('- روند: ${weightStats['trend']}');
      buffer.writeln();
    }

    // تاریخچه وزن (آخرین 10 رکورد)
    final weightHistory = data['weight_history'] as List<dynamic>;
    if (weightHistory.isNotEmpty) {
      buffer.writeln('📈 تاریخچه وزن (آخرین ${weightHistory.length} رکورد):');
      for (final record in weightHistory.take(10)) {
        final recordMap = record as Map<String, dynamic>;
        final date = recordMap['recorded_at'] as String? ?? '';
        final weight = recordMap['weight'] as num? ?? 0;
        buffer.writeln('- $date: ${weight.toStringAsFixed(1)} کیلوگرم');
      }
      buffer.writeln();
    }

    // اندازه‌گیری‌های بدن
    final bodyMeasurements = data['body_measurements'] as Map<String, dynamic>;
    if (bodyMeasurements.isNotEmpty) {
      buffer.writeln('📏 اندازه‌گیری‌های بدن:');
      if (bodyMeasurements['weight'] != null) {
        buffer.writeln(
          '- وزن: ${(bodyMeasurements['weight'] as num).toStringAsFixed(1)} کیلوگرم',
        );
      }
      if (bodyMeasurements['height'] != null) {
        buffer.writeln(
          '- قد: ${(bodyMeasurements['height'] as num).toStringAsFixed(1)} سانتی‌متر',
        );
      }
      if (bodyMeasurements['body_fat_percentage'] != null) {
        buffer.writeln(
          '- درصد چربی بدن: ${(bodyMeasurements['body_fat_percentage'] as num).toStringAsFixed(1)}%',
        );
      }
      if (bodyMeasurements['muscle_mass'] != null) {
        buffer.writeln(
          '- توده عضلانی: ${(bodyMeasurements['muscle_mass'] as num).toStringAsFixed(1)} کیلوگرم',
        );
      }
      buffer.writeln();
    }

    buffer.writeln(
      'لطفاً تحلیل جامعی از پیشرفت من ارائه بده و راهکارهای عملی برای بهبود پیشنهاد کن.',
    );

    return buffer.toString();
  }

  /// دریافت system prompt
  String _getSystemPrompt() {
    return '''
تو یک مربی ورزشی و متخصص تغذیه حرفه‌ای هستی. وظیفه تو تحلیل پیشرفت کاربر و ارائه راهکارهای عملی و کاربردی است.

در تحلیل خود:
1. نقاط قوت و پیشرفت‌های کاربر را برجسته کن
2. نقاط ضعف و نیاز به بهبود را شناسایی کن
3. راهکارهای عملی و قابل اجرا ارائه بده
4. انگیزه‌بخش و مثبت باش
5. از اصطلاحات تخصصی به صورت ساده استفاده کن
6. پاسخ را به فارسی و با لحن دوستانه و حرفه‌ای بنویس

ساختار پاسخ:
- خلاصه پیشرفت
- نقاط قوت
- نقاط قابل بهبود
- راهکارهای پیشنهادی
- انگیزه و تشویق''';
  }
}

/// استثنای محدودیت تحلیل پیشرفت
class ProgressAnalysisLimitException implements Exception {
  ProgressAnalysisLimitException(this.message);
  final String message;

  @override
  String toString() => message;
}
