import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:gymaipro/achievements/models/achievement.dart';
import 'package:gymaipro/achievements/services/achievement_database_service.dart';
import 'package:gymaipro/achievements/widgets/achievement_notification.dart';
import 'package:gymaipro/main.dart';
import 'package:gymaipro/services/score_service.dart';

class AchievementService extends ChangeNotifier {
  AchievementService._internal() {
    _initializeAchievements();
    _loadUserProgress();
  }

  /// Single shared instance across the app.
  /// Avoid creating multiple instances (causes duplicate DB reads/writes and noisy logs).
  static final AchievementService instance = AchievementService._internal();

  /// Backwards-compatible factory: `AchievementService()` returns the shared instance.
  factory AchievementService() => instance;

  final AchievementDatabaseService _databaseService = AchievementDatabaseService();
  List<Achievement> _achievements = [];
  bool _isLoading = false;

  List<Achievement> get achievements => _achievements;

  List<Achievement> get unlockedAchievements =>
      _achievements.where((a) => a.isUnlocked).toList();

  List<Achievement> get lockedAchievements =>
      _achievements.where((a) => !a.isUnlocked).toList();

  int get totalPoints => _achievements
      .where((a) => a.isUnlocked)
      .fold(0, (sum, a) => sum + a.points);

  int get totalPossiblePoints =>
      _achievements.fold(0, (sum, a) => sum + a.points);

  double get completionPercentage {
    if (_achievements.isEmpty) return 0;
    return (unlockedAchievements.length / _achievements.length) * 100;
  }

  Map<AchievementCategory, List<Achievement>> get achievementsByCategory {
    final Map<AchievementCategory, List<Achievement>> grouped = {};

    for (final achievement in _achievements) {
      if (!grouped.containsKey(achievement.category)) {
        grouped[achievement.category] = [];
      }
      grouped[achievement.category]!.add(achievement);
    }

    return grouped;
  }

