import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/models/custom_music.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/academy/services/custom_music_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/services/user_preferences_service.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:gymaipro/utils/cache_service.dart';

/// سرویس دریافت موزیک‌ها - فقط از Supabase
class WorkoutMusicService {
  static const String _cacheKey = 'academy_workout_music';
  static const Duration _cacheExpiry = Duration(minutes: 30);
  static final CustomMusicService _customMusicService = CustomMusicService();
  static final UserPreferencesService _preferencesService =
      UserPreferencesService();

  /// دریافت تمام موزیک‌ها از Supabase
  static Future<List<WorkoutMusic>> fetchMusic({
    bool forceRefresh = false,
  }) async {
    // اگر forceRefresh است، cache را پاک می‌کنیم
    if (forceRefresh) {
      await clearCache();
    }

    // بررسی cache
    if (!forceRefresh) {
      final lastUpdate = await CacheService.getUpdatedAt(_cacheKey);
      if (lastUpdate != null &&
          DateTime.now().difference(lastUpdate) < _cacheExpiry) {
        final cachedData = await CacheService.getJsonList(_cacheKey);
        if (cachedData != null && cachedData.isNotEmpty) {
          final cachedMusic = cachedData
              .cast<Map<String, dynamic>>()
              .map(WorkoutMusic.fromJson)
              .toList();

          // فیلتر کردن فقط موزیک‌های Supabase (isCustom = true)
          final supabaseMusics = cachedMusic.where((m) => m.isCustom).toList();

          // اگر موزیک‌های قدیمی در cache هستند، cache را پاک می‌کنیم
          if (supabaseMusics.length < cachedMusic.length) {
            debugPrint(
              '⚠️ موزیک‌های قدیمی در cache پیدا شد، در حال پاک کردن...',
            );
            await clearCache();
          } else if (supabaseMusics.isNotEmpty) {
            // اگر author یا createdBy null است، باید دوباره fetch کنیم
            final needsAuthorRefresh = supabaseMusics.any(
              (m) =>
                  m.author == null ||
                  m.author!.isEmpty ||
                  m.author == 'مربی ناشناس' ||
                  m.author == 'کاربر ناشناس',
            );
            
            // بررسی اینکه آیا createdBy در cache وجود دارد
            final needsCreatedByRefresh = supabaseMusics.any(
              (m) => m.createdBy == null || m.createdBy!.isEmpty,
            );

            if (needsAuthorRefresh || needsCreatedByRefresh) {
              debugPrint('⚠️ برخی موزیک‌ها author یا createdBy ندارند، در حال refresh...');
              await clearCache();
            } else {
              debugPrint('✅ Cache valid, using cached music with authors and createdBy');
              // اعمال لایک‌ها به cache (برای نمایش به‌روز)
              final musicWithPreferences = await _applyUserData(supabaseMusics);
              return musicWithPreferences;
            }
          } else {
            // اگر cache فقط موزیک‌های قدیمی دارد، cache را پاک می‌کنیم
            await clearCache();
          }
        }
      }
    }

    try {
      debugPrint('🔄 Fetching music from Supabase (not from cache)...');
      // دریافت موزیک‌ها از Supabase
      final musics = await _fetchAllMusics();

      // اطمینان از اینکه فقط موزیک‌های Supabase هستند
      final supabaseMusics = musics.where((m) => m.isCustom).toList();

      debugPrint('✅ Fetched ${supabaseMusics.length} musics from Supabase');
      debugPrint(
        '📝 Authors: ${supabaseMusics.map((m) => '${m.title}: ${m.author ?? "null"}').join(', ')}',
      );

      // اعمال لایک‌ها و preferences
      final musicWithPreferences = await _applyUserData(supabaseMusics);

      // ذخیره در cache
      final jsonData = musicWithPreferences.map((m) => m.toJson()).toList();
      await CacheService.setJson(_cacheKey, jsonData);

      debugPrint(
        '💾 Cached ${musicWithPreferences.length} musics with authors',
      );

      return musicWithPreferences;
    } catch (e) {
      debugPrint('Error fetching music: $e');

      // Fallback به cache در صورت خطا (فقط موزیک‌های Supabase)
      final cachedData = await CacheService.getJsonList(_cacheKey);
      if (cachedData != null && cachedData.isNotEmpty) {
        final cachedMusic = cachedData
            .cast<Map<String, dynamic>>()
            .map(WorkoutMusic.fromJson)
            .where((m) => m.isCustom) // فقط موزیک‌های Supabase
            .toList();
        if (cachedMusic.isNotEmpty) {
          return _applyUserData(cachedMusic);
        }
      }

      return [];
    }
  }

