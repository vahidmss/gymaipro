import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/trainer_ranking/models/trainer_ranking_model.dart';
import 'package:gymaipro/utils/cache_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrainerRankingService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static const String _cacheKey = 'trainer_rankings';
  static const Duration _cacheExpiry = Duration(minutes: 10);

  // Check if cache is still valid
  Future<bool> get _isCacheValid async {
    final lastUpdate = await CacheService.getUpdatedAt(_cacheKey);
    if (lastUpdate == null) return false;
    return DateTime.now().difference(lastUpdate) < _cacheExpiry;
  }

  // Clear cache manually
  static Future<void> clearCache() async {
    await CacheService.clear(_cacheKey);
  }

  // دریافت لیست مربیان رتبه‌بندی شده
  Future<List<UserProfile>> getTrainerRankings({
    int limit = 20,
    int offset = 0,
    String? specialization,
    double? minRating,
    double? maxHourlyRate,
    bool? isOnline,
    bool forceRefresh = false,
  }) async {
    try {
      // Return cached data if available and valid, unless force refresh is requested
      if (!forceRefresh && await _isCacheValid) {
        final cachedData = await CacheService.getJsonList(_cacheKey);
        if (cachedData != null) {
          return cachedData
              .cast<Map<String, dynamic>>()
              .map(UserProfile.fromJson)
              .toList();
        }
      }

      // ابتدا ranking همه مربیان را محاسبه و به‌روزرسانی کنیم
      await _updateAllTrainerRankings();

      final query = _supabase
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .order('ranking', ascending: true);

      final response = await query;
      final trainers = response.map(_convertTrainerToUserProfile).toList();

      // --- محاسبه تعداد شاگردان ---
      // 1) شاگردان حقیقی از جدول trainer_clients با وضعیت active
      final trainerClients = await _supabase
          .from('trainer_clients')
          .select('trainer_id, client_id, status');

      final Map<String, Set<String>> activeClientsByTrainer = {};
      for (final rel in trainerClients) {
        final m = Map<String, dynamic>.from(rel);
        if (m['status'] == 'active' &&
            m['trainer_id'] != null &&
            m['client_id'] != null) {
          final trainerId = m['trainer_id'] as String;
          final clientId = m['client_id'] as String;
          activeClientsByTrainer.putIfAbsent(trainerId, () => <String>{});
          activeClientsByTrainer[trainerId]!.add(clientId);
        }
      }

      // 2) شاگردان بر اساس برنامه‌های ساخته‌شده (برای سناریوی AI که رابطه مستقیم ندارند)
      final workoutPrograms = await _supabase
          .from('workout_programs')
          .select('trainer_id, user_id');

      final Map<String, Set<String>> programStudentsByTrainer = {};
      for (final program in workoutPrograms) {
        final m = Map<String, dynamic>.from(program);
        final String? trainerId = m['trainer_id'] as String?;
        final String? userId = m['user_id'] as String?;
        if (trainerId != null && userId != null) {
          programStudentsByTrainer.putIfAbsent(trainerId, () => <String>{});
          programStudentsByTrainer[trainerId]!.add(userId);
        }
      }

      final updated = trainers.map((t) {
        if (t.id == null) return t;
        final id = t.id!;
        final active = activeClientsByTrainer[id]?.length ?? 0;
        // اگر مربی شاگرد فعال دارد همان عدد نمایش داده شود؛
        // در غیر این صورت تعداد شاگردانِ بدست‌آمده از برنامه‌ها نمایش داده شود.
        final byPrograms = programStudentsByTrainer[id]?.length ?? 0;
        final count = active > 0 ? active : byPrograms;
        return t.copyWith(studentCount: count);
      }).toList();

      // Cache the results
      final jsonData = updated.map((trainer) => trainer.toJson()).toList();
      await CacheService.setJson(_cacheKey, jsonData);

      return updated;
    } catch (e) {
      print('خطا در دریافت رتبه‌بندی مربیان: $e');
      return [];
    }
  }

  // دریافت جزئیات یک مربی
  Future<UserProfile?> getTrainerDetails(String trainerId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', trainerId)
          .eq('role', 'trainer')
          .single();

      final trainer = _convertTrainerToUserProfile(response);

      // محاسبه تعداد شاگردان واقعی
      final studentCount = await _getStudentCount(trainerId);
      final activeStudentCount = await _getActiveStudentCount(trainerId);

      return trainer.copyWith(
        studentCount: studentCount,
        activeStudentCount: activeStudentCount,
      );
    } catch (e) {
      print('خطا در دریافت جزئیات مربی: $e');
      return null;
    }
  }

  // محاسبه تعداد کل شاگردان (همه شاگردان - فعال و منقضی شده)
  Future<int> _getStudentCount(String trainerId) async {
    try {
      print('🔍 محاسبه تعداد کل شاگردان برای مربی: $trainerId');

      // همه شاگردان از جدول trainer_clients (فعال و منقضی شده)
      final trainerClients = await _supabase
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId);

      print('🔍 تعداد کل شاگردان: ${trainerClients.length}');
      return trainerClients.length;
    } catch (e) {
      print('خطا در محاسبه تعداد کل شاگردان: $e');
      return 0;
    }
  }

  // محاسبه تعداد شاگردان فعال
  Future<int> _getActiveStudentCount(String trainerId) async {
    try {
      print('🔍 محاسبه تعداد شاگردان فعال برای مربی: $trainerId');

      // شاگردان فعال از جدول trainer_clients
      final trainerClients = await _supabase
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', trainerId)
          .eq('status', 'active');

      print('🔍 تعداد شاگردان فعال: ${trainerClients.length}');
      return trainerClients.length;
    } catch (e) {
      print('خطا در محاسبه تعداد شاگردان فعال: $e');
      return 0;
    }
  }

  // دریافت نظرات یک مربی با اطلاعات کامل کاربر
  Future<List<TrainerReview>> getTrainerReviews(String trainerId) async {
    try {
      // Join با جدول profiles برای دریافت اطلاعات کاربر
      final response = await _supabase
          .from('trainer_reviews')
          .select('''
            id,
            trainer_id,
            client_id,
            rating,
            review,
            created_at,
            profiles!trainer_reviews_client_id_fkey(
              first_name,
              last_name,
              avatar_url,
              username
            )
          ''')
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      final reviews = <TrainerReview>[];
      for (final json in response) {
        final profile = json['profiles'] as Map<String, dynamic>?;

        final isStudent = await _checkIfStudent(
          json['client_id'] as String,
          trainerId,
        );

        final firstName = profile?['first_name'] as String? ?? '';
        final lastName = profile?['last_name'] as String? ?? '';
        final fullName = '$firstName $lastName'.trim();
        final displayName = fullName.isNotEmpty
            ? fullName
            : profile?['username'] as String? ?? 'کاربر';

        reviews.add(
          TrainerReview.fromJson({
            'id': json['id'],
            'trainer_id': json['trainer_id'],
            'user_id': json['client_id'],
            'student_name': displayName,
            'rating': (json['rating'] as num).toDouble(),
            'comment': json['review'] ?? '',
            'created_at': json['created_at'],
            'user_avatar': profile?['avatar_url'],
            'user_full_name': fullName.isNotEmpty ? fullName : null,
            'is_verified_student': isStudent,
          }),
        );
      }

      return reviews;
    } catch (e) {
      print('خطا در دریافت نظرات مربی: $e');
      return [];
    }
  }

  // بررسی اینکه آیا کاربر شاگرد مربی بوده یا نه
  Future<bool> _checkIfStudent(String userId, String trainerId) async {
    try {
      // بررسی در جدول trainer_subscriptions
      final subscriptionCheck = await _supabase
          .from('trainer_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq('status', 'active')
          .limit(1);

      return subscriptionCheck.isNotEmpty;
    } catch (e) {
      print('خطا در بررسی شاگرد بودن: $e');
      return false;
    }
  }

  // افزودن نظر جدید (همیشه نظر جدید ایجاد می‌کند)
  Future<bool> addTrainerReview({
    required String trainerId,
    required String clientId,
    required double rating,
    required String comment,
  }) async {
    try {
      // همیشه نظر جدید ایجاد می‌کند (constraint حذف شده)
      await _supabase.from('trainer_reviews').insert({
        'trainer_id': trainerId,
        'client_id': clientId,
        'rating': rating.toInt(),
        'review': comment,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      });

      // به‌روزرسانی آمار مربی
      await _updateTrainerStats(trainerId);

      return true;
    } catch (e) {
      print('خطا در افزودن نظر: $e');
      return false;
    }
  }

  // به‌روزرسانی آمار مربی
  Future<void> _updateTrainerStats(String trainerId) async {
    try {
      // محاسبه میانگین امتیاز
      final reviewsResponse = await _supabase
          .from('trainer_reviews')
          .select('rating')
          .eq('trainer_id', trainerId);

      final ratings = reviewsResponse
          .map((r) => (r['rating'] as num).toDouble())
          .toList();

      final averageRating = ratings.isNotEmpty
          ? ratings.reduce((a, b) => a + b) / ratings.length
          : 0.0;

      // به‌روزرسانی آمار در profiles
      await _supabase
          .from('profiles')
          .update({
            'rating': averageRating,
            'review_count': ratings.length,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', trainerId)
          .eq('role', 'trainer');
    } catch (e) {
      print('خطا در به‌روزرسانی آمار مربی: $e');
    }
  }

  // به‌روزرسانی ranking همه مربیان
  Future<void> _updateAllTrainerRankings() async {
    try {
      // دریافت همه مربیان
      final trainersResponse = await _supabase
          .from('profiles')
          .select(
            'id, rating, review_count, experience_years, ranking, is_online, last_active_at',
          )
          .eq('role', 'trainer');

      if (trainersResponse.isEmpty) return;

      // محاسبه ranking برای هر مربی
      final List<Map<String, dynamic>> trainersWithScores = [];

      for (final trainer in trainersResponse) {
        final score = await _calculateTrainerScore(trainer);
        trainersWithScores.add({'id': trainer['id'], 'score': score});
      }

      // مرتب‌سازی بر اساس امتیاز (نزولی)
      trainersWithScores.sort(
        (a, b) => (b['score'] as double).compareTo(a['score'] as double),
      );

      // به‌روزرسانی ranking
      for (int i = 0; i < trainersWithScores.length; i++) {
        final trainerId = trainersWithScores[i]['id'];
        final ranking = i + 1; // ranking از 1 شروع می‌شود

        await _supabase
            .from('profiles')
            .update({
              'ranking': ranking,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', trainerId as Object)
            .eq('role', 'trainer');
      }

      print('✅ Ranking همه مربیان به‌روزرسانی شد');
    } catch (e) {
      print('خطا در به‌روزرسانی ranking مربیان: $e');
    }
  }

  // تبدیل داده‌های trainer به UserProfile
  UserProfile _convertTrainerToUserProfile(dynamic trainerData) {
    final Map<String, dynamic> trainer = Map<String, dynamic>.from(
      trainerData as Map<dynamic, dynamic>,
    );

    // Debug: Print gym owner status
    if (trainer['is_gym_owner'] == true) {
      print(
        '🏢 Gym Owner Found: ${trainer['username']} - is_gym_owner: ${trainer['is_gym_owner']}',
      );
    }
    return UserProfile(
      id: trainer['id'] as String? ?? '',
      username: (trainer['username'] as String?) ?? '',
      phoneNumber: trainer['phone_number'] as String?,
      firstName: trainer['first_name'] as String?,
      lastName: trainer['last_name'] as String?,
      avatarUrl: trainer['avatar_url'] as String?,
      bio: trainer['bio'] as String?,
      birthDate: trainer['birth_date'] != null
          ? DateTime.parse(trainer['birth_date'] as String)
          : null,
      height: trainer['height'] != null
          ? double.parse(trainer['height'].toString())
          : null,
      weight: trainer['weight'] != null
          ? double.parse(trainer['weight'].toString())
          : null,
      armCircumference: trainer['arm_circumference'] != null
          ? double.parse(trainer['arm_circumference'].toString())
          : null,
      chestCircumference: trainer['chest_circumference'] != null
          ? double.parse(trainer['chest_circumference'].toString())
          : null,
      waistCircumference: trainer['waist_circumference'] != null
          ? double.parse(trainer['waist_circumference'].toString())
          : null,
      hipCircumference: trainer['hip_circumference'] != null
          ? double.parse(trainer['hip_circumference'].toString())
          : null,
      experienceLevel: trainer['experience_level'] as String?,
      preferredTrainingDays: _convertToList<String>(
        trainer['preferred_training_days'],
      ),
      preferredTrainingTime: trainer['preferred_training_time'] as String?,
      fitnessGoals: _convertToList<String>(trainer['fitness_goals']),
      medicalConditions: _convertToList<String>(trainer['medical_conditions']),
      dietaryPreferences: _convertToList<String>(
        trainer['dietary_preferences'],
      ),
      weightHistory:
          _convertToList<Map<String, dynamic>>(trainer['weight_history']) ?? [],
      gender: trainer['gender'] as String?,
      role: 'trainer',
      lastSeenAt: trainer['last_seen_at'] != null
          ? DateTime.parse(trainer['last_seen_at'] as String)
          : null,
      isOnline: (trainer['is_online'] as bool?) ?? false,
      lastActiveAt: trainer['last_active_at'] != null
          ? DateTime.parse(trainer['last_active_at'] as String)
          : null,
      createdAt: trainer['created_at'] != null
          ? DateTime.parse(trainer['created_at'] as String)
          : null,
      updatedAt: trainer['updated_at'] != null
          ? DateTime.parse(trainer['updated_at'] as String)
          : null,
      // فیلدهای trainer
      specializations: _convertToList<String>(trainer['specializations']),
      certificates: _convertToList<String>(trainer['certificates']),
      hourlyRate: trainer['hourly_rate'] != null
          ? double.parse(trainer['hourly_rate'].toString())
          : 0.0,
      rating: trainer['rating'] != null
          ? double.parse(trainer['rating'].toString())
          : 0.0,
      reviewCount: (trainer['review_count'] as int?) ?? 0,
      studentCount: 0, // این مقدار بعداً از جدول trainer_clients محاسبه می‌شود
      experienceYears: (trainer['experience_years'] as int?) ?? 0,
      ranking: (trainer['ranking'] as int?) ?? 999999,
      phoneNumberPublic: trainer['phone_number_public'] as String?,
      emailPublic: trainer['email_public'] as String?,
      isGymOwner: (trainer['is_gym_owner'] as bool?) ?? false,
    );
  }

  // تابع کمکی برای تبدیل آرایه‌ها
  List<T>? _convertToList<T>(dynamic value) {
    if (value == null) return null;
    if (value is List) {
      try {
        if (T == String) {
          return value.map((e) => e.toString()).cast<T>().toList();
        } else if (T == Map<String, dynamic>) {
          return value
              .map((e) => Map<String, dynamic>.from(e as Map<dynamic, dynamic>))
              .cast<T>()
              .toList();
        } else {
          return value.cast<T>().toList();
        }
      } catch (e) {
        print('خطا در تبدیل آرایه: $e, value: $value');
        return null;
      }
    }
    return null;
  }

  // محاسبه امتیاز مربی
  Future<double> _calculateTrainerScore(Map<String, dynamic> trainer) async {
    double score = 0;

    // امتیاز rating (40% وزن)
    final rating = (trainer['rating'] as num?)?.toDouble() ?? 0.0;
    score += rating * 0.4;

    // امتیاز تعداد نظرات (20% وزن)
    final reviewCount = (trainer['review_count'] as num?)?.toInt() ?? 0;
    score += (reviewCount * 0.1).clamp(0.0, 2.0); // حداکثر 2 امتیاز

    // امتیاز تعداد شاگردان فعال (15% وزن) - از جدول trainer_clients
    final activeStudentCount = await _getActiveStudentCount(
      trainer['id'] as String,
    );
    score += (activeStudentCount * 0.05).clamp(0.0, 1.5); // حداکثر 1.5 امتیاز

    // امتیاز سال‌های تجربه (15% وزن)
    final experienceYears = (trainer['experience_years'] as num?)?.toInt() ?? 0;
    score += (experienceYears * 0.1).clamp(0.0, 1.5); // حداکثر 1.5 امتیاز

    // امتیاز آنلاین بودن (5% وزن)
    final isOnline = trainer['is_online'] as bool? ?? false;
    if (isOnline) score += 0.5;

    // امتیاز فعالیت اخیر (5% وزن)
    final lastActiveAt = trainer['last_active_at'];
    if (lastActiveAt != null) {
      final lastActive = DateTime.parse(lastActiveAt as String);
      final daysSinceLastActive = DateTime.now().difference(lastActive).inDays;
      if (daysSinceLastActive <= 7) score += 0.5; // فعال در هفته گذشته
    }

    return score;
  }

  // جستجوی مربیان
  Future<List<UserProfile>> searchTrainers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .or(
            'username.ilike.%$query%,first_name.ilike.%$query%,last_name.ilike.%$query%,bio.ilike.%$query%',
          )
          .order('ranking', ascending: true);

      return response.map(_convertTrainerToUserProfile).toList();
    } catch (e) {
      print('خطا در جستجوی مربیان: $e');
      return [];
    }
  }

  // دریافت مربیان آنلاین
  Future<List<UserProfile>> getOnlineTrainers() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .eq('is_online', true)
          .order('ranking', ascending: true);

      return response.map(_convertTrainerToUserProfile).toList();
    } catch (e) {
      print('خطا در دریافت مربیان آنلاین: $e');
      return [];
    }
  }

  // دریافت مربیان برتر
  Future<List<UserProfile>> getTopTrainers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('role', 'trainer')
          .order('rating', ascending: false)
          .limit(limit);

      return response.map(_convertTrainerToUserProfile).toList();
    } catch (e) {
      print('خطا در دریافت مربیان برتر: $e');
      return [];
    }
  }

  // دریافت آمار برنامه‌های مربی
  Future<Map<String, int>> getTrainerProgramStats(String trainerId) async {
    try {
      // تعداد برنامه‌های ورزشی
      final workoutPrograms = await _supabase
          .from('workout_programs')
          .select('id')
          .eq('trainer_id', trainerId);

      // تعداد برنامه‌های تغذیه (فعلاً غیرفعال - جدول وجود ندارد)
      const int nutritionPrograms = 0;

      return {
        'workout_programs': workoutPrograms.length,
        'nutrition_programs': nutritionPrograms,
      };
    } catch (e) {
      print('خطا در دریافت آمار برنامه‌های مربی: $e');
      return {'workout_programs': 0, 'nutrition_programs': 0};
    }
  }

  // دریافت آمار کلی مربیان
  Future<Map<String, dynamic>> getTrainerStats() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('rating, review_count, is_online')
          .eq('role', 'trainer');

      final int totalTrainers = response.length;
      final int onlineTrainers = response
          .where((t) => t['is_online'] == true)
          .length;
      double avgRating = 0;

      if (response.isNotEmpty) {
        final ratings = response
            .map((t) => (t['rating'] as num?)?.toDouble() ?? 0.0)
            .where((r) => r > 0)
            .toList();

        if (ratings.isNotEmpty) {
          avgRating = ratings.reduce((a, b) => a + b) / ratings.length;
        }
      }

      return {
        'total_trainers': totalTrainers,
        'online_trainers': onlineTrainers,
        'average_rating': avgRating,
      };
    } catch (e) {
      print('خطا در دریافت آمار مربیان: $e');
      return {'total_trainers': 0, 'online_trainers': 0, 'average_rating': 0.0};
    }
  }

  // دریافت تخصص‌های موجود
  Future<List<String>> getAvailableSpecializations() async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('specializations')
          .eq('role', 'trainer')
          .not('specializations', 'is', null);

      final Set<String> specializations = {};
      for (final item in response) {
        if (item['specializations'] != null) {
          final List<String> specs = List<String>.from(
            item['specializations'] as Iterable<dynamic>,
          );
          specializations.addAll(specs);
        }
      }

      return specializations.toList()..sort();
    } catch (e) {
      print('خطا در دریافت تخصص‌ها: $e');
      return [];
    }
  }
}
