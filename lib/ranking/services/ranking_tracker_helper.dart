import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/services/activity_tracking_service.dart';

/// Helper برای ردیابی خودکار فعالیت‌ها در جاهای مختلف اپ
/// این کلاس به صورت خودکار فعالیت‌ها را ردیابی می‌کند
class RankingTrackerHelper {
  static final RankingTrackerHelper _instance =
      RankingTrackerHelper._internal();
  factory RankingTrackerHelper() => _instance;
  RankingTrackerHelper._internal();

  final ActivityTrackingService _activityService = ActivityTrackingService();

  /// ردیابی خواندن مقاله (فراخوانی از صفحه مقاله)
  /// باید هر 5 دقیقه یکبار فراخوانی شود
  Future<void> trackArticleReading({int minutes = 5}) async {
    try {
      await _activityService.incrementArticleReadingTime(minutes);
      debugPrint('✅ Tracked article reading: $minutes minutes');
    } catch (e) {
      debugPrint('❌ Error tracking article reading: $e');
    }
  }

  /// ردیابی گوش دادن به موزیک (فراخوانی از MusicPlayerService)
  /// باید هر 10 دقیقه یکبار فراخوانی شود
  Future<void> trackMusicListening({int minutes = 10}) async {
    try {
      await _activityService.incrementMusicListeningTime(minutes);
      debugPrint('✅ Tracked music listening: $minutes minutes');
    } catch (e) {
      debugPrint('❌ Error tracking music listening: $e');
    }
  }

  /// ردیابی تماشای ویدیو (فراخوانی از صفحه ویدیو)
  /// باید هر 5 دقیقه یکبار فراخوانی شود
  Future<void> trackVideoWatching({int minutes = 5}) async {
    try {
      await _activityService.incrementVideoWatchingTime(minutes);
      debugPrint('✅ Tracked video watching: $minutes minutes');
    } catch (e) {
      debugPrint('❌ Error tracking video watching: $e');
    }
  }

  /// ردیابی ثبت تمرین (فراخوانی هنگام ثبت تمرین)
  Future<void> trackWorkoutLog() async {
    try {
      await _activityService.incrementWorkoutLogs();
      debugPrint('✅ Tracked workout log');
    } catch (e) {
      debugPrint('❌ Error tracking workout log: $e');
    }
  }

  /// ردیابی ثبت رژیم (فراخوانی هنگام ثبت وعده)
  Future<void> trackMealLog() async {
    try {
      await _activityService.incrementMealLogs();
      debugPrint('✅ Tracked meal log');
    } catch (e) {
      debugPrint('❌ Error tracking meal log: $e');
    }
  }

  /// ردیابی کالری‌شماری (فراخوانی هنگام ثبت کالری)
  Future<void> trackCalorieCounting() async {
    try {
      await _activityService.markCalorieCounting();
      debugPrint('✅ Tracked calorie counting');
    } catch (e) {
      debugPrint('❌ Error tracking calorie counting: $e');
    }
  }
}
