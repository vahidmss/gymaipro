import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/profile_model.dart'; // Removed this line
import '../models/weight_record_model.dart';
import '../models/user_profile.dart';
import 'dart:io';

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
  // Future<Profile> createProfile(String username, String phoneNumber) async {
  //   try {
  //     // Normalize phone number
  //     final normalizedPhone = normalizePhoneNumber(phoneNumber);

  //     // ابتدا کاربر را در سیستم احراز هویت ثبت‌نام می‌کنیم
  //     await registerUserAfterOTP(username, normalizedPhone);

  //     // سپس پروفایل را دریافت می‌کنیم
  //     final response = await _client
  //         .from('profiles')
  //         .select()
  //         .eq('username', username)
  //         .single();

  //     return Profile.fromJson(response);
  //   } catch (e) {
  //     print('Error creating profile: $e');
  //     rethrow;
  //   }
  // }

  // Future<Profile?> getProfile(String id) async {
  //   final response =
  //       await _client.from('profiles').select().eq('id', id).single();

  //   return response != null ? Profile.fromJson(response) : null;
  // }

  Future<void> updateProfile(String userId, Map<String, dynamic> data) async {
    try {
      await _client.from('profiles').update(data).eq('id', userId);
    } catch (e) {
      print('Error updating profile: $e');
      rethrow;
    }
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

      // اول دریافت تمام پروفایل‌ها برای دیباگ
      final allProfiles = await getAllProfiles();
      print('Debugging: Found ${allProfiles.length} total profiles');
      for (var profile in allProfiles) {
        print(
            'Profile: ${profile['username']} - ${profile['phone_number']} - ${profile['id']} - email: ${profile['email']}');
      }

      // جستجوی کاربر با شماره موبایل
      final response = await _client
          .from('profiles')
          .select('*') // دریافت تمام فیلدها برای دیباگ
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      print('Profile lookup raw response: $response');

      if (response != null) {
        // اگر ایمیل در پروفایل وجود داشته باشد، از آن استفاده کن
        if (response['email'] != null &&
            response['email'].toString().isNotEmpty) {
          print('Using existing email from profile: ${response['email']}');
          return response['email'];
        }

        // اگر ایمیل در پروفایل نبود، از الگوی شماره موبایل استفاده کن - نه نام کاربری
        String email =
            '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@example.com';
        print('Generated email based on phone number: $email');
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
      if (e is PostgrestException) {
        print(
            'PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}');
      }
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
      final response = await _client
          .from('profiles')
          .select()
          // .eq('phone_number', normalizedPhone) // Use normalizedPhone for lookup
          .eq('phone_number',
              phoneNumber) // TODO: Re-evaluate if normalization is needed based on how numbers are stored
          .maybeSingle(); // Use maybeSingle to handle 0 or 1 record gracefully

      if (response == null) {
        print(
            'No profile found for phone number: $phoneNumber. Attempting manual check if enabled.');
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
        password: normalizedPhone, // Consider a stronger password strategy
      );

      if (authResponse.user == null) {
        print('Auth registration failed for email: $email');
        return false;
      }

      print(
          'Auth registration successful for user ID: ${authResponse.user!.id}, email: $email');

      // ایجاد پروفایل در جدول profiles
      // Ensure this matches the structure expected by createInitialProfile and RLS policies
      final profileData = {
        'id': authResponse.user!.id, // Crucial: Link to auth user
        'username': username,
        'phone_number': normalizedPhone,
        'email': email, // Store the email used for auth
        // 'created_at' and 'updated_at' should be handled by db defaults/triggers
      };

      final profileInsertResponse = await _client
          .from('profiles')
          .insert(profileData)
          .select(); // select() fetches the inserted row(s)

      if (profileInsertResponse.isEmpty) {
        print(
            'Profile creation failed after auth. Response: $profileInsertResponse');
        // Consider if user should be deleted from auth if profile creation fails, or other cleanup.
        return false;
      }

      print('Profile created directly: $profileInsertResponse');
      return true;
    } catch (e) {
      print('Error in direct registration: $e');
      if (e is PostgrestException) {
        print(
            'PostgrestException details in direct registration: ${e.message}, code: ${e.code}, details: ${e.details}');
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

  Future<UserProfile?> getProfileByEmail(String email) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('email',
              email) // Assuming your profiles table has an 'email' column
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
            'کاربری با این شماره موبایل یافت نشد. لطفاً ابتدا ثبت‌نام کنید.');
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
            'Sign in successful with primary email: ${response.session != null}');
        return response.session;
      } catch (e) {
        print('Primary sign in failed: $e');

        // تلاش دوم: استفاده از ایمیل ساخته شده از شماره موبایل
        final phoneEmail =
            '${normalizedPhone.replaceAll(RegExp(r'\D'), '')}@example.com';
        if (email != phoneEmail) {
          print('Trying alternative email based on phone: $phoneEmail');
          try {
            final response =
                await Supabase.instance.client.auth.signInWithPassword(
              email: phoneEmail,
              password: normalizedPhone,
            );
            print(
                'Sign in successful with phone email: ${response.session != null}');
            return response.session;
          } catch (e2) {
            print('Phone-based email sign in failed: $e2');
            // رد کردن استثنا برای تلاش با روش‌های دیگر
          }
        }

        // تلاش سوم: بررسی پروفایل کاربر و استخراج نام کاربری برای ساخت ایمیل
        try {
          final profile = await _client
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
                final response =
                    await Supabase.instance.client.auth.signInWithPassword(
                  email: usernameEmail,
                  password: normalizedPhone,
                );
                print(
                    'Sign in successful with username email: ${response.session != null}');
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

  Future<Session?> signUpWithPhone(String phoneNumber, String username) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      final email = await getFakeEmailFromPhoneNumber(normalizedPhone);

      // ثبت‌نام کاربر
      final response = await Supabase.instance.client.auth.signUp(
        email: email,
        password: normalizedPhone,
      );

      if (response.user != null) {
        // ایجاد پروفایل کاربر
        await Supabase.instance.client.from('profiles').insert({
          'id': response.user!.id,
          'username': username,
          'phone_number': normalizedPhone,
          'created_at': DateTime.now().toIso8601String(),
        });
      }

      return response.session;
    } catch (e) {
      print('Error in signUpWithPhone: $e');
      rethrow;
    }
  }

  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    try {
      final fileExt = imageFile.path.split('.').last;
      final fileName = '$userId-${DateTime.now().toIso8601String()}.$fileExt';
      final filePath =
          'public/$fileName'; // Standard path for public access if needed

      await _client.storage.from('profile_images').upload(
            filePath,
            imageFile,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: false),
          );

      final imageUrlResponse =
          _client.storage.from('profile_images').getPublicUrl(filePath);
      // The new updateProfile function expects userId (which is auth user id)
      // and a map of data.
      // Ensure 'avatar_url' is a column in your 'profiles' table.
      await updateProfile(userId, {'avatar_url': imageUrlResponse});
      return imageUrlResponse;
    } catch (e) {
      print('Error uploading profile image: $e');
      return null;
    }
  }

  Future<UserProfile?> getProfileByAuthId() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return null;
      final response = await _client
          .from('profiles')
          .select()
          .eq('id',
              user.id) // Assuming 'id' in profiles table is the auth user_id
          .maybeSingle();
      if (response == null) return null;
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error getting profile by auth id: $e');
      return null;
    }
  }

  // Creates a profile entry if one doesn't exist for the new user.
  // This is typically called after successful signup.
  Future<UserProfile?> createInitialProfile(User user, String phoneNumber,
      {String? username}) async {
    try {
      // Check if a profile already exists for this user ID to prevent duplicates
      final existingProfile = await _client
          .from('profiles')
          .select('id')
          .eq('id', user.id)
          .maybeSingle();

      if (existingProfile != null) {
        print('Profile already exists for user ${user.id}. Skipping creation.');
        // Optionally, load and return the existing profile
        return getProfileByAuthId();
      }

      // Create a new profile
      // The 'id' for the profiles table should be the user.id from auth.users
      // 'phone_number' is collected during registration
      // 'email' might be user.email
      // 'username' could be derived or set initially
      final Map<String, dynamic> profileData = {
        'id': user.id,
        'phone_number': phoneNumber,
        'email': user.email, // Store email from auth if available
        // 'username': username ?? user.email?.split('@').first, // Example username
      };
      if (username != null && username.isNotEmpty) {
        profileData['username'] = username;
      }

      final response =
          await _client.from('profiles').insert(profileData).select().single();

      print('Initial profile created successfully: $response');
      return UserProfile.fromJson(response);
    } catch (e) {
      print('Error creating initial profile: $e');
      if (e is PostgrestException) {
        print(
            'PostgrestException details: ${e.message}, code: ${e.code}, details: ${e.details}');
      }
      return null;
    }
  }
}
