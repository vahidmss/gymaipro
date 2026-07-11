import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت AI Trainer
class AITrainerService {
  static final SupabaseClient _client = Supabase.instance.client;

  static const String systemUsername = 'gymai_trainer';
  static const String avatarAssetPath = 'images/GymAI.jpg';

  /// شناسه AI Trainer (cache شده)
  static String? _aiTrainerId;

  /// دریافت شناسه AI Trainer
  static Future<String?> getAITrainerId() async {
    if (_aiTrainerId != null) {
      debugPrint('AI Trainer ID از cache: $_aiTrainerId');
      return _aiTrainerId;
    }

    try {
      debugPrint('جستجوی AI Trainer در دیتابیس...');

      final configuredId = AppConfig.aiTrainerProfileId.trim();
      if (configuredId.isNotEmpty) {
        final byId = await ProfileRepository.instance.fetchProfile(configuredId);
        if (byId != null) {
          _aiTrainerId = byId['id'] as String;
          debugPrint('AI Trainer ID پیدا شد با config: $_aiTrainerId');
          return _aiTrainerId;
        }
      }

      final byUsername =
          await ProfileRepository.instance.fetchProfileByUsername(systemUsername);
      if (byUsername != null) {
        _aiTrainerId = byUsername['id'] as String;
        final role = byUsername['role']?.toString() ?? '';
        if (role != 'trainer') {
          debugPrint(
            'AI Trainer با username پیدا شد ولی role=$role است (trainer انتظار می‌رود)',
          );
        } else {
          debugPrint('AI Trainer ID پیدا شد با username: $_aiTrainerId');
        }
        return _aiTrainerId;
      }

      debugPrint('AI Trainer پیدا نشد!');
      return null;
    } catch (e) {
      debugPrint('خطا در دریافت شناسه AI Trainer: $e');
      return null;
    }
  }

  /// بررسی وجود AI Trainer
  static Future<bool> isAITrainerExists() async {
    final id = await getAITrainerId();
    return id != null;
  }

  /// ایجاد AI Trainer اگر وجود نداشته باشد
  static Future<String?> ensureAITrainerExists() async {
    // ابتدا بررسی کنیم آیا وجود دارد
    final existingId = await getAITrainerId();
    if (existingId != null) {
      debugPrint('AI Trainer موجود است: $existingId');
      return existingId;
    }

    // اگر وجود ندارد، آن را ایجاد کنیم
    debugPrint('AI Trainer وجود ندارد - تلاش برای ایجاد...');
    final success = await createAITrainerIfNotExists();
    if (success) {
      debugPrint('AI Trainer با موفقیت ایجاد شد');
      return getAITrainerId();
    } else {
      debugPrint('خطا در ایجاد AI Trainer');
      return null;
    }
  }

