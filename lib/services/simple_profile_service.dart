import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// Removed dependency on ProfileService to keep a single source if we deprecate it

class SimpleProfileService {
  static final SupabaseClient client = Supabase.instance.client;

  // تست کاربر فعلی
  static Future<void> testCurrentUser() async {
    print('=== TESTING CURRENT USER ===');

    final authUser = client.auth.currentUser;
    print('Auth user: ${authUser?.id}');

    // mock removed

    final profile = await getCurrentProfile();
    print('Profile found: ${profile != null}');
    if (profile != null) {
      print('Profile username: ${profile['username']}');
      print('Profile phone: ${profile['phone_number']}');
    }

    print('=== END TEST ===');
  }

  // دریافت پروفایل کاربر فعلی
  static Future<Map<String, dynamic>?> getCurrentProfile() async {
    try {
      print('=== SIMPLE PROFILE SERVICE: Getting current profile ===');

      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        print(
          '=== SIMPLE PROFILE SERVICE: No authenticated user found anywhere ===',
        );
        return null;
      }

      print(
        '=== SIMPLE PROFILE SERVICE: Getting profile for user: $userId ===',
      );
      var response = await client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        print(
          '=== SIMPLE PROFILE SERVICE: Profile found: ${response['username']} ===',
        );
        print(
          '=== SIMPLE PROFILE SERVICE: Profile phone: ${response['phone_number']} ===',
        );
        print(
          '=== SIMPLE PROFILE SERVICE: Profile role: ${response['role']} ===',
        );
        return response;
      }
      print(
        '=== SIMPLE PROFILE SERVICE: No profile found for user: $userId ===',
      );

      // تلاش برای ساخت پروفایل حداقلی
      try {
        print(
          '=== SIMPLE PROFILE SERVICE: Ensuring minimal profile exists ===',
        );
        // phone_number در جدول یونیک است؛ اگر نداریم مقدار یکتا می‌گذاریم
        const safePhone = '';
        await client.from('profiles').insert({
          'id': userId,
          'username': 'user_${userId.substring(0, 8)}',
          'phone_number': safePhone,
          'role': 'athlete',
        });
      } catch (e) {
        print(
          '=== SIMPLE PROFILE SERVICE: ensure insert error (ignored): $e ===',
        );
      }

