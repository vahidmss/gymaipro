import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/auth_state_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  // Normalize phone number format
  String normalizePhoneNumber(String phoneNumber) {
    // Remove any spaces or special characters
    String normalized = phoneNumber.replaceAll(RegExp(r'\s+'), '');
    normalized = normalized.replaceAll(RegExp(r'[^\d]'), '');

    // Ensure it starts with 0 for Supabase storage
    if (!normalized.startsWith('0')) {
      normalized = '0$normalized';
    }

    // Remove +98 if present and replace with 0
    if (normalized.startsWith('+98')) {
      normalized = '0${normalized.substring(3)}';
    } else if (normalized.startsWith('98')) {
      normalized = '0${normalized.substring(2)}';
    }

    return normalized;
  }

  // بررسی یکتا بودن نام کاربری (با fallback)
  Future<bool> isUsernameUnique(String username) async {
    try {
      print('Checking username uniqueness for: $username');

      // Test connection first
      try {
        await client.from('profiles').select('count').limit(1);
        print('Supabase connection test successful');
      } catch (e) {
        print('Supabase connection test failed: $e');
        // Fallback: return true to allow registration to continue
        print('Using fallback: allowing username to be considered unique');
        return true;
      }

      final response = await client
          .from('profiles')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      print('isUsernameUnique response: $response');
      return response == null;
    } catch (e) {
      print('Error in isUsernameUnique: $e');
      print('Error type: ${e.runtimeType}');
      if (e is PostgrestException) {
        print(
          'PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}',
        );
      }

      // Fallback: return true to allow registration to continue
      print(
        'Using fallback due to error: allowing username to be considered unique',
      );
      return true;
    }
  }

  // بررسی وجود کاربر با شماره موبایل (اول RPC امن، سپس fallback)
  Future<bool> doesUserExist(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      print('Checking if user exists with RPC: $normalizedPhone');

      // 1) RPC SEC DEF (بدون محدودیت RLS)
      try {
        final result = await client.rpc<bool>(
          'check_user_exists',
          params: {'phone': normalizedPhone},
        );
        print('RPC check result: $result');
        return result;
        if (result is Map) {
          final boolResult =
              (result as Map<String, dynamic>)['check_user_exists'];
          if (boolResult is bool) return boolResult;
        }
      } catch (e) {
        print('RPC check failed: $e');
      }

      // 2) Fallback: جست‌وجو با چند فرمت شماره (در صورت فعال بودن دسترسی RLS)
      final candidates = <String>{};
      final digits = normalizedPhone.replaceAll(RegExp('[^0-9]'), '');
      final noZero = digits.startsWith('0') ? digits.substring(1) : digits;
      candidates.add(digits); // 09xxxxxxxxx
      candidates.add('+98$noZero');
      candidates.add('98$noZero');
      candidates.add(noZero);

      try {
        final orExpr = candidates.map((c) => 'phone_number.eq.$c').join(',');
        final response = await client
            .from('profiles')
            .select('id')
            .or(orExpr)
            .limit(1);
        final exists = response.isNotEmpty;
        print('Direct multi-format check: $exists');
        return exists;
      } catch (e) {
        print('Direct query failed: $e');
        return false;
      }
    } catch (e) {
      print('Error checking user existence: $e');
      return false;
    }
  }

  // ساخت ایمیل ساختگی
  String createFakeEmail(String username, String phoneNumber) {
    // Remove any spaces and special characters from username
    final String cleanUsername = username.replaceAll(RegExp(r'[^\w\s]+'), '');
    // Create a fake email using username and phone number
    return '$cleanUsername@example.com';
  }

  // ثبت‌نام کاربر پس از تأیید OTP
  Future<void> registerUserAfterOTP(String username, String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // ساخت ایمیل ساختگی
      final String email = createFakeEmail(username, normalizedPhone);

      // ثبت‌نام در Supabase Auth
      final response = await client.auth.signUp(
        email: email,
        password: normalizedPhone, // استفاده از شماره موبایل به عنوان پسورد
      );

      if (response.user == null) {
        throw Exception('Registration failed: User not created');
      }

      // ایجاد پروفایل در جدول profiles با id کاربر
      await client.from('profiles').insert({
        'id': response.user!.id, // اضافه کردن id کاربر
        'username': username,
        'phone_number': normalizedPhone,
        'email': email, // اضافه کردن ایمیل
      });

      print(
        'User registered successfully with email: $email and id: ${response.user!.id}',
      );
    } catch (e) {
      print('Error registering user: $e');
      rethrow;
    }
  }

  // ساخت ایمیل ساختگی با استفاده از شماره موبایل
  Future<String> getFakeEmailFromPhoneNumber(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // جستجوی کاربر با شماره موبایل
      final response = await client
          .from('profiles')
          .select('email')
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      if (response != null &&
          response['email'] != null &&
          response['email'].toString().isNotEmpty) {
        return response['email'] as String;
      }

      // ایجاد ایمیل ساختگی بر اساس شماره موبایل
      return '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@example.com';
    } catch (e) {
      print('Error getting fake email: $e');
      return '${phoneNumber.replaceAll(RegExp(r'\D'), '')}@example.com';
    }
  }

  // خروج کاربر
  Future<void> signOut() async {
    try {
      // Check connectivity before sign out
      final isOnline = await ConnectivityService.instance.checkNow();

      if (isOnline) {
        // Online: normal sign out
        await client.auth.signOut();
        print('User signed out successfully (online)');
      } else {
        // Offline: local sign out only
        print('Offline mode: performing local sign out only');
        // Clear local session without server call
        await client.auth.signOut();
        print('User signed out successfully (offline)');
      }
    } catch (e) {
      print('Error signing out: $e');
      // Don't throw exception in offline mode, just log
      if (kDebugMode) {
        print('Sign out error (may be offline): $e');
      }
    }
  }

  // دریافت پروفایل با استفاده از شماره موبایل
  Future<UserProfile?> getProfileByPhoneNumber(String phoneNumber) async {
    if (phoneNumber.isEmpty) {
      print('Phone number is empty, cannot fetch profile.');
      return null;
    }
    // Remove any non-digit characters from the phone number for a clean lookup
    // final normalizedPhone = phoneNumber.replaceAll(RegExp(r'[^0-9]'), '');
    // if (normalizedPhone.isEmpty) {
    //   print('Normalized phone number is empty.');
    //   return null;
    // }
    // print('Attempting to get profile for normalized phone number: $normalizedPhone (original: $phoneNumber)');

    try {
      final response = await client
          .from('profiles')
          .select()
          // .eq('phone_number', normalizedPhone) // Use normalizedPhone for lookup
          .eq(
            'phone_number',
            phoneNumber,
          ) // TODO: Re-evaluate if normalization is needed based on how numbers are stored
          .maybeSingle(); // Use maybeSingle to handle 0 or 1 record gracefully

      if (response == null) {
        print(
          'No profile found for phone number: $phoneNumber. Attempting manual check if enabled.',
        );
        // Fallback: If no direct match, try fetching all and comparing, only if really needed and RLS allows
        // This can be inefficient and might expose data if RLS is not strict.
        // Consider if this fallback is truly necessary or if strict matching is preferred.
        // if (AppConfig.enableManualProfileExistenceCheck) { // Example config flag
        //   final allProfiles = await getAllProfiles();
        //   print('Got ${allProfiles.length} profiles for manual check');
        //   if (allProfiles.isNotEmpty) {
        //     for (var profile in allProfiles) {
        //       print('Profile: ${profile['username']} - ${profile['phone_number']}');
        //       if (profile['phone_number'] == normalizedPhone) {
        //         print('Found matching profile with manual check: ${profile['username']}');
        //         return UserProfile.fromJson(profile);
        //       }
        //     }
        //   }
        //   print('No matching profile found after checking ${allProfiles.length} profiles');
        // }
        return null;
      }
      print('Profile lookup response: $response');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting profile: $e');
      if (e is PostgrestException) {
        print('PostgrestException details: ${e.message}, code: ${e.code}');
      }
      return null;
    }
  }

  // دریافت همه پروفایل‌ها
  Future<List<dynamic>> getAllProfiles() async {
    try {
      print('Getting all profiles');

      // Check if we can connect to the database
      final client = Supabase.instance.client;
      print('Supabase client initialized');

      // استفاده از دستور SQL مستقیم برای دریافت همه پروفایل‌ها
      final response = await client.rpc<List<dynamic>>('get_all_profiles');

      if (response.isEmpty) {
        print('No profiles found using RPC, trying direct query');
        // اگر RPC کار نکرد، از کوئری مستقیم استفاده کنیم
        final directResponse = await client.from('profiles').select();

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
        final rawResponse = await client.from('profiles').select();
        print('Alternative method response: $rawResponse');
        return rawResponse;
      } catch (e2) {
        print('Alternative method also failed: $e2');
        return [];
      }
    }
  }

  Future<void> _ensureProfileForUser(
    Session session,
    String normalizedPhone,
  ) async {
    try {
      final userId = session.user.id;
      final existing = await client
          .from('profiles')
          .select('id,email')
          .eq('id', userId)
          .maybeSingle();
      if (existing != null) {
        // Optionally backfill phone if missing
        if (existing['email'] == null || existing['email'].toString().isEmpty) {
          final email =
              '${normalizedPhone.replaceAll(RegExp('[^0-9]'), '')}@example.com';
          await client
              .from('profiles')
              .update({'email': email})
              .eq('id', userId);
        }
        return;
      }
      // Create minimal profile if missing
      final email =
          '${normalizedPhone.replaceAll(RegExp('[^0-9]'), '')}@example.com';
      await client.from('profiles').insert({
        'id': userId,
        'username': 'user_${userId.substring(0, 6)}',
        'phone_number': normalizedPhone,
        'email': email,
      });
    } catch (e) {
      print('ensureProfile error: $e');
    }
  }

  // ثبت‌نام مستقیم کاربر (برای دیباگ)
  Future<bool> registerUserDirectly(String username, String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print(
        'Registering user directly - username: $username, phone: $normalizedPhone',
      );

      // ساخت ایمیل ساختگی
      final String email = createFakeEmail(username, normalizedPhone);

      // ثبت‌نام در Supabase Auth
      final authResponse = await client.auth.signUp(
        email: email,
        password: normalizedPhone, // Consider a stronger password strategy
      );

      if (authResponse.user == null) {
        print('Auth registration failed for email: $email');
        return false;
      }

      print(
        'Auth registration successful for user ID: ${authResponse.user!.id}, email: $email',
      );

      // ایجاد پروفایل در جدول profiles
      final profileData = {
        'id': authResponse.user!.id, // Use auth user ID as profile ID
        'username': username,
        'phone_number': normalizedPhone,
        'email': email,
        'created_at': DateTime.now().toIso8601String(),
        'updated_at': DateTime.now().toIso8601String(),
      };

      print('Creating profile with data: $profileData');

      // Clear any existing profile entry (in case it exists but is incomplete)
      try {
        await client.from('profiles').delete().eq('id', authResponse.user!.id);
        print('Deleted any existing incomplete profile');
      } catch (e) {
        print('No existing profile to delete or error: $e');
      }

      // Create the profile
      try {
        final profileResponse = await client
            .from('profiles')
            .insert(profileData)
            .select();
        print('Profile creation response: $profileResponse');
      } catch (e) {
        print('Profile creation with select failed: $e');

        // Try without select
        try {
          await client.from('profiles').insert(profileData);
          print('Profile created without select');
        } catch (e2) {
          print('Profile creation without select also failed: $e2');
          return false;
        }
      }

      // Verify profile was created by checking if we can retrieve it
      try {
        final checkProfile = await client
            .from('profiles')
            .select()
            .eq('id', authResponse.user!.id)
            .maybeSingle();

        if (checkProfile == null) {
          print(
            'Profile verification failed - could not retrieve created profile',
          );
          return false;
        }

        print('Profile verified: $checkProfile');
        return true;
      } catch (e) {
        print('Profile verification error: $e');
        return false;
      }
    } catch (e) {
      print('Error in direct registration: $e');
      if (e is PostgrestException) {
        print(
          'PostgrestException details in direct registration: ${e.message}, code: ${e.code}, details: ${e.details}',
        );
      }
      return false;
    }
  }

  // بررسی وجود کاربر با استفاده از تابع RPC
  Future<bool> checkUserExistsRPC(String phoneNumber) async {
    try {
      // Normalize phone number
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Checking if user exists with RPC: $normalizedPhone');
      final result = await client.rpc<bool>(
        'check_user_exists',
        params: {'phone': normalizedPhone},
      );
      print('RPC check result: $result');
      return result;
      if (result is Map) {
        final boolResult =
            (result as Map<String, dynamic>)['check_user_exists'];
        if (boolResult is bool) return boolResult;
      }
      // fallback direct query if RPC not deployed yet
      final profile = await client
          .from('profiles')
          .select('id')
          .eq('phone_number', normalizedPhone)
          .maybeSingle();
      return profile != null;
    } catch (e) {
      print('Error in RPC check: $e');
      return false;
    }
  }

  Future<UserProfile?> getProfileByEmail(String email) async {
    try {
      final response = await client
          .from('profiles')
          .select()
          .eq(
            'email',
            email,
          ) // Assuming your profiles table has an 'email' column
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting profile by email: $e');
      return null;
    }
  }

  Future<Session?> signInWithPhone(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      print('Attempting to sign in with phone number: $normalizedPhone');

      // بررسی وجود کاربر با شماره موبایل
      final userExists = await doesUserExist(normalizedPhone);
      print('User exists check: $userExists');

      if (!userExists) {
        print('User with phone number $normalizedPhone does not exist');
        throw Exception(
          'کاربری با این شماره موبایل یافت نشد. لطفاً ابتدا ثبت‌نام کنید.',
        );
      }

      final email = await getFakeEmailFromPhoneNumber(normalizedPhone);
      print('Using email for sign in: $email');

      try {
        // تلاش اول: استفاده از ایمیل دریافت شده (که احتمالاً از پروفایل می‌آید)
        final response = await Supabase.instance.client.auth.signInWithPassword(
          email: email,
          password: normalizedPhone,
        );

        print(
          'Sign in successful with primary email: ${response.session != null}',
        );

        // ذخیره session و اطمینان از وجود پروفایل
        if (response.session != null) {
          await AuthStateService().saveAuthState(
            response.session!,
            phoneNumber: phoneNumber,
          );
          await _ensureProfileForUser(response.session!, normalizedPhone);
        }

        return response.session;
      } catch (e) {
        print('Primary sign in failed: $e');

        // تلاش دوم: استفاده از ایمیل ساخته شده از شماره موبایل
        final phoneEmail =
            '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@example.com';
        if (email != phoneEmail) {
          print('Trying alternative email based on phone: $phoneEmail');
          try {
            final response = await Supabase.instance.client.auth
                .signInWithPassword(
                  email: phoneEmail,
                  password: normalizedPhone,
                );
            print(
              'Sign in successful with phone email: ${response.session != null}',
            );

            // ذخیره session و پروفایل
            if (response.session != null) {
              await AuthStateService().saveAuthState(
                response.session!,
                phoneNumber: phoneNumber,
              );
              await _ensureProfileForUser(response.session!, normalizedPhone);
            }

            return response.session;
          } catch (e2) {
            print('Phone-based email sign in failed: $e2');
            // رد کردن استثنا برای تلاش با روش‌های دیگر
          }
        }

        // تلاش سوم: بررسی پروفایل کاربر و استخراج نام کاربری برای ساخت ایمیل
        try {
          final profile = await client
              .from('profiles')
              .select('username')
              .eq('phone_number', normalizedPhone)
              .maybeSingle();

          if (profile != null && profile['username'] != null) {
            final username = profile['username'].toString();
            final usernameEmail =
                '${username.replaceAll(RegExp(r'[^\w\s]+'), '')}@example.com';

            if (email != usernameEmail && phoneEmail != usernameEmail) {
              print('Trying username-based email: $usernameEmail');
              try {
                final response = await Supabase.instance.client.auth
                    .signInWithPassword(
                      email: usernameEmail,
                      password: normalizedPhone,
                    );
                print(
                  'Sign in successful with username email: ${response.session != null}',
                );

                // ذخیره session و پروفایل
                if (response.session != null) {
                  await AuthStateService().saveAuthState(
                    response.session!,
                    phoneNumber: phoneNumber,
                  );
                  await _ensureProfileForUser(
                    response.session!,
                    normalizedPhone,
                  );
                }

                return response.session;
              } catch (e3) {
                print('Username-based email sign in failed: $e3');
              }
            }
          }
        } catch (e4) {
          print('Error retrieving profile for username: $e4');
        }

        // اگر تمام تلاش‌ها شکست خورد، خطای اصلی را رد کن
        rethrow;
      }
    } catch (e) {
      print('Error in signInWithPhone: $e');
      if (e is AuthException) {
        print('AuthException details: ${e.message}, status: ${e.statusCode}');
        if (e.statusCode == 'invalid_login_credentials') {
          throw Exception('نام کاربری یا رمز عبور اشتباه است.');
        }
      }
      rethrow;
    }
  }

  // تست اتصال پایگاه داده
  Future<bool> testDatabaseConnection() async {
    const maxRetries = 3;
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        await client.from('profiles').select('count').limit(1);
        print('Database connection: OK');
        return true;
      } catch (e) {
        print('Database connection failed (attempt $attempt): $e');
        if (attempt < maxRetries) {
          await Future<void>.delayed(Duration(seconds: attempt * 2));
        }
      }
    }
    print('Database connection failed after $maxRetries attempts');
    return false;
  }

  // روش جایگزین با Raw SQL
  Future<Session?> _registerWithRawSQL(
    String phoneNumber,
    String username,
  ) async {
    try {
      print('Using simplified registration method...');

      // تست اتصال دیتابیس
      await testDatabaseConnection();

      // استفاده از anonymous signup که ساده‌تر است
      print('Attempting anonymous registration...');

      final response = await client.auth.signInAnonymously();
      print('Anonymous auth response received');

      if (response.user != null) {
        print('Anonymous auth successful: ${response.user!.id}');

        // ایجاد email ساختگی برای پروفایل
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email =
            '${phoneNumber.replaceAll(RegExp(r'\D'), '')}_$timestamp@temp.gymaipro';

        // ایجاد پروفایل
        await _createProfileWithSQL(
          response.user!.id,
          username,
          phoneNumber,
          email,
        );

        // ذخیره session
        if (response.session != null) {
          await AuthStateService().saveAuthState(
            response.session!,
            phoneNumber: phoneNumber,
          );
          print('Session saved successfully');
        }

        return response.session;
      }

      throw Exception('Anonymous registration failed: user is null');
    } catch (e) {
      print('Simplified registration failed: $e');
      print('Error details: $e');
      // اگر همه چیز ناکام بود، دوباره anonymous امتحان می‌کنیم
      return _fallbackAnonymousRegistration(phoneNumber, username);
    }
  }

  // ایجاد پروفایل با SQL مستقیم
  Future<void> _createProfileWithSQL(
    String userId,
    String username,
    String phoneNumber,
    String email,
  ) async {
    try {
      print('Creating profile with direct insert...');

      // استفاده از insert مستقیم که با RLS policies سازگار است
      await client.from('profiles').insert({
        'id': userId,
        'username': username,
        'phone_number': phoneNumber,
        'email': email,
        'role': 'athlete',
      });

      print('Profile created successfully with direct insert');
    } catch (e) {
      print('Direct insert failed: $e');

      // اگر insert مستقیم هم شکست خورد، از raw SQL استفاده می‌کنیم
      try {
        print('Trying raw SQL as fallback...');
        await client.rpc<void>(
          'exec_sql',
          params: {
            'sql':
                '''
            INSERT INTO public.profiles (id, username, phone_number, email, role, created_at, updated_at)
            VALUES (
              '${userId.replaceAll("'", "''")}',
              '${username.replaceAll("'", "''")}',
              '${phoneNumber.replaceAll("'", "''")}',
              '${email.replaceAll("'", "''")}',
              'athlete',
              NOW(),
              NOW()
            )
            ON CONFLICT (id) DO NOTHING;
          ''',
          },
        );
        print('Profile created with raw SQL fallback');
      } catch (sqlError) {
        print('Raw SQL fallback also failed: $sqlError');
        rethrow;
      }
    }
  }

  // روش نهایی: Anonymous registration
  Future<Session?> _fallbackAnonymousRegistration(
    String phoneNumber,
    String username,
  ) async {
    try {
      print('Final fallback: Anonymous registration...');

      // تست اتصال دیتابیس
      await testDatabaseConnection();

      final response = await client.auth.signInAnonymously();
      print('Final anonymous auth response received');

      if (response.user != null) {
        print('Final anonymous registration successful: ${response.user!.id}');

        // ایجاد email ساختگی برای پروفایل
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final email =
            '${phoneNumber.replaceAll(RegExp(r'\D'), '')}_fallback_$timestamp@temp.gymaipro';

        // ایجاد پروفایل برای anonymous user
        await _createProfileWithSQL(
          response.user!.id,
          username,
          phoneNumber,
          email,
        );

        // ذخیره session
        if (response.session != null) {
          await AuthStateService().saveAuthState(
            response.session!,
            phoneNumber: phoneNumber,
          );
          print('Final session saved successfully');
        }

        return response.session;
      }

      throw Exception('Final anonymous registration failed: user is null');
    } catch (e) {
      print('Final anonymous registration failed: $e');
      print('Final error details: $e');
      throw Exception(
        'همه روش‌های ثبت‌نام ناکام بودند. لطفاً مدیر سیستم را در جریان قرار دهید.',
      );
    }
  }

  Future<Session?> signUpWithPhone(String phoneNumber, String username) async {
    try {
      print('=== DEBUG: Starting signUpWithPhone ===');
      print('Phone: $phoneNumber');
      print('Username: $username');

      // تست اتصال
      await testDatabaseConnection();

      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      print('Normalized phone: $normalizedPhone');

      // روش جدید: استفاده از raw SQL به جای Auth
      return await _registerWithRawSQL(normalizedPhone, username);
    } catch (e) {
      print('Error in signUpWithPhone: $e');
      rethrow;
    }
  }

  // تابع کمکی برای ایجاد پروفایل در صورت عدم وجود
  Future<bool> ensureProfileExists(
    String userId, {
    String? username,
    String? phoneNumber,
  }) async {
    try {
      // بررسی وجود پروفایل
      final existingProfile = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile != null) {
        print('Profile already exists for user: $userId');
        return true;
      }

      // اگر پروفایل وجود نداره، سعی کن بسازیش
      print('Profile not found for user: $userId, creating...');

      final profileData = {
        'id': userId,
        'username': username ?? 'user_${userId.substring(0, 8)}',
        'phone_number': phoneNumber ?? '',
        'role': 'athlete', // تنظیم role پیش‌فرض
      };

      // اضافه کردن email اگر phoneNumber موجود باشه
      if (phoneNumber != null && phoneNumber.isNotEmpty) {
        profileData['email'] =
            '${phoneNumber.replaceAll(RegExp(r'\D'), '')}@temp.local';
      }

      await client.from('profiles').insert(profileData);
      print('Profile created successfully for user: $userId');
      return true;
    } catch (e) {
      print('Error ensuring profile exists: $e');
      return false;
    }
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().toIso8601String()}.$fileExt';
      final filePath =
          'public/$fileName'; // Standard path for public access if needed

      await client.storage.from('profile_images').upload(filePath, imageFile);

      final imageUrlResponse = client.storage
          .from('profile_images')
          .getPublicUrl(filePath);
      // The new updateProfile function expects userId (which is auth user id)
      // and a map of data.
      // Ensure 'avatar_url' is a column in your 'profiles' table.
      await SimpleProfileService.updateProfile({
        'avatar_url': imageUrlResponse,
      });
      return imageUrlResponse;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  // Profile-related methods moved to ProfileService
  // Use ProfileService.getProfileByAuthId() instead

  // Profile-related methods moved to ProfileService
  // Use ProfileService.createInitialProfile() instead

  // اضافه کردن داده‌های فرضی وزن برای تست
  Future<void> addSampleWeightData(String profileId) async {
    try {
      final now = DateTime.now();

      // ابتدا چک کنیم آیا جدول weight_records وجود دارد
      try {
        // اول همه رکوردهای قبلی را حذف می‌کنیم
        await client
            .from('weight_records')
            .delete()
            .eq('profile_id', profileId);
        print('رکوردهای قبلی وزن با موفقیت حذف شدند');
      } catch (e) {
        print('خطا در حذف رکوردهای قبلی: $e');
        // ادامه می‌دهیم حتی اگر حذف ناموفق بود
      }

      // ایجاد چندین رکورد وزن با تاریخ‌های مختلف (از گذشته تا امروز)
      final sampleData = [
        {
          'profile_id': profileId,
          'weight': 85.5,
          'recorded_at': now
              .subtract(const Duration(days: 60))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 84.2,
          'recorded_at': now
              .subtract(const Duration(days: 50))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 83.0,
          'recorded_at': now
              .subtract(const Duration(days: 40))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 82.1,
          'recorded_at': now
              .subtract(const Duration(days: 30))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 81.3,
          'recorded_at': now
              .subtract(const Duration(days: 20))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 80.5,
          'recorded_at': now
              .subtract(const Duration(days: 10))
              .toIso8601String(),
        },
        {
          'profile_id': profileId,
          'weight': 79.8,
          'recorded_at': now.toIso8601String(),
        },
      ];

      print('تلاش برای اضافه کردن ${sampleData.length} رکورد وزن...');

      // اضافه کردن هر رکورد به صورت تکی برای مدیریت بهتر خطاها
      for (int i = 0; i < sampleData.length; i++) {
        try {
          await client.from('weight_records').insert(sampleData[i]);
          print(
            'رکورد ${i + 1} با موفقیت اضافه شد: ${sampleData[i]['weight']} کیلوگرم',
          );
        } catch (e) {
          print('خطا در اضافه کردن رکورد ${i + 1}: $e');
          // ادامه می‌دهیم با رکورد بعدی
        }
      }

      print('داده‌های فرضی وزن با موفقیت اضافه شدند');
    } catch (e) {
      print('خطا در افزودن داده‌های فرضی وزن: $e');
      rethrow;
    }
  }
}
