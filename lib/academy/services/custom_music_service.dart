import 'package:flutter/foundation.dart';
import 'package:gymaipro/academy/models/custom_music.dart';
import 'package:gymaipro/academy/models/workout_music.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت موزیک‌های اختصاصی مربی
class CustomMusicService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// تعیین نام نمایشی هنرمند/نویسنده بر اساس نقش: ادمین → GymAI، مربی → نام و نام‌خانوادگی
  Future<String> resolveArtistByCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return 'مربی ناشناس';

      final profile = await SimpleProfileService.queryCurrentUserProfile(
        select: 'role, first_name, last_name, username',
      );
      if (profile == null) return 'مربی ناشناس';

      final role = profile['role'] as String?;
      if (role == 'admin') {
        return 'GymAI';
      }

      final firstName = profile['first_name'] as String?;
      final lastName = profile['last_name'] as String?;
      final username = profile['username'] as String?;
      final fullName = '${(firstName ?? '').trim()} ${(lastName ?? '').trim()}'.trim();
      if (fullName.isNotEmpty) return fullName;
      if ((username ?? '').trim().isNotEmpty) return (username!).trim();
      return 'مربی ناشناس';
    } catch (e) {
      debugPrint('Error resolving artist by user: $e');
      return 'مربی ناشناس';
    }
  }

  /// دریافت نام نویسنده از userId (created_by از custom_music که به auth.users.id اشاره می‌کند)
  Future<String> _getAuthorName(String userId) async {
    try {
      debugPrint('🔍 Getting author name for userId: $userId');
      
      // created_by در custom_music به auth.users.id اشاره می‌کند
      // profiles.id به auth.users.id reference می‌کنه (PRIMARY KEY REFERENCES auth.users(id))
      // پس اول با id جستجو می‌کنیم (رایج‌ترین حالت)
      
      // اول: جستجو با id (profiles.id == auth.users.id)
      var profile = await _supabase
          .from('profiles')
          .select('first_name, last_name, username')
          .eq('id', userId)
          .maybeSingle();
      
      debugPrint('🔍 Profile by id: $profile');
      
      // دوم: اگر پیدا نشد، با auth_user_id جستجو کن (برای legacy profiles)
      if (profile == null) {
        try {
          profile = await _supabase
              .from('profiles')
              .select('first_name, last_name, username')
              .eq('auth_user_id', userId)
              .maybeSingle();
          
          debugPrint('🔍 Profile by auth_user_id: $profile');
        } catch (e) {
          debugPrint('⚠️ Error querying by auth_user_id (column may not exist): $e');
        }
      }
      
      if (profile != null) {
        final firstName = profile['first_name'] as String?;
        final lastName = profile['last_name'] as String?;
        final username = profile['username'] as String?;
        
        debugPrint(
          '🔍 firstName: $firstName, lastName: $lastName, username: $username',
        );

        // اولویت: نام و نام خانوادگی (ترکیب)
        if (firstName != null && 
            firstName.trim().isNotEmpty && 
            lastName != null && 
            lastName.trim().isNotEmpty) {
          final name = '${firstName.trim()} ${lastName.trim()}'.trim();
          if (name.isNotEmpty) {
            debugPrint('✅ Returning full name: $name');
            return name;
          }
        }
        // دوم: فقط نام
        if (firstName != null && firstName.trim().isNotEmpty) {
          debugPrint('✅ Returning first name: $firstName');
          return firstName.trim();
        }
        // سوم: فقط نام خانوادگی
        if (lastName != null && lastName.trim().isNotEmpty) {
          debugPrint('✅ Returning last name: $lastName');
          return lastName.trim();
        }
        // چهارم: username
        if (username != null && username.trim().isNotEmpty) {
          debugPrint('✅ Returning username: $username');
          return username.trim();
        }
        
        debugPrint('⚠️ Profile found but all name fields are empty/null');
      }
      
      debugPrint('⚠️ No profile found for user: $userId');
      return 'مربی ناشناس';
    } catch (e, stackTrace) {
      debugPrint('❌ Error getting author name for $userId: $e');
      debugPrint('❌ Stack trace: $stackTrace');
      return 'مربی ناشناس';
    }
  }

  /// تبدیل CustomMusic به WorkoutMusic با author
  /// اگر artist در دیتابیس پر باشد (GymAI یا نام مربی) از همان استفاده می‌شود، وگرنه از پروفایل
  Future<WorkoutMusic> customMusicToWorkoutMusic(
    CustomMusic customMusic,
  ) async {
    final authorName = (customMusic.artist.trim().isNotEmpty)
        ? customMusic.artist.trim()
        : await _getAuthorName(customMusic.createdBy);
    return customMusic.toWorkoutMusic(authorName: authorName);
  }

  /// تبدیل لیست CustomMusic به لیست WorkoutMusic با author
  /// بهینه‌سازی شده برای لود سریع‌تر
  Future<List<WorkoutMusic>> customMusicsToWorkoutMusics(
    List<CustomMusic> customMusics,
  ) async {
    if (customMusics.isEmpty) return [];
    
    // دریافت نام‌های نویسندگان به صورت موازی
    final userIds = customMusics.map((m) => m.createdBy).toSet().toList();
    final authorNamesMap = <String, String>{};
    
    // دریافت نام‌ها به صورت موازی
    final authorFutures = userIds.map((userId) async {
      try {
        final name = await _getAuthorName(userId);
        return MapEntry(userId, name);
      } catch (e) {
        debugPrint('Error getting author name for $userId: $e');
        return MapEntry(userId, 'مربی ناشناس');
      }
    });
    
    final authorEntries = await Future.wait(authorFutures);
    for (final entry in authorEntries) {
      authorNamesMap[entry.key] = entry.value;
    }
    
    // تبدیل CustomMusic به WorkoutMusic؛ اولویت با artist ذخیره‌شده (GymAI یا نام مربی)
    return customMusics.map((cm) {
      final authorName = cm.artist.trim().isNotEmpty
          ? cm.artist.trim()
          : (authorNamesMap[cm.createdBy] ?? 'مربی ناشناس');
      return cm.toWorkoutMusic(authorName: authorName);
    }).toList();
  }

  /// دریافت تمام موزیک‌های مربی
  Future<List<CustomMusic>> getTrainerMusics() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('CustomMusicService: User is null');
        throw Exception('کاربر احراز هویت نشده است');
      }

      debugPrint('CustomMusicService: Fetching musics for user: ${user.id}');

      final response = await _supabase
          .from('custom_music')
          .select()
          .eq('created_by', user.id)
          .order('created_at', ascending: false);

      debugPrint('CustomMusicService: Response type: ${response.runtimeType}');
      
      final responseList = response as List;
      debugPrint('CustomMusicService: Response length: ${responseList.length}');

      if (responseList.isEmpty) {
        debugPrint('CustomMusicService: No musics found for user ${user.id}');
        return [];
      }

      final musics = responseList
          .map((json) {
            try {
              if (json is! Map<String, dynamic>) {
                debugPrint('CustomMusicService: Invalid JSON type: ${json.runtimeType}');
                return null;
              }
              return CustomMusic.fromJson(json);
            } catch (e) {
              debugPrint('CustomMusicService: Error parsing music JSON: $e');
              debugPrint('CustomMusicService: JSON: $json');
              return null;
            }
          })
          .whereType<CustomMusic>()
          .toList();

      debugPrint('CustomMusicService: Successfully parsed ${musics.length} musics');
      return musics;
    } catch (e, stackTrace) {
      debugPrint('CustomMusicService: Error fetching trainer musics: $e');
      debugPrint('CustomMusicService: Stack trace: $stackTrace');
      return [];
    }
  }

  /// دریافت موزیک‌های public
  Future<List<CustomMusic>> getPublicMusics() async {
    try {
      final response = await _supabase
          .from('custom_music')
          .select()
          .eq('visibility', 'public')
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CustomMusic.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching public musics: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// دریافت موزیک‌های private مربی‌های خاص (برای شاگردان)
  Future<List<CustomMusic>> getPrivateMusicsForTrainers(
    List<String> trainerIds,
  ) async {
    try {
      if (trainerIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('custom_music')
          .select()
          .eq('visibility', 'private')
          .inFilter('created_by', trainerIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CustomMusic.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching private musics for trainers: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// دریافت موزیک‌های public مربی‌های خاص
  Future<List<CustomMusic>> getPublicMusicsForTrainers(
    List<String> trainerIds,
  ) async {
    try {
      if (trainerIds.isEmpty) {
        return [];
      }

      final response = await _supabase
          .from('custom_music')
          .select()
          .eq('visibility', 'public')
          .inFilter('created_by', trainerIds)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => CustomMusic.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching public musics for trainers: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// ساخت موزیک جدید
  /// نام هنرمند بر اساس نقش تنظیم می‌شود: ادمین → GymAI، مربی → نام و نام‌خانوادگی
  Future<CustomMusic> createMusic({
    required String title,
    required String artist,
    required String audioUrl,
    required String coverImageUrl,
    required int duration,
    String? category,
    String? description,
    String? singer,
    String visibility = 'private',
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        debugPrint('CustomMusicService: createMusic - User is null');
        throw Exception('کاربر احراز هویت نشده است');
      }

      final displayArtist = await resolveArtistByCurrentUser();
      debugPrint('CustomMusicService: Creating music for user: ${user.id}');
      debugPrint('CustomMusicService: Title: $title, Artist (resolved): $displayArtist');
      debugPrint('CustomMusicService: Audio URL: $audioUrl');
      debugPrint('CustomMusicService: Cover URL: $coverImageUrl');

      final now = DateTime.now().toIso8601String();

      final data = {
        'created_by': user.id,
        'title': title,
        'artist': displayArtist,
        'audio_url': audioUrl,
        'cover_image_url': coverImageUrl,
        'duration': duration,
        'category': category,
        'description': description,
        'singer': singer?.trim().isEmpty ?? false ? null : singer?.trim(),
        'visibility': visibility,
        'views_count': 0,
        'likes_count': 0,
        'created_at': now,
        'updated_at': now,
      };

      debugPrint('CustomMusicService: Inserting data: $data');

      final response = await _supabase
          .from('custom_music')
          .insert(data)
          .select()
          .single();

      debugPrint('CustomMusicService: Insert response: $response');

      final music = CustomMusic.fromJson(response);
      debugPrint('CustomMusicService: Successfully created music with ID: ${music.id}');
      return music;
    } catch (e, stackTrace) {
      debugPrint('CustomMusicService: Error creating custom music: $e');
      debugPrint('CustomMusicService: Stack trace: $stackTrace');
      if (e is PostgrestException) {
        debugPrint('CustomMusicService: Postgrest error details: ${e.message}');
        debugPrint('CustomMusicService: Postgrest error code: ${e.code}');
        debugPrint('CustomMusicService: Postgrest error details: ${e.details}');
        debugPrint('CustomMusicService: Postgrest error hint: ${e.hint}');
      }
      rethrow;
    }
  }

  /// به‌روزرسانی موزیک
  /// نام هنرمند دوباره بر اساس نقش تنظیم می‌شود (ادمین → GymAI، مربی → نام فعلی)
  Future<CustomMusic> updateMusic({
    required String musicId,
    String? title,
    String? artist,
    String? audioUrl,
    String? coverImageUrl,
    int? duration,
    String? category,
    String? description,
    String? singer,
    String? visibility,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      final displayArtist = await resolveArtistByCurrentUser();

      final data = <String, dynamic>{
        'updated_at': DateTime.now().toIso8601String(),
        'artist': displayArtist,
      };

      if (title != null) data['title'] = title;
      if (audioUrl != null) data['audio_url'] = audioUrl;
      if (coverImageUrl != null) data['cover_image_url'] = coverImageUrl;
      if (duration != null) data['duration'] = duration;
      if (category != null) data['category'] = category;
      if (description != null) data['description'] = description;
      if (singer != null) data['singer'] = singer.trim().isEmpty ? null : singer.trim();
      if (visibility != null) data['visibility'] = visibility;

      final response = await _supabase
          .from('custom_music')
          .update(data)
          .eq('id', musicId)
          .eq('created_by', user.id)
          .select()
          .single();

      return CustomMusic.fromJson(response);
    } catch (e, stackTrace) {
      debugPrint('Error updating custom music: $e');
      debugPrint('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// حذف موزیک
  Future<bool> deleteMusic(String musicId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      await _supabase
          .from('custom_music')
          .delete()
          .eq('id', musicId)
          .eq('created_by', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting custom music: $e');
      return false;
    }
  }
}

