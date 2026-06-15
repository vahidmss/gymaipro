import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/custom_exercise.dart';
import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';
import 'package:gymaipro/services/coach_video_upload_service.dart';
import 'package:gymaipro/services/trainer_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت تمرین‌های اختصاصی
class CustomExerciseService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileRepository _profiles = ProfileRepository.instance;
  final CoachVideoUploadService _videoUploadService = CoachVideoUploadService();

  String? _encodeUrlColumn(List<String> urls) {
    if (urls.isEmpty) return null;
    if (urls.length == 1) return urls.first;
    return jsonEncode(urls);
  }

  /// دریافت نام نویسنده از userId
  Future<String> _getAuthorName(String userId) async {
    try {
      final displayName = await _profiles.getDisplayName(userId);
      return displayName;
    } catch (e) {
      debugPrint('Error getting author name: $e');
      return 'جیم اِی آی';
    }
  }

  /// تبدیل CustomExercise به Exercise با author
  Future<Exercise> customExerciseToExercise(CustomExercise customExercise) async {
    final authorName = await _getAuthorName(customExercise.createdBy);
    final exercise = customExercise.toExercise(authorName: authorName);
    debugPrint('=== CustomExerciseService: Converting "${customExercise.name}" - createdBy: ${customExercise.createdBy}, exercise.createdBy: ${exercise.createdBy} ===');
    return exercise;
  }

  /// تبدیل لیست CustomExercise به لیست Exercise با author
  Future<List<Exercise>> customExercisesToExercises(List<CustomExercise> customExercises) async {
    final exercises = <Exercise>[];
    for (final ce in customExercises) {
      final exercise = await customExerciseToExercise(ce);
      exercises.add(exercise);
    }
    return exercises;
  }

  /// دریافت تمام تمرین‌های مربی
  Future<List<CustomExercise>> getMyExercises() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      final response = await _supabase
          .from('custom_exercises')
          .select()
          .eq('created_by', user.id)
          .order('created_at', ascending: false)
          .then((value) => value as List);

      return response
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching custom exercises: $e');
      return [];
    }
  }

  /// دریافت تمرین‌های اختصاصی یک مربی خاص (برای شاگردان)
  /// این متد تمرین‌هایی که مربی با shared_with_clients=true ساخته است را برمی‌گرداند
  Future<List<CustomExercise>> getTrainerExercisesById(String trainerId) async {
    try {
      final response = await _supabase
          .from('custom_exercises')
          .select()
          .eq('created_by', trainerId)
          .eq('shared_with_clients', true)
          .order('created_at', ascending: false)
          .then((value) => value as List);

      return response
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching trainer custom exercises: $e');
      return [];
    }
  }

  /// دریافت تمرین‌های public
  /// برای تست: همه تمرین‌های public رو نمایش می‌ده (approved یا نه)
  Future<List<CustomExercise>> getPublicExercises({
    String? mainMuscle,
    String? difficulty,
    int limit = 50,
    bool requireApproval = false, // برای تست false می‌ذاریم
  }) async {
    try {
      var query = _supabase
          .from('custom_exercises')
          .select()
          .eq('visibility', 'public');
      
      // فقط اگر requireApproval true باشه، approved رو چک می‌کنیم
      if (requireApproval) {
        query = query.eq('approved', true);
      }

      if (mainMuscle != null && mainMuscle.isNotEmpty) {
        query = query.eq('main_muscle', mainMuscle);
      }

      if (difficulty != null && difficulty.isNotEmpty) {
        query = query.eq('difficulty', difficulty);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      debugPrint('=== CustomExerciseService.getPublicExercises: Query executed ===');
      final responseList = response as List;
      debugPrint('=== Found ${responseList.length} public custom exercises ===');
      
      return responseList
          .map((e) {
            final exData = e as Map<String, dynamic>;
            debugPrint('Parsing: ${exData['title']} (visibility: ${exData['visibility']}, approved: ${exData['approved']})');
            return CustomExercise.fromJson(exData);
          })
          .toList();
    } catch (e, stackTrace) {
      debugPrint('Error fetching public exercises: $e');
      debugPrint('Stack trace: $stackTrace');
      return [];
    }
  }

  /// ساخت تمرین جدید
  Future<CustomExercise> createExercise({
    required String title,
    required String name,
    required String mainMuscle, String? description,
    String? detailedDescription,
    String secondaryMuscles = '',
    String difficulty = 'متوسط',
    String equipment = 'بدون تجهیزات',
    String exerciseType = 'قدرتی',
    String? targetArea,
    String? videoUrl,
    String? imageUrl,
    List<String>? videoUrls,
    List<String>? imageUrls,
    List<String> tips = const [],
    String visibility = 'private',
    bool sharedWithClients = true,
    List<String> tags = const [],
    List<String> otherNames = const [],
    int estimatedDuration = 0,
    Map<String, int> muscleTargets = const {},
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      final resolvedVideoUrls = videoUrls ??
          (videoUrl != null && videoUrl.isNotEmpty ? [videoUrl] : const <String>[]);
      final resolvedImageUrls = imageUrls ??
          (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : const <String>[]);

      final data = {
        'created_by': user.id,
        'title': title,
        'name': name,
        'description': description,
        'detailed_description': detailedDescription,
        'main_muscle': mainMuscle,
        'secondary_muscles': secondaryMuscles,
        'difficulty': difficulty,
        'equipment': equipment,
        'exercise_type': exerciseType,
        'target_area': targetArea,
        'video_url': _encodeUrlColumn(resolvedVideoUrls),
        'image_url': _encodeUrlColumn(resolvedImageUrls),
        'tips': tips,
        'visibility': visibility,
        'shared_with_clients': sharedWithClients,
        'tags': tags,
        'other_names': otherNames,
        'estimated_duration': estimatedDuration,
        if (MuscleTargets.hasData(muscleTargets))
          'muscle_targets_json': jsonEncode(muscleTargets),
      };

      final response = await _supabase
          .from('custom_exercises')
          .insert(data)
          .select()
          .single();

      final customExercise = CustomExercise.fromJson(response);

      // اگر تمرین public باشه، به ai_exercises هم اضافه می‌کنیم
      if (visibility == 'public') {
        await _syncToAiExercises(customExercise);
      }

      return customExercise;
    } catch (e) {
      debugPrint('Error creating custom exercise: $e');
      rethrow;
    }
  }

  /// به‌روزرسانی تمرین
  Future<CustomExercise> updateExercise(
    String exerciseId, {
    String? title,
    String? name,
    String? description,
    String? detailedDescription,
    String? mainMuscle,
    String? secondaryMuscles,
    String? difficulty,
    String? equipment,
    String? exerciseType,
    String? targetArea,
    String? videoUrl,
    String? imageUrl,
    List<String>? videoUrls,
    List<String>? imageUrls,
    List<String>? tips,
    String? visibility,
    bool? sharedWithClients,
    List<String>? tags,
    List<String>? otherNames,
    int? estimatedDuration,
    Map<String, int>? muscleTargets,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (name != null) data['name'] = name;
      if (description != null) data['description'] = description;
      if (detailedDescription != null) {
        data['detailed_description'] = detailedDescription;
      }
      if (mainMuscle != null) data['main_muscle'] = mainMuscle;
      if (secondaryMuscles != null) data['secondary_muscles'] = secondaryMuscles;
      if (difficulty != null) data['difficulty'] = difficulty;
      if (equipment != null) data['equipment'] = equipment;
      if (exerciseType != null) data['exercise_type'] = exerciseType;
      if (targetArea != null) data['target_area'] = targetArea;
      if (videoUrls != null) {
        data['video_url'] = _encodeUrlColumn(videoUrls);
      } else if (videoUrl != null) {
        data['video_url'] = videoUrl;
      }
      if (imageUrls != null) {
        data['image_url'] = _encodeUrlColumn(imageUrls);
      } else if (imageUrl != null) {
        data['image_url'] = imageUrl;
      }
      if (tips != null) data['tips'] = tips;
      if (visibility != null) data['visibility'] = visibility;
      if (sharedWithClients != null) {
        data['shared_with_clients'] = sharedWithClients;
      }
      if (tags != null) data['tags'] = tags;
      if (otherNames != null) data['other_names'] = otherNames;
      if (estimatedDuration != null) {
        data['estimated_duration'] = estimatedDuration;
      }
      if (muscleTargets != null) {
        data['muscle_targets_json'] = MuscleTargets.hasData(muscleTargets)
            ? jsonEncode(muscleTargets)
            : null;
      }

      // دریافت تمرین قبلی برای بررسی تغییر visibility
      final oldExerciseResponse = await _supabase
          .from('custom_exercises')
          .select('visibility')
          .eq('id', exerciseId)
          .eq('created_by', user.id)
          .single();
      final oldVisibility = oldExerciseResponse['visibility'] as String?;

      final response = await _supabase
          .from('custom_exercises')
          .update(data)
          .eq('id', exerciseId)
          .eq('created_by', user.id)
          .select()
          .single();

      final customExercise = CustomExercise.fromJson(response);

      // مدیریت sync با ai_exercises بر اساس تغییر visibility
      final newVisibility = visibility ?? oldVisibility;
      if (newVisibility == 'public' && oldVisibility != 'public') {
        // تبدیل از private به public: اضافه به ai_exercises
        await _syncToAiExercises(customExercise);
      } else if (newVisibility == 'private' && oldVisibility == 'public') {
        // تبدیل از public به private: حذف از ai_exercises
        await _removeFromAiExercises(customExercise);
      } else if (newVisibility == 'public' && oldVisibility == 'public') {
        // اگر قبلاً public بود و هنوز public هست، فقط update می‌کنیم
        await _syncToAiExercises(customExercise);
      }

      return customExercise;
    } catch (e) {
      debugPrint('Error updating custom exercise: $e');
      rethrow;
    }
  }

  /// حذف تمرین
  Future<bool> deleteExercise(String exerciseId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('کاربر احراز هویت نشده است');

      // دریافت تمرین برای بررسی visibility قبل از حذف
      final exerciseResponse = await _supabase
          .from('custom_exercises')
          .select()
          .eq('id', exerciseId)
          .eq('created_by', user.id)
          .maybeSingle();

      if (exerciseResponse != null) {
        final customExercise = CustomExercise.fromJson(exerciseResponse);
        
        // اگر تمرین public بود، از ai_exercises هم حذف می‌کنیم
        if (customExercise.visibility == 'public') {
          await _removeFromAiExercises(customExercise);
        }
      }

      await _supabase
          .from('custom_exercises')
          .delete()
          .eq('id', exerciseId)
          .eq('created_by', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting custom exercise: $e');
      return false;
    }
  }

  /// Sync تمرین اختصاصی به ai_exercises (برای تمرین‌های public)
  Future<void> _syncToAiExercises(CustomExercise customExercise) async {
    try {
      // تبدیل CustomExercise به Exercise و سپس به فرمت Supabase
      final exercise = customExercise.toExercise();
      
      final supabaseData = <String, dynamic>{
        'id': exercise.id,
        'name': exercise.name,
        // 'title' column doesn't exist in ai_exercises table, using 'name' instead
        'content': exercise.content,
        'main_muscle': exercise.mainMuscle,
        'secondary_muscles': exercise.secondaryMuscles,
        'tips': exercise.tips,
        'video_url': exercise.videoUrl,
        'image_url': exercise.imageUrl,
        'other_names': exercise.otherNames,
        'difficulty': exercise.difficulty,
        'equipment': exercise.equipment,
        'exercise_type': exercise.exerciseType,
        'estimated_duration': exercise.estimatedDuration,
        'target_area': exercise.targetArea.isNotEmpty 
            ? exercise.targetArea 
            : exercise.mainMuscle,
        // 'description' and 'detailed_description' columns don't exist in ai_exercises table
        // detailed_description is stored in 'source' JSON field and extracted during read
      };

      // استفاده از upsert برای insert یا update
      await _supabase.from('ai_exercises').upsert(
        supabaseData,
        onConflict: 'id',
      );

      debugPrint('Synced custom exercise ${customExercise.title} to ai_exercises');
    } catch (e) {
      debugPrint('Error syncing custom exercise to ai_exercises: $e');
      // خطا رو throw نمی‌کنیم تا عملیات اصلی (create/update) موفق باشه
    }
  }

  /// حذف تمرین اختصاصی از ai_exercises (وقتی private می‌شه)
  Future<void> _removeFromAiExercises(CustomExercise customExercise) async {
    try {
      // ساخت ID منحصر به فرد از UUID
      final uniqueId = int.tryParse(
        customExercise.id.replaceAll('-', '').substring(0, 8),
        radix: 16,
      ) ?? 999999999;

      await _supabase
          .from('ai_exercises')
          .delete()
          .eq('id', uniqueId);

      debugPrint('Removed custom exercise ${customExercise.title} from ai_exercises');
    } catch (e) {
      debugPrint('Error removing custom exercise from ai_exercises: $e');
      // خطا رو throw نمی‌کنیم تا عملیات اصلی (update/delete) موفق باشه
    }
  }

  /// دریافت تمرین‌های اختصاصی مربی‌های کاربر (برای شاگردان)
  /// این متد تمرین‌هایی که مربی‌های کاربر با shared_with_clients=true ساخته‌اند را برمی‌گرداند
  Future<List<CustomExercise>> getTrainerExercisesForClient(
    String clientId,
  ) async {
    try {
      // ابتدا مربی‌های فعال کاربر را پیدا می‌کنیم
      final trainerService = TrainerService();
      final trainerRelationships = await trainerService.getClientTrainers(clientId);
      
      // فقط مربی‌های active را در نظر می‌گیریم
      final activeTrainerIds = trainerRelationships
          .where((rel) => rel.status == 'active')
          .map((rel) => rel.trainerId)
          .toList();

      if (activeTrainerIds.isEmpty) {
        return [];
      }

      // دریافت تمرین‌های اختصاصی که مربی‌ها با shared_with_clients=true ساخته‌اند
      final response = await _supabase
          .from('custom_exercises')
          .select()
          .inFilter('created_by', activeTrainerIds)
          .eq('shared_with_clients', true)
          .order('created_at', ascending: false);

      final responseList = response as List;
      
      return responseList
          .map((e) => CustomExercise.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('Error fetching trainer exercises for client: $e');
      return [];
    }
  }

  /// آپلود ویدیو
  Future<String> uploadVideo(
    XFile videoFile, {
    void Function(double progress)? onProgress,
  }) async {
    final file = File(videoFile.path);
    return _videoUploadService.uploadVideo(
      file,
      onProgress: onProgress,
    );
  }

  /// آپلود تصویر تمرین اختصاصی
  Future<String> uploadExerciseImage(XFile imageFile) async {
    final user = _supabase.auth.currentUser;
    if (user == null) {
      throw Exception('کاربر احراز هویت نشده است');
    }

    final file = File(imageFile.path);
    if (!await file.exists()) {
      throw Exception('فایل تصویر وجود ندارد');
    }

    final ext = imageFile.path.split('.').last.toLowerCase();
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final path =
        '${user.id}/${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _supabase.storage.from('custom_exercise_images').upload(
          path,
          file,
          fileOptions: const FileOptions(upsert: true),
        );

    return _supabase.storage.from('custom_exercise_images').getPublicUrl(path);
  }
}