  /// دریافت تمام موزیک‌ها از Supabase (public + private مربی)
  static Future<List<WorkoutMusic>> _fetchAllMusics() async {
    final musics = <WorkoutMusic>[];

    try {
      debugPrint('🔄 Fetching public musics...');
      // دریافت موزیک‌های public (برای همه کاربران)
      final publicMusics = await _customMusicService.getPublicMusics();
      debugPrint('📦 Found ${publicMusics.length} public musics');
      final publicWorkoutMusics = await _customMusicService
          .customMusicsToWorkoutMusics(publicMusics);
      debugPrint(
        '✅ Converted to ${publicWorkoutMusics.length} WorkoutMusic with authors',
      );
      musics.addAll(publicWorkoutMusics);

      // دریافت موزیک‌های private مربی (فقط برای خود مربی)
      try {
        final trainerMusics = await _customMusicService.getTrainerMusics();
        final privateMusics = trainerMusics
            .where((m) => m.visibility == 'private')
            .toList();
        if (privateMusics.isNotEmpty) {
          final privateWorkoutMusics = await _customMusicService
              .customMusicsToWorkoutMusics(privateMusics);
          musics.addAll(privateWorkoutMusics);
        }
      } catch (e) {
        debugPrint('Error fetching trainer private musics: $e');
        // اگر مربی نیست یا خطا داد، ادامه می‌دهیم
      }

      // دریافت موزیک‌های (public + private) مربی‌هایی که کاربر شاگرد آن‌هاست
      try {
        // استفاده از SimpleProfileService برای دریافت profiles.id (مثل کیف پول)
        final profile = await SimpleProfileService.getCurrentProfile();
        final userId = profile?['id'] as String?;
        if (userId != null && userId.isNotEmpty) {
          final trainerClientService = TrainerClientService();
          final trainerRelationships = await trainerClientService.getClientTrainers(userId);
          
          // باید auth_user_id مربی را بگیریم چون custom_music.created_by به auth.users.id اشاره می‌کند
          final activeTrainerAuthIds = <String>[];
          for (final rel in trainerRelationships) {
            final status = rel['status'] as String?;
            if (status == null || status == 'active') {
              final trainerProfile = rel['trainer'] as Map<String, dynamic>?;
              if (trainerProfile != null) {
                // اولویت: auth_user_id (برای custom_music که به auth.users.id اشاره می‌کند)
                final authUserId = trainerProfile['auth_user_id'] as String?;
                if (authUserId != null && authUserId.isNotEmpty) {
                  activeTrainerAuthIds.add(authUserId);
                } else {
                  // Fallback: اگر auth_user_id ندارند، از profiles.id استفاده می‌کنیم
                  // (در legacy schema که profiles.id == auth.users.id)
                  final profileId = trainerProfile['id'] as String?;
                  if (profileId != null && profileId.isNotEmpty) {
                    activeTrainerAuthIds.add(profileId);
                  }
                }
              }
            }
          }

          if (activeTrainerAuthIds.isNotEmpty) {
            // دریافت موزیک‌های private و public مربی‌ها
            final trainerPrivateMusics = await _customMusicService
                .getPrivateMusicsForTrainers(activeTrainerAuthIds);
            final trainerPublicMusics = await _customMusicService
                .getPublicMusicsForTrainers(activeTrainerAuthIds);
            
            // ترکیب موزیک‌های private و public مربی‌ها
            final allTrainerMusics = <CustomMusic>[];
            allTrainerMusics.addAll(trainerPrivateMusics);
            allTrainerMusics.addAll(trainerPublicMusics);
            
            if (allTrainerMusics.isNotEmpty) {
              final trainerWorkoutMusics = await _customMusicService
                  .customMusicsToWorkoutMusics(allTrainerMusics);
              musics.addAll(trainerWorkoutMusics);
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching musics from trainers: $e');
        // اگر خطا داد، ادامه می‌دهیم
      }

      return musics;
    } catch (e) {
      debugPrint('Error fetching all musics: $e');
      return [];
    }
  }

  /// اعمال user preferences (likes) به لیست موزیک‌ها
  static Future<List<WorkoutMusic>> _applyUserData(
    List<WorkoutMusic> musics,
  ) async {
    if (musics.isEmpty) return musics;

    try {
      // دریافت preferences برای همه موزیک‌ها به صورت batch
      final musicIds = musics.map((m) => m.id).toList();
      final audioUrls = musics.map((m) => m.audioUrl).toList();
      final preferences = await _preferencesService.getMusicPreferences(
        musicIds,
        audioUrls: audioUrls,
      );

      final likedIds = Set<int>.from(preferences['likes'] as List? ?? []);
      final globalLikes = Map<int, int>.from(
        preferences['global_likes'] as Map? ?? {},
      );

      // اعمال preferences به موزیک‌ها
      for (final music in musics) {
        music.isLikedByUser = likedIds.contains(music.id);
        // استفاده از likes_count از custom_music یا مقدار فعلی
        music.likes = globalLikes[music.id] ?? music.likes;
      }

      return musics;
    } catch (e) {
      debugPrint('Error applying user data to musics: $e');
      // در صورت خطا، موزیک‌ها را بدون preferences برمی‌گردانیم
      return musics;
    }
  }

  /// پاک کردن cache
  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }
}
