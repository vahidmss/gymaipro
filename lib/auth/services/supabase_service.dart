import 'dart:io';

import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
// import 'dart:math' as math; // unused

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Build a consistent fake email for auth from phone or username
  String _emailForAuth({required String normalizedPhone, String? username}) {
    final localPart = normalizedPhone.isNotEmpty
        ? normalizedPhone.replaceAll(RegExp(r'\D'), '')
        : (username ?? 'user');
    return '${localPart.toLowerCase()}@gym.ai';
  }

  // Normalize phone number format
  String normalizePhoneNumber(String phoneNumber) {
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');

    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    if (normalized.startsWith('+98')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('98')) {
      normalized = '0${normalized.substring(2)}';
    }

    return normalized;
  }

  // Check username uniqueness
  Future<bool> isUsernameUnique(String username) async {
    try {
      await client.from('profiles').select('count').limit(1);

      final response = await client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      return response == null;
    } catch (e) {
      return true; // Allow registration to continue on error
    }
  }

  // Check if user exists
  Future<bool> doesUserExist(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // Try RPC first
      try {
        final result = await client.rpc<bool>(
          'check_user_exists',
          params: {'phone_number': normalizedPhone},
        );
        return result == true;
      } catch (e) {
        // Fallback to direct query
        final exists = await client
            .from('profiles')
            .select('id')
            .eq('phone_number', normalizedPhone)
            .maybeSingle();

        return exists != null;
      }
    } catch (e) {
      return false;
    }
  }

  // Register user with phone number (real auth only)
  Future<Session?> signUpWithPhone(String phoneNumber, String username) async {
    try {
      print('=== SIGNUP: start signUpWithPhone ===');
      print('=== SIGNUP: input phoneNumber: $phoneNumber ===');
      print('=== SIGNUP: input username: $username ===');

      await testDatabaseConnection();
      print('=== SIGNUP: database connection test passed ===');

      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      print(
        '=== SIGNUP: normalizedPhone: $normalizedPhone, username: $username ===',
      );

      print('=== SIGNUP: calling _registerRealUser ===');
      final session = await _registerRealUser(normalizedPhone, username);
      print(
        '=== SIGNUP: _registerRealUser returned session: ${session != null} ===',
      );
      if (session != null) {
        print('=== SIGNUP: session user ID: ${session.user.id} ===');
        print(
          '=== SIGNUP: session access token length: ${session.accessToken.length} ===',
        );
      }
      return session;
    } catch (e) {
      print('=== SIGNUP: Error in signUpWithPhone: $e ===');
      print('=== SIGNUP: Error type: ${e.runtimeType} ===');
      print('=== SIGNUP: Error details: $e ===');
      rethrow;
    }
  }

  Future<Session?> _registerRealUser(
    String phoneNumber,
    String username,
  ) async {
    print(
      '=== REGISTER REAL USER: starting with phone=$phoneNumber, username=$username ===',
    );

    // روش پیشنهادی: چون OTP داخلی قبلاً حذف شده، از ایمیل/پسورد مشتق‌شده استفاده می‌کنیم
    final normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    print(
      '=== REGISTER REAL USER: normalized phone (digits only): $normalized ===',
    );

    final baseEmail = _emailForAuth(
      normalizedPhone: normalized,
      username: username,
    );
    final password = normalized; // فقط برای تست؛ در تولید نباید همان شماره باشد

    final String email = baseEmail;
    print('=== REGISTER REAL USER: generated email=$email ===');
    print('=== REGISTER REAL USER: generated password=$password ===');

    try {
      // تلاش برای ثبت‌نام
      print('=== REGISTER REAL USER: attempting signUp with email=$email ===');
      final res = await client.auth.signUp(email: email, password: password);
      final session = res.session;
      final signedUpUserId = res.user?.id;
      print(
        '=== REGISTER REAL USER: signUp done. session: ${session != null}, user: ${signedUpUserId ?? 'null'} ===',
      );

      if (session == null) {
        // اگر نیاز به تأیید ایمیل باشد، session برنمی‌گردد؛ در این پروژه فرض می‌کنیم ایمیل auto-confirm است
        // بنابراین تلاش برای ورود
        print(
          '=== REGISTER REAL USER: no session after signUp. trying signInWithPassword ===',
        );
        final signInRes = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print(
          '=== REGISTER REAL USER: signIn result session: ${signInRes.session != null} ===',
        );
        if (signInRes.session == null) {
          print('=== REGISTER REAL USER: signIn failed, returning null ===');
          return null;
        }
        print(
          '=== REGISTER REAL USER: calling _ensureProfile after signIn ===',
        );
        await _ensureProfile(
          signInRes.session!.user.id,
          username,
          phoneNumber,
          email,
        );
        print(
          '=== REGISTER REAL USER: _ensureProfile completed after signIn ===',
        );
        return signInRes.session;
      }

      print('=== REGISTER REAL USER: calling _ensureProfile after signUp ===');
      await _ensureProfile(session.user.id, username, phoneNumber, email);
      print(
        '=== REGISTER REAL USER: _ensureProfile completed after signUp ===',
      );
      return session;
    } catch (e) {
      print(
        '=== REGISTER REAL USER: signUp threw. trying signInWithPassword. error: $e ===',
      );
      print('=== REGISTER REAL USER: error type: ${e.runtimeType} ===');
      print('=== REGISTER REAL USER: error details: $e ===');

      // تلاش برای ورود با ایمیل پایه (اگر قبلاً ساخته شده بوده)
      try {
        print('=== REGISTER REAL USER: attempting fallback signIn ===');
        final signInRes = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        print(
          '=== REGISTER REAL USER: fallback signIn session: ${signInRes.session != null} ===',
        );
        if (signInRes.session != null) {
          print(
            '=== REGISTER REAL USER: calling _ensureProfile after fallback signIn ===',
          );
          await _ensureProfile(
            signInRes.session!.user.id,
            username,
            phoneNumber,
            email,
          );
          print(
            '=== REGISTER REAL USER: _ensureProfile completed after fallback signIn ===',
          );
          return signInRes.session;
        } else {
          print(
            '=== REGISTER REAL USER: fallback signIn returned null session ===',
          );
        }
      } catch (fallbackError) {
        print(
          '=== REGISTER REAL USER: fallback signIn failed: $fallbackError ===',
        );
        print(
          '=== REGISTER REAL USER: fallback error type: ${fallbackError.runtimeType} ===',
        );
      }

      // در صورت شکست به‌دلیل تداخل ایمیل، یک suffix اضافه و دوباره ثبت‌نام کن
      final parts = email.split('@');
      final altEmail = '${parts.first}-1@${parts.last}';
      print('=== REGISTER REAL USER: trying alternative email: $altEmail ===');
      try {
        print('=== REGISTER REAL USER: attempting alternative signUp ===');
        final alt = await client.auth.signUp(
          email: altEmail,
          password: password,
        );
        print(
          '=== REGISTER REAL USER: alternative signUp result: ${alt.session != null} ===',
        );
        if (alt.session != null) {
          print(
            '=== REGISTER REAL USER: calling _ensureProfile after alternative signUp ===',
          );
          await _ensureProfile(
            alt.session!.user.id,
            username,
            phoneNumber,
            altEmail,
          );
          print(
            '=== REGISTER REAL USER: _ensureProfile completed after alternative signUp ===',
          );
          return alt.session;
        }
        // بدون سشن، تلاش برای ورود
        print('=== REGISTER REAL USER: attempting alternative signIn ===');
        final altIn = await client.auth.signInWithPassword(
          email: altEmail,
          password: password,
        );
        print(
          '=== REGISTER REAL USER: alternative signIn result: ${altIn.session != null} ===',
        );
        if (altIn.session != null) {
          print(
            '=== REGISTER REAL USER: calling _ensureProfile after alternative signIn ===',
          );
          await _ensureProfile(
            altIn.session!.user.id,
            username,
            phoneNumber,
            altEmail,
          );
          print(
            '=== REGISTER REAL USER: _ensureProfile completed after alternative signIn ===',
          );
          return altIn.session;
        }
      } catch (ee) {
        print('=== REGISTER REAL USER: alternative signUp failed: $ee ===');
        print(
          '=== REGISTER REAL USER: alternative error type: ${ee.runtimeType} ===',
        );
      }
      print(
        '=== REGISTER REAL USER: all registration attempts failed, rethrowing original error ===',
      );
      rethrow;
    }
  }

  Future<void> _ensureProfile(
    String userId,
    String username,
    String phoneNumber,
    String email,
  ) async {
    try {
      print('=== PROFILE: ensuring profile for user=$userId ===');
      print(
        '=== PROFILE: username=$username, phone=$phoneNumber, email=$email ===',
      );

      // بررسی اتصال دیتابیس
      try {
        await client.from('profiles').select('count').limit(1);
        print('=== PROFILE: database connection test successful ===');
      } catch (dbError) {
        print('=== PROFILE: database connection test failed: $dbError ===');
        throw Exception('Database connection failed: $dbError');
      }

      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (existing != null) {
        print('=== PROFILE: profile already exists ===');
        return;
      }

      // بررسی تکراری بودن username
      String finalUsername = username;
      try {
        print(
          '=== PROFILE: checking username uniqueness for: $finalUsername ===',
        );
        final nameExists = await client
            .from('profiles')
            .select('id')
            .eq('username', finalUsername)
            .maybeSingle();
        if (nameExists != null) {
          final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
          finalUsername = '${finalUsername}_$suffix';
          print('=== PROFILE: username taken. using $finalUsername ===');
        } else {
          print('=== PROFILE: username is unique ===');
        }
      } catch (usernameError) {
        print('=== PROFILE: error checking username: $usernameError ===');
      }

      // بررسی تکراری بودن phone_number
      try {
        print(
          '=== PROFILE: checking phone number uniqueness for: $phoneNumber ===',
        );
        final phoneExists = await client
            .from('profiles')
            .select('id')
            .eq('phone_number', phoneNumber)
            .maybeSingle();
        if (phoneExists != null) {
          print(
            '=== PROFILE: phone number already exists, this might cause issues ===',
          );
        } else {
          print('=== PROFILE: phone number is unique ===');
        }
      } catch (phoneError) {
        print('=== PROFILE: error checking phone number: $phoneError ===');
      }

      print('=== PROFILE: attempting upsert with data: ===');
      print('=== PROFILE: id=$userId ===');
      print('=== PROFILE: username=$finalUsername ===');
      print('=== PROFILE: phone_number=$phoneNumber ===');
      print('=== PROFILE: email=$email ===');
      print('=== PROFILE: role=athlete ===');

      await client.from('profiles').upsert({
        'id': userId,
        'username': finalUsername,
        'phone_number': phoneNumber,
        'email': email,
        'role': 'athlete',
      });
      print('=== PROFILE: upsert completed successfully for $userId ===');
    } catch (e) {
      print('=== PROFILE: ensure failed with error: $e ===');
      print('=== PROFILE: error type: ${e.runtimeType} ===');
      print('=== PROFILE: error details: $e ===');
      rethrow; // rethrow the error to see the full stack trace
    }
  }

  // removed unused UUID generator

  // Test database connection
  Future<void> testDatabaseConnection() async {
    try {
      await client.from('profiles').select('count').limit(1);
    } catch (e) {
      throw Exception('Database connection failed: $e');
    }
  }

  // Sign in with phone number (mapped to email for real auth)
  Future<Session?> signInWithPhone(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      print('=== SIGNIN: start with phone=$normalizedPhone ===');
      final userExists = await doesUserExist(normalizedPhone);
      print('=== SIGNIN: userExists=$userExists ===');

      if (!userExists) {
        throw Exception(
          'User with phone number $normalizedPhone does not exist',
        );
      }

      // اگر ایمیل در پروفایل ذخیره شده باشد، از همان استفاده کن
      String? emailFromProfile;
      try {
        final prof = await client
            .from('profiles')
            .select('email')
            .eq('phone_number', normalizedPhone)
            .maybeSingle();
        emailFromProfile = (prof != null && (prof['email'] as String?) != null)
            ? (prof['email'] as String)
            : null;
        print('=== SIGNIN: emailFromProfile=${emailFromProfile ?? 'null'} ===');
      } catch (e) {
        print('=== SIGNIN: error fetching profile email: $e ===');
      }

      final email =
          emailFromProfile ??
          _emailForAuth(
            normalizedPhone: normalizedPhone.replaceAll(RegExp(r'\D'), ''),
          );
      print('=== SIGNIN: trying signInWithPassword email=$email ===');
      final response = await client.auth.signInWithPassword(
        email: email,
        password: normalizedPhone,
      );
      print(
        '=== SIGNIN: session=${response.session != null} user=${response.session?.user.id ?? 'null'} ===',
      );
      return response.session;
    } catch (e) {
      print('=== SIGNIN: Error in signInWithPhone: $e ===');
      rethrow;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await client.auth.signOut();
    } catch (e) {
      // Continue even if sign out fails
    }
  }

  // Get profile by phone number
  Future<UserProfile?> getProfileByPhone(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      return null;
    }

    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      final response = await client
          .from('profiles')
          .select()
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      if (response != null) {
        return UserProfile.fromJson(response);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get all profiles (for admin use)
  Future<List<Map<String, dynamic>>> getAllProfiles() async {
    try {
      final response = await client.from('profiles').select();
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  // Ensure profile exists
  Future<bool> ensureProfileExists(
    String userId, {
    String? username,
    String? phoneNumber,
  }) async {
    try {
      final existingProfile = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        return true;
      }

      final profileData = {
        'id': userId,
        'username': username ?? 'user_${userId.substring(0, 8)}',
        'phone_number': phoneNumber ?? '',
        'role': 'athlete',
      };

      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        profileData['email'] =
            '${phoneNumber.replaceAll(RegExp(r'\D'), '')}@temp.local';
      }

      await client.from('profiles').insert(profileData);
      return true;
    } catch (e) {
      return false;
    }
  }

  // Upload profile image
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().toIso8601String()}.$fileExt';
      final filePath = 'public/$fileName';

      await client.storage.from('profile_images').upload(filePath, imageFile);

      final imageUrlResponse = client.storage
          .from('profile_images')
          .getPublicUrl(filePath);

      // استفاده از SimpleProfileService بجای ProfileService
      await SimpleProfileService.updateProfile({
        'avatar_url': imageUrlResponse,
      });
      return imageUrlResponse;
    } catch (e) {
      return null;
    }
  }
}