      // دریافت مجدد
      try {
        response = await client
            .from('profiles')
            .select()
            .eq('id', userId)
            .maybeSingle();
        if (response != null) return response;
      } catch (_) {}
      return null;
    } catch (e) {
      print('=== SIMPLE PROFILE SERVICE: Error getting profile: $e ===');
      return null;
    }
  }

  // به‌روزرسانی پروفایل
  static Future<bool> updateProfile(Map<String, dynamic> updates) async {
    try {
      // دریافت شناسه کاربر واقعی
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        print('No authenticated user found anywhere');
        return false;
      }

      print('Updating profile for user: $userId');
      print('Updates: $updates');

      // حذف فیلدهای غیرضروری از updates
      final cleanUpdates = Map<String, dynamic>.from(updates);
      cleanUpdates.remove('id'); // حذف id از updates
      cleanUpdates.remove('created_at'); // حذف created_at از updates
      // username را تنها در صورتی حذف می‌کنیم که مقدار آن رشته خالی باشد
      if (cleanUpdates['username'] == null ||
          (cleanUpdates['username'] is String &&
              (cleanUpdates['username'] as String).isEmpty)) {
        cleanUpdates.remove('username');
      }

      // تبدیل فیلدهای numeric از string به double
      for (final key in [
        'weight',
        'height',
        'arm_circumference',
        'chest_circumference',
        'waist_circumference',
        'hip_circumference',
      ]) {
        if (cleanUpdates.containsKey(key) && cleanUpdates[key] != null) {
          final value = cleanUpdates[key];
          if (value is String && value.isNotEmpty) {
            try {
              cleanUpdates[key] = double.parse(value);
            } catch (e) {
              print('Error parsing $key as double: $e');
              cleanUpdates.remove(key);
            }
          } else if (value == '' || value == null) {
            cleanUpdates.remove(key);
          }
        }
      }

      cleanUpdates['updated_at'] = DateTime.now().toUtc().toIso8601String();

      print('Clean updates: $cleanUpdates');

      // ابتدا بررسی کن که کاربر وجود دارد
      final checkResponse = await client
          .from('profiles')
          .select('id, username, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      print('User check response: $checkResponse');

      if (checkResponse == null) {
        print('User not found in database!');
        return false;
      }

      final response = await client
          .from('profiles')
          .update(cleanUpdates)
          .eq('id', userId)
          .select();

      print('Profile update response: $response');

      if (response.isNotEmpty) {
        print('Profile updated successfully');
        return true;
      } else {
        print('Profile update failed - no response');
        return false;
      }
    } catch (e) {
      print('Error updating profile: $e');
      return false;
    }
  }

  // ذخیره نام و نام خانوادگی
  static Future<bool> updateName(String firstName, String lastName) async {
    try {
      final updates = {'first_name': firstName, 'last_name': lastName};

      return await updateProfile(updates);
    } catch (e) {
      print('Error updating name: $e');
      return false;
    }
  }

  // ذخیره اطلاعات شخصی
  static Future<bool> updatePersonalInfo({
    String? bio,
    DateTime? birthDate,
    double? height,
    double? weight,
    String? gender,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (bio != null) updates['bio'] = bio;
      if (birthDate != null) {
        updates['birth_date'] = birthDate.toIso8601String().split('T')[0];
      }
      if (height != null) updates['height'] = height;
      if (weight != null) updates['weight'] = weight;
      if (gender != null) updates['gender'] = gender;

      return await updateProfile(updates);
    } catch (e) {
      print('Error updating personal info: $e');
      return false;
    }
  }

  // ذخیره اطلاعات فیزیکی
  static Future<bool> updatePhysicalInfo({
    double? armCircumference,
    double? chestCircumference,
    double? waistCircumference,
    double? hipCircumference,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (armCircumference != null) {
        updates['arm_circumference'] = armCircumference;
      }
      if (chestCircumference != null) {
        updates['chest_circumference'] = chestCircumference;
      }
      if (waistCircumference != null) {
        updates['waist_circumference'] = waistCircumference;
      }
      if (hipCircumference != null) {
        updates['hip_circumference'] = hipCircumference;
      }

      return await updateProfile(updates);
    } catch (e) {
      print('Error updating physical info: $e');
      return false;
    }
  }

  // ذخیره اهداف تناسب اندام
  static Future<bool> updateFitnessGoals(List<String> goals) async {
    try {
      return await updateProfile({'fitness_goals': goals});
    } catch (e) {
      print('Error updating fitness goals: $e');
      return false;
    }
  }

  // ذخیره شرایط پزشکی
  static Future<bool> updateMedicalConditions(List<String> conditions) async {
    try {
      return await updateProfile({'medical_conditions': conditions});
    } catch (e) {
      print('Error updating medical conditions: $e');
      return false;
    }
  }

  // ذخیره ترجیحات غذایی
  static Future<bool> updateDietaryPreferences(List<String> preferences) async {
    try {
      return await updateProfile({'dietary_preferences': preferences});
    } catch (e) {
      print('Error updating dietary preferences: $e');
      return false;
    }
  }

  // ذخیره سطح تجربه
  static Future<bool> updateExperienceLevel(String level) async {
    try {
      return await updateProfile({'experience_level': level});
    } catch (e) {
      print('Error updating experience level: $e');
      return false;
    }
  }

  // ذخیره روزهای تمرین ترجیحی
  static Future<bool> updatePreferredTrainingDays(List<String> days) async {
    try {
      return await updateProfile({'preferred_training_days': days});
    } catch (e) {
      print('Error updating preferred training days: $e');
      return false;
    }
  }

  // ذخیره زمان تمرین ترجیحی
  static Future<bool> updatePreferredTrainingTime(String time) async {
    try {
      return await updateProfile({'preferred_training_time': time});
    } catch (e) {
      print('Error updating preferred training time: $e');
      return false;
    }
  }
}
