import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت AI Trainer
class AITrainerService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// شناسه AI Trainer (cache شده)
  static String? _aiTrainerId;

  /// دریافت شناسه AI Trainer
  static Future<String?> getAITrainerId() async {
    if (_aiTrainerId != null) {
      print('AI Trainer ID از cache: $_aiTrainerId');
      return _aiTrainerId;
    }

    try {
      print('جستجوی AI Trainer در دیتابیس...');

      // ابتدا بررسی کنیم آیا AI Trainer وجود دارد
      final allTrainers = await _client
          .from('profiles')
          .select('id, username, first_name, role')
          .eq('role', 'trainer');

      print('تمام مربیان موجود: $allTrainers');

      // جستجوی مستقیم با ID
      final response = await _client
          .from('profiles')
          .select('id, username, first_name, role')
          .eq('id', 'ddb977b5-0d39-4d9f-9a11-8dabbf301c02')
          .maybeSingle();

      print('نتیجه جستجوی AI Trainer با ID: $response');

      // اگر با ID پیدا نشد، با username جستجو کن
      if (response == null) {
        final responseByUsername = await _client
            .from('profiles')
            .select('id, username, first_name, role')
            .eq('username', 'gymai_trainer')
            .eq('role', 'trainer')
            .maybeSingle();

        print('نتیجه جستجوی AI Trainer با username: $responseByUsername');

        if (responseByUsername != null) {
          _aiTrainerId = responseByUsername['id'] as String;
          print('AI Trainer ID پیدا شد با username: $_aiTrainerId');
          return _aiTrainerId;
        }
      } else {
        _aiTrainerId = response['id'] as String;
        print('AI Trainer ID پیدا شد با ID: $_aiTrainerId');
        return _aiTrainerId;
      }

      print('AI Trainer پیدا نشد!');
      return null;
    } catch (e) {
      print('خطا در دریافت شناسه AI Trainer: $e');
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
      print('AI Trainer موجود است: $existingId');
      return existingId;
    }

    // اگر وجود ندارد، آن را ایجاد کنیم
    print('AI Trainer وجود ندارد - تلاش برای ایجاد...');
    final success = await createAITrainerIfNotExists();
    if (success) {
      print('AI Trainer با موفقیت ایجاد شد');
      return getAITrainerId();
    } else {
      print('خطا در ایجاد AI Trainer');
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
      print('AI Trainer با موفقیت ایجاد شد');
      return true;
    } catch (e) {
      print('خطا در ایجاد AI Trainer: $e');
      return false;
    }
  }

  /// دریافت اطلاعات AI Trainer
  static Future<Map<String, dynamic>?> getAITrainerProfile() async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('username', 'gymai_trainer')
          .eq('role', 'trainer')
          .maybeSingle();

      return response;
    } catch (e) {
      print('خطا در دریافت پروفایل AI Trainer: $e');
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
      print('خطا در به‌روزرسانی آمار AI Trainer: $e');
    }
  }
}
