import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/ranking/models/ranking_score_breakdown.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/services/models/point_history.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// امتیاز فعالیت کاربر برای رتبه‌بندی و لیگ (جدول user_rankings).
/// ستارهٔ دستاوردها جداست و در AchievementService مدیریت می‌شود.
class ScoreService extends ChangeNotifier {
  factory ScoreService() => _instance;
  ScoreService._internal();
  static final ScoreService _instance = ScoreService._internal();

  int _score = 0;
  List<PointHistory> _activityEntries = [];
  bool _isLoadingFromDatabase = false;
  bool _isLoading = false;
  String? _lastLoadError;
  DateTime? _lastDatabaseLoadAt;
  static const Duration _databaseLoadCooldown = Duration(seconds: 30);

  bool get isLoading => _isLoading;
  String? get lastLoadError => _lastLoadError;

  /// امتیاز فعالیت (همان total_score در لیگ)
  int get score => _score;

  /// همان [score] — برای خوانایی در UI
  int get rankingScore => _score;

  /// ردیف‌های تفکیک امتیاز فعالیت
  List<PointHistory> get activityEntries => List.unmodifiable(_activityEntries);

  /// @deprecated فقط برای سازگاری؛ دیگر تاریخچهٔ دستاورد نگه نمی‌داریم.
  List<PointHistory> get history => activityEntries;

  List<PointHistory> get sortedActivityEntries {
    final sorted = List<PointHistory>.from(_activityEntries);
    sorted.sort((a, b) => b.points.compareTo(a.points));
    return sorted;
  }

  Future<void> init() async {
    await loadFromDatabase();
  }

  Future<void> loadFromDatabase({bool force = false}) async {
    final now = DateTime.now();
    if (_isLoadingFromDatabase) {
      if (kDebugMode) {
        debugPrint('ℹ️ Activity score load skipped (already in progress)');
      }
      return;
    }
    if (!force &&
        _lastDatabaseLoadAt != null &&
        now.difference(_lastDatabaseLoadAt!) < _databaseLoadCooldown) {
      if (kDebugMode) {
        debugPrint('ℹ️ Activity score load skipped (cooldown active)');
      }
      return;
    }

    _isLoadingFromDatabase = true;
    _isLoading = true;
    _lastLoadError = null;
    _lastDatabaseLoadAt = now;
    notifyListeners();

    try {
      final client = Supabase.instance.client;
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;

      if (profileId == null || profileId.isEmpty) {
        _lastLoadError = 'پروفایل کاربر یافت نشد';
        return;
      }

      final previousScore = _score;
      final previousEntries = List<PointHistory>.from(_activityEntries);

      try {
        final rankingService = RankingScoreService();
        final breakdown =
            await rankingService.getScoreBreakdown(profileId);
        final computedScore = breakdown?.totalScore ?? 0;
        var loadedScore = await _loadRankingScore(client, profileId);

        if (computedScore > loadedScore) {
          loadedScore = computedScore;
          unawaited(rankingService.updateUserScore(profileId));
        }

        _score = loadedScore;
        _activityEntries = breakdown != null
            ? _activityEntriesFromBreakdown(breakdown)
            : <PointHistory>[];
        _lastLoadError = null;
        debugPrint(
          '✅ Activity score loaded: $_score (${_activityEntries.length} sources)',
        );
      } catch (e) {
        _score = previousScore;
        _activityEntries = previousEntries;
        _lastLoadError = 'خطا در بارگذاری امتیاز فعالیت';
        debugPrint('❌ Error loading activity score: $e');
      }

      notifyListeners();
    } catch (e) {
      _lastLoadError = 'خطا در بارگذاری امتیازات';
      debugPrint('❌ Error loading activity score: $e');
      notifyListeners();
    } finally {
      _isLoadingFromDatabase = false;
      _isLoading = false;
      notifyListeners();
    }
  }

  void resetScore() {
    _score = 0;
    _activityEntries = [];
    _lastLoadError = null;
    notifyListeners();
  }

  Future<int> _loadRankingScore(
    SupabaseClient client,
    String profileId,
  ) async {
    final row = await client
        .from('user_rankings')
        .select('total_score')
        .eq('user_id', profileId)
        .maybeSingle();
    return (row?['total_score'] as num?)?.toInt() ?? 0;
  }

  static List<PointHistory> _activityEntriesFromBreakdown(
    RankingScoreBreakdown b,
  ) {
    final base = DateTime(2000);
    var i = 0;
    PointHistory row({
      required String key,
      required int points,
      required PointSource source,
      required String title,
      required String icon,
      required String description,
    }) {
      return PointHistory(
        id: 'ranking_$key',
        points: points,
        source: source,
        sourceId: 'ranking_$key',
        sourceTitle: title,
        sourceIcon: icon,
        earnedAt: base.add(Duration(days: i++)),
        description: description,
      );
    }

    return <PointHistory>[
      if (b.currentStreakScore > 0)
        row(
          key: 'current_streak',
          points: b.currentStreakScore,
          source: PointSource.dailyCheckIn,
          title: 'زنجیره فعالیت فعلی',
          icon: '🔥',
          description: '${b.currentStreak} روز متوالی',
        ),
      if (b.longestStreakScore > 0)
        row(
          key: 'longest_streak',
          points: b.longestStreakScore,
          source: PointSource.dailyCheckIn,
          title: 'بهترین زنجیره فعالیت',
          icon: '🏆',
          description: '${b.longestStreak} روز',
        ),
      if (b.activeDaysScore > 0)
        row(
          key: 'active_days',
          points: b.activeDaysScore,
          source: PointSource.dailyCheckIn,
          title: 'روزهای فعال (۳۰ روز اخیر)',
          icon: '📅',
          description: '${b.activeDays} روز فعال',
        ),
      if (b.dailyActivitiesScore > 0)
        row(
          key: 'daily_activity',
          points: b.dailyActivitiesScore,
          source: PointSource.other,
          title: 'فعالیت روزانه',
          icon: '⚡',
          description: 'جمع فعالیت‌های ۳۰ روز گذشته',
        ),
      if (b.totalWorkoutsScore > 0)
        row(
          key: 'workouts',
          points: b.totalWorkoutsScore,
          source: PointSource.workout,
          title: 'ثبت تمرین',
          icon: '💪',
          description: '${b.totalWorkouts} جلسه تمرین',
        ),
      if (b.totalMealsScore > 0)
        row(
          key: 'meals',
          points: b.totalMealsScore,
          source: PointSource.nutrition,
          title: 'ثبت تغذیه',
          icon: '🍽️',
          description: '${b.totalMeals} وعده',
        ),
      if (b.articlesReadScore > 0)
        row(
          key: 'articles',
          points: b.articlesReadScore,
          source: PointSource.other,
          title: 'مطالعه مقالات',
          icon: '📚',
          description: '${b.articlesReadCount} مقاله',
        ),
    ];
  }
}
