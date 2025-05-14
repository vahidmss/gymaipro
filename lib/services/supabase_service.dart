import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/profile_model.dart';
import '../models/weight_record_model.dart';

class SupabaseService {
  static final SupabaseClient _client = Supabase.instance.client;

  // Normalize phone number format
  String normalizePhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');

    // Ensure it starts with 0
    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    return normalized;
  }

  // پروفایل
  Future<Profile> createProfile(String username, String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // ابتدا کاربر را در سیستم احراز هویت ثبت‌نام می‌کنیم
      await registerUserAfterOTP(username, normalizedPhone);

      // سپس پروفایل را دریافت می‌کنیم
      final response = await _client
          .from('profiles')
          .select()
          .eq('username', username)
          .single();

      return Profile.fromJson(response);
    } catch (e) {
      print('Error creating profile: $e');
      rethrow;
    }
  }

  Future<Profile?> getProfile(String id) async {
    final response =
        await _client.from('profiles').select().eq('id', id).single();

    return response != null ? Profile.fromJson(response) : null;
  }

  Future<void> updateProfile(Profile profile) async {
    await _client
        .from('profiles')
        .update(profile.toJson())
        .eq('id', profile.id);
  }

  // ثبت وزن
  Future<WeightRecord> addWeightRecord(String profileId, double weight) async {
    try {
      final response = await _client
          .from('weight_records')
          .insert({
            'profile_id': profileId,
            'weight': weight,
            'recorded_at': DateTime.now().toIso8601String(),
          })
          .select()
          .single();
      return WeightRecord.fromJson(response);
    } catch (e) {
      print('Error adding weight record: \\$e');
      rethrow;
    }
  }

  Future<List<WeightRecord>> getWeightRecords(String profileId) async {
    final response = await _client
        .from('weight_records')
        .select()
        .eq('profile_id', profileId)
        .order('recorded_at', ascending: false);

    return (response as List)
        .map((json) => WeightRecord.fromJson(json))
        .toList();
  }

  // بررسی یکتا بودن نام کاربری
  Future<bool> isUsernameUnique(String username) async {
    try {
      print('Checking username uniqueness for: $username');
      final response = await _client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();
      print('isUsernameUnique response: $response');
      return response == null;
    } catch (e) {
      print('Error in isUsernameUnique: $e');
      rethrow;
    }
  }

  // بررسی وجود کاربر با شماره موبایل
  Future<bool> doesUserExist(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Checking if user exists with phone number: $normalizedPhone');

      // روش اول: استفاده از کوئری مستقیم
      try {
        final response = await _client
            .from('profiles')
            .select('id, username, phone_number')
            .eq('phone_number', normalizedPhone)
            .maybeSingle();

        print('User existence check direct query response: $response');
        if (response != null) {
          print('User found with direct query');
          return true;
        }
      } catch (e) {
        print('Direct query failed: $e');
      }

      // روش دوم: بررسی همه پروفایل‌ها و مقایسه دستی
      final allProfiles = await getAllProfiles();
      print('Got ${allProfiles.length} profiles for manual check');

      // چاپ همه پروفایل‌ها برای دیباگ
      for (var profile in allProfiles) {
        print('Profile: ${profile['username']} - ${profile['phone_number']}');
      }

      // بررسی دستی شماره موبایل در لیست پروفایل‌ها
      for (var profile in allProfiles) {
        if (profile['phone_number'] == normalizedPhone) {
          print(
              'Found matching profile with manual check: ${profile['username']}');
          return true;
        }
      }

      print(
          'No matching profile found after checking ${allProfiles.length} profiles');
      return false;
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // ساخت ایمیل ساختگی
  String createFakeEmail(String username, String phoneNumber) {
    // Remove any spaces and special characters from username
    String cleanUsername = username.replaceAll(RegExp(r'[^\w\s]+'), '');
    // Create a fake email using username and phone number
    return '$cleanUsername@example.com';
  }

  // ثبت‌نام کاربر پس از تأیید OTP
  Future<void> registerUserAfterOTP(String username, String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // ساخت ایمیل ساختگی
      String email = createFakeEmail(username, normalizedPhone);

      // ثبت‌نام در Supabase Auth
      final response = await _client.auth.signUp(
        email: email,
        password: normalizedPhone, // استفاده از شماره موبایل به عنوان پسورد
      );

      if (response.user == null) {
        throw Exception('Registration failed: User not created');
      }

      // ایجاد پروفایل در جدول profiles
      await _client.from('profiles').insert({
        'username': username,
        'phone_number': normalizedPhone,
      });

      print('User registered successfully with email: $email');
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // ساخت ایمیل ساختگی با استفاده از شماره موبایل
  Future<String> getFakeEmailFromPhoneNumber(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Getting fake email for phone number: $normalizedPhone');
      final response = await _client
          .from('profiles')
          .select('username')
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      print('Profile lookup response: $response');

      if (response != null && response['username'] != null) {
        String username = response['username'];
        // Remove any spaces and special characters from username
        String cleanUsername = username.replaceAll(RegExp(r'[^\w\s]+'), '');
        String email = '$cleanUsername@example.com';
        print('Generated fake email: $email');
        return email;
      } else {
        // اگر کاربر پیدا نشد، یک ایمیل ساختگی با استفاده از شماره موبایل ایجاد می‌کنیم
        print('User not found, generating email from phone number');
        String email =
            '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@example.com';
        print('Generated fallback email: $email');
        return email;
      }
    } catch (e) {
      print('Error getting fake email: $e');
      // در صورت بروز خطا، یک ایمیل ساختگی با استفاده از شماره موبایل ایجاد می‌کنیم
      String email = '${phoneNumber.replaceAll(RegExp(r'\D'), '')}@example.com';
      print('Generated fallback email after error: $email');
      return email;
    }
  }

  // خروج کاربر
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
      print('User signed out successfully');
    } catch (e) {
      print('Error signing out: $e');
      throw Exception('Error signing out');
    }
  }

  // دریافت پروفایل با استفاده از شماره موبایل
  Future<dynamic> getProfileByPhoneNumber(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Getting profile for phone number: $normalizedPhone');
      // جستجوی دقیق
      var response = await _client
          .from('profiles')
          .select()
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      // اگر پیدا نشد، جستجوی دستی بین همه پروفایل‌ها (برای رفع مشکل فرمت)
      if (response == null) {
        final allProfiles = await getAllProfiles();
        for (var profile in allProfiles) {
          final dbPhone = normalizePhoneNumber(profile['phone_number'] ?? '');
          if (dbPhone == normalizedPhone) {
            print('Manual match found for phone: $dbPhone');
            return profile;
          }
        }
      }

      print('Profile response: $response');
      return response;
    } catch (e) {
      print('Error getting profile by phone number: $e');
      return null;
    }
  }

  // دریافت همه پروفایل‌ها
  Future<List<dynamic>> getAllProfiles() async {
    try {
      print('Getting all profiles');

      // Check if we can connect to the database
      final client = Supabase.instance.client;
      print('Supabase client initialized: ${client != null}');

      // استفاده از دستور SQL مستقیم برای دریافت همه پروفایل‌ها
      final response = await _client.rpc('get_all_profiles');

      if (response == null || response.isEmpty) {
        print('No profiles found using RPC, trying direct query');
        // اگر RPC کار نکرد، از کوئری مستقیم استفاده کنیم
        final directResponse = await _client.from('profiles').select('*');

        // Log detailed information about the response
        print('Direct query response type: ${directResponse.runtimeType}');
        print('Direct query count: ${directResponse.length}');
        print('Direct query response: $directResponse');

        return directResponse;
      }

      // Log detailed information about the response
      print('All profiles response type: ${response.runtimeType}');
      print('All profiles count: ${response.length}');
      print('All profiles response: $response');

      return response;
    } catch (e) {
      print('Error getting all profiles: $e');
      try {
        // تلاش مجدد با استفاده از روش دیگر
        print('Trying alternative method to get profiles');
        final rawResponse = await _client.from('profiles').select('*');
        print('Alternative method response: $rawResponse');
        return rawResponse;
      } catch (e2) {
        print('Alternative method also failed: $e2');
        return [];
      }
    }
  }

  // ثبت‌نام مستقیم کاربر (برای دیباگ)
  Future<bool> registerUserDirectly(String username, String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print(
          'Registering user directly - username: $username, phone: $normalizedPhone');

      // ساخت ایمیل ساختگی
      String email = createFakeEmail(username, normalizedPhone);

      // ثبت‌نام در Supabase Auth
      final authResponse = await _client.auth.signUp(
        email: email,
        password: normalizedPhone,
      );

      if (authResponse.user == null) {
        print('Auth registration failed');
        return false;
      }

      // ایجاد پروفایل در جدول profiles
      final profileResponse = await _client.from('profiles').insert({
        'username': username,
        'phone_number': normalizedPhone,
      }).select();

      print('Profile created: $profileResponse');
      return true;
    } catch (e) {
      print('Error in direct registration: $e');
      return false;
    }
  }

  // بررسی وجود کاربر با استفاده از تابع RPC
  Future<bool> checkUserExistsRPC(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Checking if user exists with RPC: $normalizedPhone');
      final result = await _client.rpc('check_user_exists', params: {
        'phone': normalizedPhone,
      });

      print('RPC check result: $result');
      return result == true;
    } catch (e) {
      print('Error in RPC check: $e');
      return false;
    }
  }

  Future<Map<String, dynamic>?> getProfileByEmail(String email) async {
    try {
      final response =
          await _client.from('profiles').select().eq('email', email).single();
      return response;
    } catch (e) {
      print('Error getting profile by email: $e');
      return null;
    }
  }
}