  void _initializeAchievements() {
    _achievements = [
      // === تب اول: استفاده از اپ (Platform) ===
      Achievement(
        id: 'profile_complete',
        title: 'تکمیل پروفایل',
        description: 'پروفایل خود را 100% تکمیل کنید',
        icon: '✅',
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
        points: 10,
      ),
      Achievement(
        id: 'membership_10_days',
        title: '10 روز با ما',
        description: '10 روز از تاریخ عضویت شما می‌گذرد',
        icon: '📅',
        category: AchievementCategory.platform,
        targetValue: 10,
        currentValue: 0,
        unit: 'روز',
        points: 50,
      ),
      Achievement(
        id: 'membership_30_days',
        title: '30 روز با ما',
        description: '30 روز از تاریخ عضویت شما می‌گذرد',
        icon: '📆',
        category: AchievementCategory.platform,
        targetValue: 30,
        currentValue: 0,
        unit: 'روز',
        points: 150,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'membership_90_days',
        title: '90 روز با ما',
        description: '90 روز از تاریخ عضویت شما می‌گذرد',
        icon: '🗓️',
        category: AchievementCategory.platform,
        targetValue: 90,
        currentValue: 0,
        unit: 'روز',
        points: 300,
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
        points: 1000,
        tier: AchievementTier.platinum,
      ),
      Achievement(
        id: 'streak_3_days',
        title: '3 روز پشت سر هم',
        description: '3 روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 3,
        currentValue: 0,
        unit: 'روز',
        points: 30,
      ),
      Achievement(
        id: 'streak_10_days',
        title: '10 روز پشت سر هم',
        description: '10 روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 10,
        currentValue: 0,
        unit: 'روز',
        points: 100,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'streak_30_days',
        title: '30 روز پشت سر هم',
        description: '30 روز متوالی از اپ استفاده کنید',
        icon: '🔥',
        category: AchievementCategory.platform,
        targetValue: 30,
        currentValue: 0,
        unit: 'روز',
        points: 500,
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
        points: 50,
      ),

      // === تب دوم: اجتماعی (Social) ===
      Achievement(
        id: 'invite_1',
        title: 'دعوت یک نفر',
        description: 'یک نفر را دعوت کنید',
        icon: '👋',
        category: AchievementCategory.social,
        targetValue: 1,
        currentValue: 0,
        unit: 'دعوت',
        points: 20,
      ),
      Achievement(
        id: 'invite_3',
        title: 'دعوت 3 نفر',
        description: '3 نفر را دعوت کنید',
        icon: '👥',
        category: AchievementCategory.social,
        targetValue: 3,
        currentValue: 0,
        unit: 'دعوت',
        points: 60,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'invite_10',
        title: 'دعوت 10 نفر',
        description: '10 نفر را دعوت کنید',
        icon: '🌟',
        category: AchievementCategory.social,
        targetValue: 10,
        currentValue: 0,
        unit: 'دعوت',
        points: 300,
        tier: AchievementTier.gold,
      ),
      Achievement(
        id: 'invite_30',
        title: 'دعوت 30 نفر',
        description: '30 نفر را دعوت کنید',
        icon: '👑',
        category: AchievementCategory.social,
        targetValue: 30,
        currentValue: 0,
        unit: 'دعوت',
        points: 1000,
        tier: AchievementTier.platinum,
      ),
      Achievement(
        id: 'trainer_message',
        title: 'پیام به مربی',
        description: 'به مربی خود پیام بفرستید',
        icon: '💬',
        category: AchievementCategory.social,
        targetValue: 1,
        currentValue: 0,
        unit: 'پیام',
        points: 30,
      ),
      Achievement(
        id: 'public_chat_message',
        title: 'پیام در چت روم همگانی',
        description: 'در چت روم همگانی پیام بگذارید',
        icon: '💭',
        category: AchievementCategory.social,
        targetValue: 1,
        currentValue: 0,
        unit: 'پیام',
        points: 25,
      ),
      Achievement(
        id: 'three_friends',
        title: '3 تا دوست',
        description: '3 دوست داشته باشید',
        icon: '🤝',
        category: AchievementCategory.social,
        targetValue: 3,
        currentValue: 0,
        unit: 'دوست',
        points: 50,
      ),

      // === تب سوم: تمرین و فعالیت (Workout) ===
      Achievement(
        id: 'get_exercise_program',
        title: 'گرفتن برنامه تمرینی',
        description: 'یک برنامه تمرینی دریافت کنید',
        icon: '💪',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'برنامه',
        points: 30,
      ),
      Achievement(
        id: 'get_diet_program',
        title: 'گرفتن برنامه رژیم',
        description: 'یک برنامه رژیم دریافت کنید',
        icon: '🥗',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'برنامه',
        points: 30,
      ),
      Achievement(
        id: 'log_exercise',
        title: 'ثبت لاگ برنامه تمرین',
        description: 'لاگ برنامه تمرین خود را ثبت کنید',
        icon: '📝',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'لاگ',
        points: 20,
      ),
      Achievement(
        id: 'log_diet',
        title: 'ثبت لاگ رژیم',
        description: 'لاگ رژیم خود را ثبت کنید',
        icon: '📋',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'لاگ',
        points: 20,
      ),
      Achievement(
        id: 'log_calorie',
        title: 'ثبت کالری شماری',
        description: 'کالری شماری خود را ثبت کنید',
        icon: '🔥',
        category: AchievementCategory.workout,
        targetValue: 1,
        currentValue: 0,
        unit: 'ثبت',
        points: 15,
      ),
      Achievement(
        id: 'calorie_streak_3',
        title: '3 روز پشت سر هم کالری شماری',
        description: '3 روز متوالی کالری شماری ثبت کنید',
        icon: '🔥',
        category: AchievementCategory.workout,
        targetValue: 3,
        currentValue: 0,
        unit: 'روز',
        points: 50,
      ),
      Achievement(
        id: 'get_3_programs',
        title: '3 تا برنامه',
        description: '3 برنامه دریافت کنید',
        icon: '📚',
        category: AchievementCategory.workout,
        targetValue: 3,
        currentValue: 0,
        unit: 'برنامه',
        points: 100,
        tier: AchievementTier.silver,
      ),

      // === تب چهارم: پیشرفت شخصی (Progress) ===
      Achievement(
        id: 'weight_loss_3kg',
        title: '3 کیلو کمتر',
        description: '3 کیلوگرم کاهش وزن',
        icon: '📉',
        category: AchievementCategory.progress,
        targetValue: 3,
        currentValue: 0,
        unit: 'کیلوگرم',
        points: 200,
      ),
      Achievement(
        id: 'weight_loss_5kg',
        title: '5 کیلو کمتر',
        description: '5 کیلوگرم کاهش وزن',
        icon: '📉',
        category: AchievementCategory.progress,
        targetValue: 5,
        currentValue: 0,
        unit: 'کیلوگرم',
        points: 400,
        tier: AchievementTier.silver,
      ),
      Achievement(
        id: 'weight_loss_10kg',
        title: '10 کیلو کمتر',
        description: '10 کیلوگرم کاهش وزن',
        icon: '📉',
        category: AchievementCategory.progress,
        targetValue: 10,
        currentValue: 0,
        unit: 'کیلوگرم',
        points: 800,
        tier: AchievementTier.gold,
      ),
      Achievement(
        id: 'goal_achieved',
        title: 'هدف محقق شد',
        description: 'به هدف وزنی خود برسید',
        icon: '🎯',
        category: AchievementCategory.progress,
        targetValue: 1,
        currentValue: 0,
        unit: 'هدف',
        points: 1000,
        tier: AchievementTier.platinum,
      ),
      Achievement(
        id: 'body_transform',
        title: 'تحول بدنی',
        description: 'درصد چربی بدن را 5% کاهش دهید',
        icon: '💎',
        category: AchievementCategory.progress,
        targetValue: 5,
        currentValue: 0,
        unit: 'درصد',
        points: 600,
        tier: AchievementTier.gold,
      ),
    ];

    notifyListeners();
  }

