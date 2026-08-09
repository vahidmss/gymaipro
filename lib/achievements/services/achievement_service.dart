import 'package:flutter/foundation.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/services/achievement_database_service.dart';
import 'package:gymaipro/achievements/widgets/achievement_notification.dart';
import 'package:gymaipro/main.dart';
import 'package:gymaipro/ranking/services/ranking_score_service.dart';
import 'package:gymaipro/services/score_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';

class AchievementService extends ChangeNotifier {
  /// Backwards-compatible factory: `AchievementService()` returns the shared instance.
  factory AchievementService() => instance;
  AchievementService._internal() {
    _initializeAchievements();
    _loadUserProgress();
  }

  /// Single shared instance across the app.
  static final AchievementService instance = AchievementService._internal();

  final AchievementDatabaseService _databaseService =
      AchievementDatabaseService();
  List<Achievement> _achievements = [];
  bool _isLoading = false;
  bool _isRefreshingFromDatabase = false;
  DateTime? _lastDatabaseRefreshAt;
  static const Duration _databaseRefreshCooldown = Duration(seconds: 45);

  List<Achievement> get achievements => _achievements;

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  /// مجموع بونوس لیگ تعریف‌شده برای دستاوردهای بازشده (از کاتالوگ)
  int get totalUnlockedRewardPoints => unlockedAchievements.fold(
        0,
        (sum, a) => sum + a.points,
      );

  int get totalPossiblePoints =>
      _achievements.fold(0, (sum, a) => sum + a.points);

  double get completionPercentage {
    if (_achievements.isEmpty) return 0;
    return (unlockedAchievements.length / _achievements.length) * 100;
  }

  Map<AchievementCategory, List<Achievement>> get achievementsByCategory {
    final Map<AchievementCategory, List<Achievement>> grouped = {};
    for (final achievement in _achievements) {
      grouped.putIfAbsent(achievement.category, () => []).add(achievement);
    }
    return grouped;
  }