  /// ایجاد AI Trainer (در صورت عدم وجود)
  static Future<bool> createAITrainerIfNotExists() async {
    try {
      // بررسی وجود
      if (await isAITrainerExists()) {
        return true;
      }

      // ایجاد پروفایل AI Trainer بدون نیاز به auth.users
      final profileData = {
        'id':
            '00000000-0000-0000-0000-000000000001', // UUID ثابت برای AI Trainer
        'username': 'gymai_trainer',
        'phone_number': '+989000000000',
        'email': 'ai.trainer@gymaipro.com',
        'first_name': 'جیم‌آی',
        'last_name': 'مربی هوشمند',
        'avatar_url': 'https://via.placeholder.com/150/4CAF50/FFFFFF?text=AI',
        'bio':
            'من جیم‌آی هستم، مربی هوشمند شما! با استفاده از هوش مصنوعی پیشرفته، برنامه‌های تمرینی شخصی‌سازی شده برای شما طراحی می‌کنم.',
        'role': 'trainer',
        'specializations': [
          'برنامه‌ریزی تمرینی',
          'هوش مصنوعی',
          'شخصی‌سازی',
          'تغذیه ورزشی',
        ],
        'certificates': [
          'مدرک هوش مصنوعی در ورزش',
          'گواهینامه برنامه‌ریزی تمرینی',
        ],
        'hourly_rate': 0.0,
        'rating': 4.9,
        'review_count': 0,
        'student_count': 0,
        'experience_years': 5,
        'ranking': 1,
        'phone_number_public': '+989000000000',
        'email_public': 'ai.trainer@gymaipro.com',
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      await _client.from('profiles').insert(profileData);

      _aiTrainerId = '00000000-0000-0000-0000-000000000001';
      debugPrint('AI Trainer با موفقیت ایجاد شد');
      return true;
    } catch (e) {
      final message = e.toString();
      if (message.contains('profiles_username_key') ||
          message.contains('23505')) {
        final existing =
            await ProfileRepository.instance.fetchProfileByUsername(
          systemUsername,
        );
        if (existing != null) {
          _aiTrainerId = existing['id'] as String;
          debugPrint(
            'AI Trainer از قبل وجود داشت — ID بازیابی شد: $_aiTrainerId',
          );
          return true;
        }
      }
      debugPrint('خطا در ایجاد AI Trainer: $e');
      return false;
    }
  }

  /// دریافت اطلاعات AI Trainer
  static Future<Map<String, dynamic>?> getAITrainerProfile() async {
    try {
      return ProfileRepository.instance.fetchProfileByUsername(systemUsername);
    } catch (e) {
      debugPrint('خطا در دریافت پروفایل AI Trainer: $e');
      return null;
    }
  }

  /// به‌روزرسانی آمار AI Trainer
  static Future<void> updateAITrainerStats({
    int? programCount,
    int? reviewCount,
    int? studentCount,
  }) async {
    try {
      final aiTrainerId = await getAITrainerId();
      if (aiTrainerId == null) return;

      final updateData = <String, dynamic>{};

      if (programCount != null) {
        // شمارش برنامه‌های ایجاد شده توسط AI
        final programResponse = await _client
            .from('workout_programs')
            .select('id')
            .eq('trainer_id', aiTrainerId)
            .eq('is_deleted', false);

        updateData['student_count'] = programResponse.length;
      }

      if (reviewCount != null) {
        updateData['review_count'] = reviewCount;
      }

      if (studentCount != null) {
        updateData['student_count'] = studentCount;
      }

      if (updateData.isNotEmpty) {
        updateData['updated_at'] = DateTime.now().toIso8601String();

        await _client.from('profiles').update(updateData).eq('id', aiTrainerId);
      }
    } catch (e) {
      debugPrint('خطا در به‌روزرسانی آمار AI Trainer: $e');
    }
  }

  static bool isGymaiTrainer({
    String? userId,
    String? username,
    String? firstName,
    String? lastName,
  }) {
    final configuredId = AppConfig.aiTrainerProfileId;
    if (userId != null &&
        userId.isNotEmpty &&
        userId == configuredId) {
      return true;
    }
    if (_aiTrainerId != null && userId != null && userId == _aiTrainerId) {
      return true;
    }
    return _looksLikeGymaiName(
      firstName: firstName,
      lastName: lastName,
      username: username,
    );
  }

  static bool _looksLikeGymaiName({
    String? firstName,
    String? lastName,
    String? username,
  }) {
    final u = username?.trim().toLowerCase() ?? '';
    if (u == systemUsername || u.contains('gymai') || u.contains('gym_ai')) {
      return true;
    }

    final full = '${firstName ?? ''} ${lastName ?? ''}'.trim().toLowerCase();
    if (full.contains('gymai') || full.contains('gym ai')) return true;

    final display = '${firstName ?? ''} ${lastName ?? ''}'.trim();
    if (display == AppConfig.gymAiDisplayName) return true;

    final compact = display.replaceAll(RegExp(r'[\s\u200c]'), '');
    if (compact.contains('جیم') &&
        (compact.contains('ای') || compact.contains('آی'))) {
      return true;
    }
    return false;
  }

  static Future<String?> resolveTrainerIdForAiPrograms() async {
    final cached = await getAITrainerId();
    if (cached != null && cached.isNotEmpty) return cached;
    return AppConfig.aiTrainerProfileId;
  }

  static Future<Map<String, dynamic>?> getDisplayProfile() =>
      getAITrainerProfile();

  static String displayNameFromProfile(Map<String, dynamic>? profile) {
    if (profile == null) return AppConfig.gymAiDisplayName;
    final first = (profile['first_name'] as String?)?.trim() ?? '';
    final last = (profile['last_name'] as String?)?.trim() ?? '';
    final full = '$first $last'.trim();
    if (full.isNotEmpty) return full;
    final username = (profile['username'] as String?)?.trim() ?? '';
    if (username == systemUsername) return AppConfig.gymAiDisplayName;
    if (username.isNotEmpty) return username;
    return AppConfig.gymAiDisplayName;
  }

  static Future<void> syncActiveStudentCount() async {
    try {
      final trainerId = await resolveTrainerIdForAiPrograms();
      if (trainerId == null) return;

      final activeRes = await _client
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .eq('status', 'active')
          .count();

      await _client.from('profiles').update({
        'student_count': activeRes.count,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', trainerId);
    } catch (e) {
      debugPrint('خطا در syncActiveStudentCount: $e');
    }
  }
}