  /// بارگذاری پیشرفت کاربر از دیتابیس
  Future<void> _loadUserProgress() async {
    if (_isLoading) return;
    _isLoading = true;

    try {
      final userProgress = await _databaseService.getUserAchievements();

      // به‌روزرسانی پیشرفت دستاوردها
      for (int i = 0; i < _achievements.length; i++) {
        final achievement = _achievements[i];
        final progress = userProgress[achievement.id];

        if (progress != null) {
          _achievements[i] = achievement.copyWith(
            currentValue: progress.currentValue,
            unlockedAt: progress.unlockedAt,
          );
        } else {
          // اگر در دیتابیس نیست، reset کن
          _achievements[i] = achievement.copyWith(
            currentValue: 0,
            unlockedAt: null,
          );
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('❌ Error loading user progress: $e');
    } finally {
      _isLoading = false;
    }
  }

  /// بارگذاری مجدد از دیتابیس (پاک کردن cache و لود مجدد)
  Future<void> refreshFromDatabase() async {
    try {
      debugPrint('🔄 Refreshing achievements from database...');
      // پاک کردن cache محلی
      await _databaseService.clearLocalCache();
      // بارگذاری مجدد از دیتابیس
      await _loadUserProgress();
      debugPrint('✅ Achievements refreshed from database');
    } catch (e) {
      debugPrint('❌ Error refreshing achievements: $e');
    }
  }

  /// سینک cache محلی به دیتابیس
  Future<void> syncToDatabase() async {
    try {
      await _databaseService.syncLocalCacheToDatabase();
      await _loadUserProgress();
    } catch (e) {
      debugPrint('❌ Error syncing to database: $e');
    }
  }

  // بروزرسانی پیشرفت یک دستاورد
  Future<void> updateProgress(String achievementId, int newValue) async {
    final index = _achievements.indexWhere((a) => a.id == achievementId);
    if (index == -1) {
      debugPrint('⚠️ Achievement not found: $achievementId');
      return;
    }

    final oldAchievement = _achievements[index];
    final wasUnlocked = oldAchievement.isUnlocked;
    final isNowUnlocked = newValue >= oldAchievement.targetValue;
    final unlockTime = !wasUnlocked && isNowUnlocked ? DateTime.now() : oldAchievement.unlockedAt;

    // به‌روزرسانی در حافظه
    _achievements[index] = oldAchievement.copyWith(
      currentValue: newValue,
      unlockedAt: unlockTime,
    );

    // ذخیره در دیتابیس
    try {
      await _databaseService.saveAchievementProgress(
        achievementId,
        newValue,
        unlockedAt: unlockTime,
      );
    } catch (e) {
      debugPrint('❌ Error saving achievement progress to database: $e');
      // ادامه می‌دهیم حتی اگر ذخیره در دیتابیس خطا داد
    }

    notifyListeners();

    // اگر دستاورد تازه unlock شده، امتیاز اضافه کن
    if (!wasUnlocked && isNowUnlocked) {
      await _onAchievementUnlocked(_achievements[index]);
    }
  }

  Future<void> _onAchievementUnlocked(Achievement achievement) async {
    // اضافه کردن امتیاز به ScoreService
    final scoreService = ScoreService();
    
    // مطمئن شویم که ScoreService init شده است
    // اگر تاریخچه خالی است، از دیتابیس بارگذاری کن
    if (scoreService.history.isEmpty) {
      try {
        await scoreService.loadFromDatabase();
      } catch (e) {
        debugPrint('⚠️ Error loading score service: $e');
      }
    }
    
    // اضافه کردن امتیاز (این متد خودش بررسی می‌کند که تکراری نباشد)
    final pointsAdded = await scoreService.addAchievementPoints(
      achievementId: achievement.id,
      achievementTitle: achievement.title,
      achievementIcon: achievement.icon,
      points: achievement.points,
      description: achievement.description,
    );
    
    if (pointsAdded) {
      debugPrint(
        '🎉 Achievement Unlocked: ${achievement.title} (+${achievement.points} points)',
      );
    } else {
      debugPrint(
        'ℹ️ Achievement points already awarded: ${achievement.title}',
      );
    }

    // نمایش نوتیفیکیشن زیبا
    final context = MyApp.navigatorKey.currentContext;
    if (context != null) {
      AchievementNotification.show(context, achievement);
    }
  }

  // افزایش پیشرفت
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

  // دریافت دستاوردهای یک دسته خاص
  List<Achievement> getAchievementsByCategory(AchievementCategory category) {
    return _achievements.where((a) => a.category == category).toList();
  }

  // دریافت دستاوردهای اخیراً unlock شده
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

  // دریافت دستاوردهای نزدیک به unlock شدن
  List<Achievement> getAlmostUnlocked({double threshold = 0.8}) {
    return _achievements
        .where((a) => !a.isUnlocked && a.progress >= threshold)
        .toList()
      ..sort((a, b) => b.progress.compareTo(a.progress));
  }
}
