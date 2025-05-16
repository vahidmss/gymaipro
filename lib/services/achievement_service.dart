import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class Achievement {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color color;
  final Map<String, dynamic> criteria;
  final int points;
  final bool isUnlocked;
  final double progress;
  final DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.color,
    required this.criteria,
    required this.points,
    this.isUnlocked = false,
    this.progress = 0.0,
    this.unlockedAt,
  });

  factory Achievement.fromJson(Map<String, dynamic> json,
      {Map<String, dynamic>? userAchievement}) {
    // تبدیل رشته رنگ به شیء Color
    final colorHex = json['color'] as String;
    final color = Color(int.parse(colorHex.replaceFirst('#', '0xFF')));

    // تبدیل رشته آیکون به شیء IconData
    final iconStr = json['icon'] as String;
    IconData icon = LucideIcons.award; // پیش‌فرض

    // نگاشت رشته‌های آیکون به IconData
    switch (iconStr) {
      case 'LucideIcons.dumbbell':
        icon = LucideIcons.dumbbell;
        break;
      case 'LucideIcons.flame':
        icon = LucideIcons.flame;
        break;
      case 'LucideIcons.medal':
        icon = LucideIcons.medal;
        break;
      case 'LucideIcons.mountain':
        icon = LucideIcons.mountain;
        break;
      case 'LucideIcons.heartPulse':
        icon = LucideIcons.heartPulse;
        break;
      case 'LucideIcons.crown':
        icon = LucideIcons.crown;
        break;
      default:
        icon = LucideIcons.award;
    }

    return Achievement(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      icon: icon,
      color: color,
      criteria: json['criteria'],
      points: json['points'],
      isUnlocked: userAchievement != null && userAchievement['progress'] >= 1.0,
      progress: userAchievement != null
          ? userAchievement['progress'].toDouble()
          : 0.0,
      unlockedAt:
          userAchievement != null && userAchievement['unlocked_at'] != null
              ? DateTime.parse(userAchievement['unlocked_at'])
              : null,
    );
  }
}

class AchievementService {
  final _client = Supabase.instance.client;

  // دریافت همه دستاوردهای موجود
  Future<List<Achievement>> getAllAchievements() async {
    try {
      final response = await _client.from('achievements').select();
      return response.map((json) => Achievement.fromJson(json)).toList();
    } catch (e) {
      print('Error getting achievements: $e');
      return [];
    }
  }

  // دریافت دستاوردهای کاربر
  Future<List<Achievement>> getUserAchievements() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      // دریافت همه دستاوردها
      final achievements = await getAllAchievements();

      // دریافت دستاوردهای کاربر
      final userAchievements = await _client
          .from('user_achievements')
          .select()
          .eq('profile_id', user.id);

      // نگاشت دستاوردهای کاربر به آبجکت‌های Achievement
      final Map<String, Map<String, dynamic>> userAchievementsMap = {};
      for (var item in userAchievements) {
        userAchievementsMap[item['achievement_id']] = item;
      }

      // ترکیب اطلاعات
      return achievements.map((achievement) {
        final userAchievement = userAchievementsMap[achievement.id];
        if (userAchievement != null) {
          return Achievement.fromJson(
            {
              'id': achievement.id,
              'name': achievement.name,
              'description': achievement.description,
              'icon': achievement.icon.toString(),
              'color': achievement.color.toString(),
              'criteria': achievement.criteria,
              'points': achievement.points,
            },
            userAchievement: userAchievement,
          );
        }
        return achievement;
      }).toList();
    } catch (e) {
      print('Error getting user achievements: $e');
      return [];
    }
  }

  // آپدیت پیشرفت یک دستاورد
  Future<void> updateAchievementProgress(
      String achievementId, double progress) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return;

      // بررسی وجود رکورد
      final existing = await _client
          .from('user_achievements')
          .select()
          .eq('profile_id', user.id)
          .eq('achievement_id', achievementId)
          .maybeSingle();

      if (existing == null) {
        // ایجاد رکورد جدید
        await _client.from('user_achievements').insert({
          'profile_id': user.id,
          'achievement_id': achievementId,
          'progress': progress,
          'unlocked_at':
              progress >= 1.0 ? DateTime.now().toIso8601String() : null,
        });
      } else {
        // به‌روزرسانی رکورد موجود
        await _client
            .from('user_achievements')
            .update({
              'progress': progress,
              'unlocked_at': progress >= 1.0 && existing['unlocked_at'] == null
                  ? DateTime.now().toIso8601String()
                  : existing['unlocked_at'],
            })
            .eq('profile_id', user.id)
            .eq('achievement_id', achievementId);
      }
    } catch (e) {
      print('Error updating achievement progress: $e');
    }
  }

  // بررسی پیشرفت کاربر و به‌روزرسانی دستاوردها
  Future<void> checkAndUpdateAchievements(Map<String, dynamic> userData) async {
    try {
      final achievements = await getAllAchievements();

      for (var achievement in achievements) {
        double progress = 0.0;

        // محاسبه پیشرفت براساس معیارهای دستاورد
        if (achievement.criteria.containsKey('workout_count')) {
          final targetCount = achievement.criteria['workout_count'];
          final currentCount = userData['workout_count'] ?? 0;
          progress = (currentCount / targetCount).clamp(0.0, 1.0);
        } else if (achievement.criteria
            .containsKey('consecutive_workout_days')) {
          final targetDays = achievement.criteria['consecutive_workout_days'];
          final currentDays = userData['consecutive_days'] ?? 0;
          progress = (currentDays / targetDays).clamp(0.0, 1.0);
        } else if (achievement.criteria
            .containsKey('weight_increase_percentage')) {
          final targetPercentage =
              achievement.criteria['weight_increase_percentage'];
          final currentPercentage = userData['weight_increase_percentage'] ?? 0;
          progress = (currentPercentage / targetPercentage).clamp(0.0, 1.0);
        } else if (achievement.criteria.containsKey('bmi_healthy')) {
          final height = userData['height'] ?? 0;
          final weight = userData['weight'] ?? 0;

          if (height > 0 && weight > 0) {
            final bmi = weight / ((height / 100) * (height / 100));
            // محدوده BMI سالم بین 18.5 تا 24.9 است
            progress = (bmi >= 18.5 && bmi <= 24.9) ? 1.0 : 0.8;
          }
        }

        // به‌روزرسانی پیشرفت دستاورد
        await updateAchievementProgress(achievement.id, progress);
      }
    } catch (e) {
      print('Error checking achievements: $e');
    }
  }
}
