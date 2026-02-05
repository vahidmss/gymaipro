import 'package:flutter/foundation.dart';
import 'package:gymaipro/services/models/point_history.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت امتیاز کاربر
/// امتیازها را در دیتابیس Supabase ذخیره می‌کند
class ScoreService extends ChangeNotifier {
  factory ScoreService() => _instance;
  ScoreService._internal();
  static final ScoreService _instance = ScoreService._internal();

  final String _tableName = 'point_history';
  int _score = 0;
  final List<PointHistory> _history = [];

  /// امتیاز فعلی کاربر
  int get score => _score;

  /// تاریخچه امتیازات کسب شده
  List<PointHistory> get history => List.unmodifiable(_history);

  /// تاریخچه مرتب شده بر اساس تاریخ (جدیدترین اول)
  List<PointHistory> get sortedHistory {
    final sorted = List<PointHistory>.from(_history);
    sorted.sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
    return sorted;
  }

  /// تعداد کل امتیازات کسب شده از دستاوردها
  int get achievementPoints {
    return _history
        .where((h) => h.source == PointSource.achievement)
        .fold(0, (sum, h) => sum + h.points);
  }

  /// تعداد دستاوردهای باز شده
  int get unlockedAchievementsCount {
    return _history.where((h) => h.source == PointSource.achievement).length;
  }

  /// مقداردهی اولیه - بارگذاری از دیتابیس
  Future<void> init() async {
    await loadFromDatabase();
  }

  /// بارگذاری امتیازها از دیتابیس
  Future<void> loadFromDatabase() async {
    try {
      final client = Supabase.instance.client;
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;

      if (profileId == null || profileId.isEmpty) {
        debugPrint('⚠️ User not authenticated, cannot load scores');
        return;
      }

      // بارگذاری تاریخچه از دیتابیس
      final response = await client
          .from(_tableName)
          .select()
          .eq('user_id', profileId)
          .order('earned_at', ascending: false);

      _history.clear();
      _score = 0;

      for (final item in response) {
        try {
          final historyItem = PointHistory.fromJson(item);
          _history.add(historyItem);
          _score += historyItem.points;
        } catch (e) {
          debugPrint('❌ Error parsing point history item: $e');
        }
      }

      notifyListeners();
      debugPrint('✅ Loaded ${_history.length} point history items from database');
    } catch (e) {
      debugPrint('❌ Error loading scores from database: $e');
    }
  }

  /// افزودن امتیاز با ثبت در تاریخچه و دیتابیس
  Future<void> addScore(
    int points, {
    PointSource source = PointSource.other,
    String? sourceId,
    String? sourceTitle,
    String? sourceIcon,
    String? description,
  }) async {
    _score += points;

    // ثبت در تاریخچه
    final historyItem = PointHistory(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      points: points,
      source: source,
      sourceId: sourceId,
      sourceTitle: sourceTitle ?? 'امتیاز کسب شده',
      sourceIcon: sourceIcon ?? '⭐',
      earnedAt: DateTime.now(),
      description: description,
    );

    _history.add(historyItem);
    notifyListeners();

    // ذخیره در دیتابیس
    await _saveToDatabase(historyItem);
  }

  /// افزودن امتیاز از دستاورد
  /// این متد خودش بررسی می‌کند که آیا این دستاورد قبلاً امتیاز داده شده یا نه
  Future<bool> addAchievementPoints({
    required String achievementId,
    required String achievementTitle,
    required String achievementIcon,
    required int points,
    String? description,
  }) async {
    // ابتدا بررسی از تاریخچه محلی
    if (hasAchievementPoints(achievementId)) {
      debugPrint('⚠️ Achievement points already added locally: $achievementId');
      return false;
    }

    // بررسی از دیتابیس برای اطمینان
    final existsInDatabase = await _checkAchievementPointsInDatabase(achievementId);
    if (existsInDatabase) {
      debugPrint('⚠️ Achievement points already exist in database: $achievementId');
      // بارگذاری مجدد از دیتابیس برای همگام‌سازی
      await loadFromDatabase();
      return false;
    }

    // اضافه کردن امتیاز
    await addScore(
      points,
      source: PointSource.achievement,
      sourceId: achievementId,
      sourceTitle: achievementTitle,
      sourceIcon: achievementIcon,
      description: description ?? 'دستاورد: $achievementTitle',
    );
    
    debugPrint('✅ Achievement points added: $achievementTitle (+$points points)');
    return true;
  }

  /// بررسی از دیتابیس که آیا این دستاورد قبلاً امتیاز داده شده یا نه
  Future<bool> _checkAchievementPointsInDatabase(String achievementId) async {
    try {
      final client = Supabase.instance.client;
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;

      if (profileId == null || profileId.isEmpty) {
        return false;
      }

      final response = await client
          .from(_tableName)
          .select('id')
          .eq('user_id', profileId)
          .eq('source', PointSource.achievement.name)
          .eq('source_id', achievementId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      debugPrint('❌ Error checking achievement points in database: $e');
      return false;
    }
  }

  /// ذخیره یک آیتم تاریخچه در دیتابیس
  Future<void> _saveToDatabase(PointHistory item) async {
    try {
      final client = Supabase.instance.client;
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;

      if (profileId == null || profileId.isEmpty) {
        debugPrint('⚠️ User not authenticated, cannot save score');
        return;
      }

      await client.from(_tableName).insert({
        'id': item.id,
        'user_id': profileId,
        'points': item.points,
        'source': item.source.name,
        'source_id': item.sourceId,
        'source_title': item.sourceTitle,
        'source_icon': item.sourceIcon,
        'earned_at': item.earnedAt.toIso8601String(),
        'description': item.description,
        'created_at': DateTime.now().toIso8601String(),
      });

      debugPrint('✅ Saved point history to database: ${item.id}');
    } catch (e) {
      debugPrint('❌ Error saving point history to database: $e');
    }
  }

  /// تنظیم امتیاز (بدون ثبت در تاریخچه)
  void setScore(int points) {
    _score = points;
    notifyListeners();
  }

  /// کاهش امتیاز
  void subtractScore(int points) {
    _score = (_score - points).clamp(0, double.infinity).toInt();
    notifyListeners();
  }

  /// ریست کردن امتیاز و تاریخچه
  void resetScore() {
    _score = 0;
    _history.clear();
    notifyListeners();
  }

  /// دریافت تاریخچه بر اساس منبع
  List<PointHistory> getHistoryBySource(PointSource source) {
    return _history.where((h) => h.source == source).toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  /// دریافت تاریخچه بر اساس بازه زمانی
  List<PointHistory> getHistoryByDateRange({
    DateTime? startDate,
    DateTime? endDate,
  }) {
    final now = DateTime.now();
    final start = startDate ?? DateTime(1970);
    final end = endDate ?? now;

    return _history
        .where((h) => h.earnedAt.isAfter(start) && h.earnedAt.isBefore(end))
        .toList()
      ..sort((a, b) => b.earnedAt.compareTo(a.earnedAt));
  }

  /// بررسی اینکه آیا امتیاز از یک دستاورد خاص قبلاً اضافه شده یا نه
  bool hasAchievementPoints(String achievementId) {
    return _history.any(
      (h) => h.source == PointSource.achievement && h.sourceId == achievementId,
    );
  }
}

