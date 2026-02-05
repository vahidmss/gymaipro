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

      print('=== PROFILE: attempting insert with data (no overwrite) ===');
      print('=== PROFILE: id=$userId ===');
      print('=== PROFILE: username=$finalUsername ===');
      print('=== PROFILE: phone_number=$phoneNumber ===');
      print('=== PROFILE: email=$email ===');
      print('=== PROFILE: role=athlete (new profile only) ===');

      // فقط insert برای پروفایل جدید؛ upsert نقش موجود را بازنویسی می‌کرد
      try {
        await client.from('profiles').insert({
          'id': userId,
          'username': finalUsername,
          'phone_number': phoneNumber,
          'email': email,
          'role': 'athlete',
        });
        print('=== PROFILE: insert completed successfully for $userId ===');
      } on PostgrestException catch (e) {
        if (e.code == '23505') {
          // conflict (profile already exists) - ignore, never overwrite role
          print('=== PROFILE: profile already exists, skipping insert ===');
        } else {
          rethrow;
        }
      }
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

      // دریافت اطلاعات کامل پروفایل (نه فقط ایمیل)
      Map<String, dynamic>? profileData;
      String? emailFromProfile;
      try {
        final prof = await client
            .from('profiles')
            .select()
            .eq('phone_number', normalizedPhone)
            .maybeSingle();
        if (prof != null) {
          profileData = prof;
          emailFromProfile = prof['email'] as String?;
          final profileId = prof['id'] as String?;
          print('=== SIGNIN: Found profile with ID: $profileId ===');
          print('=== SIGNIN: Profile email: ${emailFromProfile ?? 'null'} ===');
          print(
            '=== SIGNIN: Profile username: ${prof['username'] ?? 'null'} ===',
          );
        }
      } catch (e) {
        print('=== SIGNIN: error fetching profile: $e ===');
      }

      // نکته مهم:
      // برای جلوگیری از «لاگین فیک»، فقط باید روی همان کاربرِ مربوط به همین شماره کار کنیم.
      // پس ایمیلِ هدف را از پروفایل می‌گیریم؛ اگر خالی بود، یک ایمیل استاندارد می‌سازیم.
      final normalizedDigits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
      final targetEmail =
          (emailFromProfile != null && emailFromProfile.trim().isNotEmpty)
          ? emailFromProfile.trim()
          : _emailForAuth(normalizedPhone: normalizedDigits);

      // پسوردهای محتمل (قدیمی‌ها ممکن است بدون 0 ذخیره کرده باشند)
      final candidatePasswords = <String>{
        normalizedDigits,
        normalizedDigits.replaceFirst(RegExp(r'^0+'), ''), // 9916...
      }.where((p) => p.isNotEmpty).toList();

      // 1) تلاش برای ورود با همان ایمیلِ پروفایل/ایمیل استاندارد
      for (final pw in candidatePasswords) {
        try {
          print(
            '=== SIGNIN: trying signInWithPassword email=$targetEmail, password=$pw ===',
          );
          final res = await client.auth.signInWithPassword(
            email: targetEmail,
            password: pw,
          );
          if (res.session != null) {
            final currentUserId = res.session!.user.id;
            print('=== SIGNIN: success! user=$currentUserId ===');

            // NOTE:
            // Do NOT attempt to copy/delete/duplicate `profiles` rows here.
            // The `profiles` table has UNIQUE constraints on `username` and `phone_number`,
            // and other tables often FK to `profiles.id` (legacy profile id), so duplicating
            // or deleting can break data. We rely on `SimpleProfileService` phone fallback.
            if (profileData != null) {
              final existingProfileId = (profileData['id'] ?? '').toString();
              if (existingProfileId.isNotEmpty &&
                  existingProfileId != currentUserId) {
                print(
                  '=== SIGNIN: Profile/auth id mismatch (profileId=$existingProfileId, authId=$currentUserId). Using phone fallback. ===',
                );
                // Best-effort: link profile to the current auth user for correct RLS (auth_user_id)
                try {
                  await client
                      .from('profiles')
                      .update({'auth_user_id': currentUserId})
                      .eq('id', existingProfileId);
                  print(
                    '=== SIGNIN: profiles.auth_user_id linked (profileId=$existingProfileId -> authUserId=$currentUserId) ===',
                  );
                } catch (e) {
                  print(
                    '=== SIGNIN: Failed to update profiles.auth_user_id: $e ===',
                  );
                }
              }
            }

            return res.session;
          }
        } catch (e) {
          print('=== SIGNIN: signInWithPassword failed: $e ===');
        }
      }

      // 2) اگر پروفایل داشتیم ولی یوزر auth برایش ساخته نشده/پسورد فرق دارد،
      // یک بار تلاش می‌کنیم همان ایمیل را signUp کنیم تا «همان کاربر» قابل لاگین شود.
      // (این کار روی ایمیل دیگری لاگین نمی‌کند، بنابراین حس فیک ایجاد نمی‌شود.)
      if (profileData != null && targetEmail.isNotEmpty) {
        try {
          final pw = normalizedDigits;
          print(
            '=== SIGNIN: attempting signUp for existing profile email=$targetEmail ===',
          );
          final up = await client.auth.signUp(email: targetEmail, password: pw);
          Session? newSession = up.session;

          // اگر session نداد (ایمیل کانفرم)، تلاش به signIn
          if (newSession == null) {
            final inRes = await client.auth.signInWithPassword(
              email: targetEmail,
              password: pw,
            );
            newSession = inRes.session;
          }

          // اگر signUp/signIn موفق بود، پروفایل قدیمی را به ID جدید لینک کن
          if (newSession != null) {
            final newUserId = newSession.user.id;
            print('=== SIGNIN: signUp successful! New user ID: $newUserId ===');
            // NOTE: Same as above — do not duplicate/delete profiles here.
            // Rely on phone fallback profile resolution.
            try {
              final existingProfileId = (profileData['id'] ?? '').toString();
              if (existingProfileId.isNotEmpty) {
                await client
                    .from('profiles')
                    .update({'auth_user_id': newUserId})
                    .eq('id', existingProfileId);
                print(
                  '=== SIGNIN: profiles.auth_user_id linked after signUp (profileId=$existingProfileId -> authUserId=$newUserId) ===',
                );
              }
            } catch (e) {
              print(
                '=== SIGNIN: Failed to update profiles.auth_user_id after signUp: $e ===',
              );
            }

            return newSession;
          }
        } catch (e) {
          print('=== SIGNIN: signUp/signIn fallback failed: $e ===');
        }
      }

      throw Exception(
        'ورود ناموفق بود: اکانت مربوط به این شماره پیدا نشد یا پسورد هم‌خوانی ندارد.',
      );
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