  void _initializeAchievements() {
    // فقط دستاوردهایی که در اپ سیم‌کشی شده‌اند — ویترین قفل‌شده ممنوع.
    _achievements = [
      // === استفاده از اپ ===
      Achievement(
        id: 'profile_complete',
        title: 'تکمیل پروفایل',
        description: 'پروفایل خود را ۱۰۰٪ تکمیل کنید',
        icon: '👤',
        category: AchievementCategory.platform,
        targetValue: 100,
        currentValue: 0,
        unit: 'درصد',
        points: 50,
      ),
      Achievement(
        id: 'first_login',
        title: 'خوش آمدید',
        description: 'برای اولین بار وارد شوید',
        icon: '👋',
        category: AchievementCategory.platform,
        targetValue: 1,
        currentValue: 0,
        unit: 'ورود',
        points: 20,
      ),
      Achievement(
        id: 'membership_10_days',
        title: '۱۰ روز با ما',
        description: '۱۰ روز از تاریخ عضویت شما می‌گذرد',
        icon: '📅',
        category: AchievementCategory.platform,
        targetValue: 10,
        currentValue: 0,
        unit: 'روز',
        points: 40,
      ),
      Achievement(
        id: 'membership_30_days',
        title: '۳۰ روز با ما',
        description: '۳۰ روز از تاریخ عضویت شما می‌گذرد',
        icon: '📆',
        category: AchievementCategory.platform,
        targetValue: 30,
        currentValue: 0,
        unit: 'روز',
        points: 100,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'membership_90_days',
        title: '۹۰ روز با ما',
        description: '۹۰ روز از تاریخ عضویت شما می‌گذرد',
        icon: '🗓️',
        category: AchievementCategory.platform,
        targetValue: 90,
        currentValue: 0,
        unit: 'روز',
        points: 200,
        tier: AchievementTier.gold,
      ),
      Achievement(
        id: 'membership_1_year',
        title: 'یک سال با ما',
        description: 'یک سال کامل از تاریخ عضویت شما می‌گذرد',
        icon: '🎂',
        category: AchievementCategory.platform,
        targetValue: 365,
        currentValue: 0,
        unit: 'روز',
        points: 500,
        tier: AchievementTier.platinum,
      ),
      Achievement(
        id: 'streak_3_days',
        title: '۳ روز پشت سر هم',
        description: '۳ روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 3,
        currentValue: 0,
        unit: 'روز',
        points: 30,
      ),
      Achievement(
        id: 'streak_10_days',
        title: '۱۰ روز پشت سر هم',
        description: '۱۰ روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 10,
        currentValue: 0,
        unit: 'روز',
        points: 80,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'streak_30_days',
        title: '۳۰ روز پشت سر هم',
        description: '۳۰ روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 30,
        currentValue: 0,
        unit: 'روز',
        points: 250,
        tier: AchievementTier.gold,
      ),
      Achievement(
        id: 'confidential_info',
        title: 'ثبت اطلاعات محرمانه',
        description: 'بخش اطلاعات محرمانه را تکمیل کنید',
        icon: '🔒',
        category: AchievementCategory.platform,
        targetValue: 1,
        currentValue: 0,
        unit: 'بخش',
        points: 40,
      ),

      // === اجتماعی ===
      Achievement(
        id: 'invite_1',
        title: 'دعوت یک نفر',
        description: 'یک نفر را دعوت کنید',
        icon: '👋',
        category: AchievementCategory.social,
        targetValue: 1,
        currentValue: 0,
        unit: 'دعوت',
        points: 30,
      ),
      Achievement(
        id: 'invite_3',
        title: 'دعوت ۳ نفر',
        description: '۳ نفر را دعوت کنید',
        icon: '👥',
        category: AchievementCategory.social,
        targetValue: 3,
        currentValue: 0,
        unit: 'دعوت',
        points: 80,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'invite_10',
        title: 'دعوت ۱۰ نفر',
        description: '۱۰ نفر را دعوت کنید',
        icon: '🌟',
        category: AchievementCategory.social,
        targetValue: 10,
        currentValue: 0,
        unit: 'دعوت',
        points: 200,
        tier: AchievementTier.gold,
      ),
      Achievement(
        id: 'invite_30',
        title: 'دعوت ۳۰ نفر',
        description: '۳۰ نفر را دعوت کنید',
        icon: '👑',
        category: AchievementCategory.social,
        targetValue: 30,
        currentValue: 0,
        unit: 'دعوت',
        points: 500,
        tier: AchievementTier.platinum,
      ),

      // === تمرین و تغذیه ===
      Achievement(
        id: 'get_exercise_program',
        title: 'گرفتن برنامه تمرینی',
        description: 'یک برنامه تمرینی دریافت کنید',
        icon: '💪',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'برنامه',
        points: 40,
      ),
      Achievement(
        id: 'get_diet_program',
        title: 'گرفتن برنامه رژیم',
        description: 'یک برنامه رژیم دریافت کنید',
        icon: '🥗',
        category: AchievementCategory.nutrition,
        targetValue: 1,
        currentValue: 0,
        unit: 'برنامه',
        points: 40,
      ),
      Achievement(
        id: 'log_exercise',
        title: 'ثبت لاگ تمرین',
        description: 'اولین جلسه تمرین خود را ثبت کنید',
        icon: '📝',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'لاگ',
        points: 25,
      ),
      Achievement(
        id: 'log_diet',
        title: 'ثبت لاگ رژیم',
        description: 'اولین وعده غذایی را ثبت کنید',
        icon: '📋',
        category: AchievementCategory.nutrition,
        targetValue: 1,
        currentValue: 0,
        unit: 'لاگ',
        points: 25,
      ),
      Achievement(
        id: 'log_calorie',
        title: 'ثبت کالری‌شماری',
        description: 'کالری یک وعده را ثبت کنید',
        icon: '🔥',
        category: AchievementCategory.nutrition,
        targetValue: 1,
        currentValue: 0,
        unit: 'ثبت',
        points: 20,
      ),
    ];

    notifyListeners();
  }

  Future<void> _loadUserProgress() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final userProgress = await _databaseService.getUserAchievements();

      for (var i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        final progress = userProgress[achievement.id];

        if (progress != null) {
          _achievements[i] = achievement.copyWith(
            currentValue: progress.currentValue,
            unlockedAt: progress.unlockedAt,
          );
        } else {
          _achievements[i] = achievement.copyWith(currentValue: 0);
        }
      }

      await _syncInviteAchievementsFromProfile();
      await _backfillMissingBonuses(userProgress);
      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// اگر دستاورد باز است ولی bonus_points هنوز ۰ است (مایگریشن اجرا نشده).
  Future<void> _backfillMissingBonuses(
    Map<String, AchievementProgress> userProgress,
  ) async {
    var grantedAny = false;
    for (final achievement in _achievements) {
      if (!achievement.isUnlocked) continue;
      final progress = userProgress[achievement.id];
      if (progress != null && progress.bonusPoints > 0) continue;

      final granted = await _databaseService.grantBonusPointsIfNeeded(
        achievement.id,
        achievement.points,
      );
      if (granted) grantedAny = true;
    }
    if (grantedAny) {
      final profile = await SimpleProfileService.getCurrentProfile();
      final profileId = profile?['id'] as String?;
      if (profileId != null && profileId.isNotEmpty) {
        await RankingScoreService().updateUserScore(profileId);
        await ScoreService().loadFromDatabase(force: true);
      }
    }
  }

  Future<void> _syncInviteAchievementsFromProfile() async {
    try {
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) return;

      final totalReferrals = (profile['total_referrals'] as int?) ?? 0;
      const inviteIds = ['invite_1', 'invite_3', 'invite_10', 'invite_30'];
      for (final id in inviteIds) {
        final index = _achievements.indexWhere((a) => a.id == id);
        if (index != -1 &&
            _achievements[index].currentValue != totalReferrals) {
          await updateProgress(id, totalReferrals);
        }
      }
    } catch (e) {
      debugPrint('❌ Error syncing invite achievements from profile: $e');
    }
  }

  Future<void> syncInviteAchievementsFromProfile() async {
    await _syncInviteAchievementsFromProfile();
    notifyListeners();
  }

  Future<void> refreshFromDatabase({bool force = false}) async {
    final now = DateTime.now();
    if (_isRefreshingFromDatabase) return;
    if (!force &&
        _lastDatabaseRefreshAt != null &&
        now.difference(_lastDatabaseRefreshAt!) < _databaseRefreshCooldown) {
      return;
    }

    _isRefreshingFromDatabase = true;
    _lastDatabaseRefreshAt = now;
    try {
      await _databaseService.clearLocalCache();
      await _loadUserProgress();
    } catch (e) {
      debugPrint('❌ Error refreshing achievements: $e');
    } finally {
      _isRefreshingFromDatabase = false;
    }
  }

  void resetForLogout() {
    _initializeAchievements();
    notifyListeners();
  }

  Future<void> syncToDatabase() async {
    try {
      await _databaseService.syncLocalCacheToDatabase();
      await _loadUserProgress();
    } catch (e) {
      debugPrint('❌ Error syncing to database: $e');
    }
  }

  Future<void> updateProgress(String achievementId, int newValue) async {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) {
      debugPrint('⚠️ Achievement not found: $achievementId');
      return;
    }

    final oldAchievement = _achievements[index];
    final wasUnlocked = oldAchievement.isUnlocked;
    final isNowUnlocked = newValue >= oldAchievement.targetValue;
    if (oldAchievement.currentValue == newValue &&
        wasUnlocked == isNowUnlocked) {
      return;
    }
    final unlockTime = !wasUnlocked && isNowUnlocked
        ? DateTime.now()
        : oldAchievement.unlockedAt;

    _achievements[index] = oldAchievement.copyWith(
      currentValue: newValue,
      unlockedAt: unlockTime,
    );

    try {
      await _databaseService.saveAchievementProgress(
        achievementId,
        newValue,
        unlockedAt: unlockTime,
      );
    } catch (e) {
      debugPrint('❌ Error saving achievement progress to database: $e');
    }

    notifyListeners();

    if (!wasUnlocked && isNowUnlocked) {
      await _onAchievementUnlocked(_achievements[index]);
    }
  }

  Future<void> _onAchievementUnlocked(Achievement achievement) async {
    debugPrint(
      '🎉 Achievement Unlocked: ${achievement.title} (+${achievement.points} امتیاز)',
    );

    final granted = await _databaseService.grantBonusPointsIfNeeded(
      achievement.id,
      achievement.points,
    );

    if (granted) {
      try {
        final profile = await SimpleProfileService.getCurrentProfile();
        final profileId = profile?['id'] as String?;
        if (profileId != null && profileId.isNotEmpty) {
          await RankingScoreService().updateUserScore(profileId);
          await ScoreService().loadFromDatabase(force: true);
        }
      } catch (e) {
        debugPrint('❌ Error refreshing league score after unlock: $e');
      }
    }

    final context = MyApp.navigatorKey.currentContext;
    if (context != null && context.mounted) {
      AchievementNotification.show(context, achievement);
    }
  }

  Future<void> incrementProgress(
    String achievementId, [
    int increment = 1,
  ]) async {
    final achievement = _achievements.firstWhere(
      (a) => a.id == achievementId,
      orElse: () => throw Exception('Achievement not found'),
    );
    await updateProgress(achievementId, achievement.currentValue + increment);
  }

  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  List<Achievement> getRecentlyUnlocked({int days = 7}) {
    final cutoffDate = DateTime.now().subtract(Duration(days: days));
    return _achievements
        .where(
          (a) =>
              a.isUnlocked &&
              a.unlockedAt != null &&
              a.unlockedAt!.isAfter(cutoffDate),
        )
        .toList()
      ..sort((a, b) => b.unlockedAt!.compareTo(a.unlockedAt!));
  }

  List<Achievement> getAlmostUnlocked({double threshold = 0.8}) {
    return _achievements
        .where((a) => !a.isUnlocked && a.progress >= threshold)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
  }
}
