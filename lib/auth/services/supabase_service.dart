import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// وقتی آدرس Supabase درست است اما env `SUPABASE_ANON_KEY` مربوط به همان سرور
/// نیست (مثلاً کلید پروژهٔ ابری مانده) و API با 401 برمی‌گردد.
class SupabaseBackendAuthException implements Exception {
  SupabaseBackendAuthException(this.message);
  final String message;
  @override
  String toString() => message;
}

const String _kAnonKeyMismatchUserMessage =
    'سرور در دسترس است اما کلید SUPABASE_ANON_KEY با سرور داخلی هماهنگ نیست '
    '(خطای 401). در فایل .env پروژه، مقدار ANON_KEY را از سرور (فایل .env داکر '
    'Supabase یا خروجی supabase status) کپی کنید و اپ را دوباره اجرا کنید.';

bool _isInvalidSupabaseApiKey(Object e) {
  if (e is PostgrestException) {
    final c = e.code?.toString() ?? '';
    if (c == '401') return true;
    if (e.message.contains('Invalid authentication credentials')) return true;
  }
  final s = e.toString();
  return s.contains('Invalid authentication credentials') &&
      (s.contains('401') || s.contains('Unauthorized'));
}

class SupabaseService {
  static final SupabaseClient client = Supabase.instance.client;

  /// Build email for auth from phone or username
  String _emailForAuth({required String normalizedPhone, String? username}) {
    final localPart = normalizedPhone.isNotEmpty
        ? normalizedPhone.replaceAll(RegExp(r'\D'), '')
        : (username ?? 'user');
    return '${localPart.toLowerCase()}@gym.ai';
  }

  /// Normalize phone number format (delegates to PhoneUtils)
  String normalizePhoneNumber(String phoneNumber) {
    return PhoneUtils.normalize(phoneNumber);
  }

  /// Check username uniqueness with timeout so weak network doesn't hang the UI.
  static const Duration _usernameCheckTimeout = Duration(seconds: 8);

  Future<bool> isUsernameUnique(String username) async {
    try {
      return await Future<bool>(() async {
        await client.from('profiles').select('count').limit(1);
        final response = await client
            .from('profiles')
            .select('id')
            .eq('username', username)
            .maybeSingle();
        return response == null;
      }).timeout(
        _usernameCheckTimeout,
        onTimeout: () => throw TimeoutException(
          'Username check timed out',
          _usernameCheckTimeout,
        ),
      );
    } on TimeoutException {
      rethrow;
    } catch (e) {
      if (kDebugMode) debugPrint('isUsernameUnique error: $e');
      rethrow;
    }
  }

  /// Check if user exists (with timeout so weak network doesn't hang).
  static const Duration _doesUserExistTimeout = Duration(seconds: 8);

  // نکته: تابع دیتابیس check_user_exists(phone TEXT) پارامتر «phone» می‌گیرد، نه phone_number
  Future<bool> doesUserExist(String phoneNumber) async {
    try {
      return await Future<bool>(() async {
        final normalizedPhone = normalizePhoneNumber(phoneNumber);

        try {
          final result = await client.rpc<bool>(
            'check_user_exists',
            params: {'phone': normalizedPhone},
          );
          return result == true;
        } catch (e) {
          if (_isInvalidSupabaseApiKey(e)) {
            throw SupabaseBackendAuthException(_kAnonKeyMismatchUserMessage);
          }
        }

        final digits =
            normalizedPhone.replaceAll(RegExp(r'[^\d]'), '');
        final noLeadingZero =
            digits.startsWith('0') ? digits.substring(1) : digits;
        final candidates = [
          normalizedPhone,
          digits,
          '+98$noLeadingZero',
          '98$noLeadingZero',
          noLeadingZero,
        ];

        for (final candidate in candidates) {
          if (candidate.isEmpty) continue;
          try {
            final row = await client
                .from('profiles')
                .select('id')
                .eq('phone_number', candidate)
                .maybeSingle();
            if (row != null) return true;
          } catch (e) {
            if (_isInvalidSupabaseApiKey(e)) {
              throw SupabaseBackendAuthException(_kAnonKeyMismatchUserMessage);
            }
            continue;
          }
        }
        return false;
      }).timeout(
        _doesUserExistTimeout,
        onTimeout: () => false,
      );
    } on SupabaseBackendAuthException {
      rethrow;
    } catch (_) {
      return false;
    }
  }

  /// Register user with phone number
  Future<Session?> signUpWithPhone(String phoneNumber, String username) async {
    try {
      try {
        await testDatabaseConnection();
      } catch (e) {
        debugPrint('signUpWithPhone: DB probe failed, continuing: $e');
      }
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      return await _registerRealUser(normalizedPhone, username);
    } catch (e) {
      debugPrint('Error in signUpWithPhone: $e');
      rethrow;
    }
  }

  /// Register user with normalized phone and username
  Future<Session?> _registerRealUser(
    String phoneNumber,
    String username,
  ) async {
    final normalized = phoneNumber.replaceAll(RegExp(r'\D'), '');
    final email = _emailForAuth(
      normalizedPhone: normalized,
      username: username,
    );
    final password = normalized;

    // Try signUp first
    try {
      final res = await client.auth.signUp(email: email, password: password);
      if (res.session != null) {
        await _ensureProfile(res.session!.user.id, username, phoneNumber, email);
        return res.session;
      }
      // If no session, try signIn (email confirmation might be required)
      final signInRes = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      if (signInRes.session != null) {
        await _ensureProfile(
          signInRes.session!.user.id,
          username,
          phoneNumber,
          email,
        );
        return signInRes.session;
      }
    } catch (e) {
      // If signUp fails (e.g., email exists), try signIn
      try {
        final signInRes = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (signInRes.session != null) {
          await _ensureProfile(
            signInRes.session!.user.id,
            username,
            phoneNumber,
            email,
          );
          return signInRes.session;
        }
      } catch (_) {
        // If signIn also fails, try alternative email
        final parts = email.split('@');
        final altEmail = '${parts.first}-1@${parts.last}';
        try {
          final altRes = await client.auth.signUp(
            email: altEmail,
            password: password,
          );
          if (altRes.session != null) {
            await _ensureProfile(
              altRes.session!.user.id,
              username,
              phoneNumber,
              altEmail,
            );
            return altRes.session;
          }
          final altSignIn = await client.auth.signInWithPassword(
            email: altEmail,
            password: password,
          );
          if (altSignIn.session != null) {
            await _ensureProfile(
              altSignIn.session!.user.id,
              username,
              phoneNumber,
              altEmail,
            );
            return altSignIn.session;
          }
        } catch (_) {
          // All attempts failed
        }
      }
      rethrow;
    }
    return null;
  }

  /// Ensure profile exists for user
  Future<void> _ensureProfile(
    String userId,
    String username,
    String phoneNumber,
    String email,
  ) async {
    try {
      // Check if profile already exists
      final existing = await client
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();
      if (existing != null) return;

      // Check username uniqueness and generate alternative if needed
      String finalUsername = username;
      try {
        final nameExists = await client
            .from('profiles')
            .select('id')
            .eq('username', finalUsername)
            .maybeSingle();
        if (nameExists != null) {
          final suffix = DateTime.now().millisecondsSinceEpoch % 10000;
          finalUsername = '${finalUsername}_$suffix';
        }
      } catch (_) {
        // Continue with original username on error
      }

      // Insert new profile
      try {
        await client.from('profiles').insert({
          'id': userId,
          'username': finalUsername,
          'phone_number': phoneNumber,
          'email': email,
          'role': 'athlete',
        });
      } on PostgrestException catch (e) {
        if (e.code != '23505') rethrow; // Ignore duplicate key error
      }
    } catch (e) {
      debugPrint('Error ensuring profile: $e');
      rethrow;
    }
  }

  /// Test database connection
  Future<void> testDatabaseConnection({
    Duration timeout = const Duration(seconds: 6),
  }) async {
    try {
      await client
          .from('profiles')
          .select('count')
          .limit(1)
          .timeout(timeout);
    } catch (e) {
      throw Exception('Database connection failed: $e');
    }
  }

  /// Sign in with phone number
  Future<Session?> signInWithPhone(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);
      if (!await doesUserExist(normalizedPhone)) {
        throw Exception(
          'User with phone number $normalizedPhone does not exist',
        );
      }

      // Get profile data
      final prof = await client
          .from('profiles')
          .select()
          .eq('phone_number', normalizedPhone)
          .maybeSingle();

      final normalizedDigits = normalizedPhone.replaceAll(RegExp(r'\D'), '');
      final emailFromProfile = prof?['email'] as String?;
      final targetEmail = (emailFromProfile?.trim().isNotEmpty ?? false)
          ? emailFromProfile!.trim()
          : _emailForAuth(normalizedPhone: normalizedDigits);

      final candidatePasswords = <String>{
        normalizedDigits,
        normalizedDigits.replaceFirst(RegExp('^0+'), ''),
      }.where((p) => p.isNotEmpty).toList();

      // Try signIn with candidate passwords
      for (final pw in candidatePasswords) {
        try {
          final res = await client.auth.signInWithPassword(
            email: targetEmail,
            password: pw,
          );
          if (res.session != null) {
            // Link profile to auth user if IDs differ
            if (prof != null) {
              final existingProfileId = (prof['id'] ?? '').toString();
              if (existingProfileId.isNotEmpty &&
                  existingProfileId != res.session!.user.id) {
                try {
                  await client
                      .from('profiles')
                      .update({'auth_user_id': res.session!.user.id})
                      .eq('id', existingProfileId);
                } catch (_) {
                  // Ignore update errors
                }
              }
            }
            return res.session;
          }
        } catch (_) {
          continue;
        }
      }

      // If signIn failed, try signUp for existing profile
      if (prof != null && targetEmail.isNotEmpty) {
        try {
          final pw = normalizedDigits;
          final up = await client.auth.signUp(email: targetEmail, password: pw);
          final Session? newSession = up.session ?? (await client.auth.signInWithPassword(
            email: targetEmail,
            password: pw,
          )).session;

          if (newSession != null) {
            final existingProfileId = (prof['id'] ?? '').toString();
            if (existingProfileId.isNotEmpty) {
              try {
                await client
                    .from('profiles')
                    .update({'auth_user_id': newSession.user.id})
                    .eq('id', existingProfileId);
              } catch (_) {
                // Ignore update errors
              }
            }
            return newSession;
          }
        } catch (_) {
          // Fall through to error
        }
      }

      throw Exception(
        'ورود ناموفق بود: اکانت مربوط به این شماره پیدا نشد یا پسورد هم‌خوانی ندارد.',
      );
    } catch (e) {
      debugPrint('Error in signInWithPhone: $e');
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

  // Upload profile image (bytes — works on web and native).
  Future<String?> uploadProfileImageBytes(
    String userId,
    Uint8List bytes, {
    String extension = 'jpg',
    String mimeType = 'image/jpeg',
  }) async {
    try {
      final fileName =
          '$userId-${DateTime.now().toIso8601String()}.$extension';
      final filePath = 'public/$fileName';

      await client.storage.from('profile_images').uploadBinary(
            filePath,
            bytes,
            fileOptions: FileOptions(contentType: mimeType, upsert: true),
          );

      final imageUrlResponse = client.storage
          .from('profile_images')
          .getPublicUrl(filePath);

      final updated = await SimpleProfileService.updateProfile(
        {'avatar_url': imageUrlResponse},
      );
      if (!updated) {
        throw Exception('به‌روزرسانی پروفایل در دیتابیس انجام نشد');
      }
      return imageUrlResponse;
    } catch (e) {
      if (kDebugMode) {
        // ignore: avoid_print
        print('Error uploading profile image: $e');
      }
      rethrow;
    }
  }

  // Upload profile image from filesystem (native).
  Future<String?> uploadProfileImage(String userId, File imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final fileExt = imageFile.path.split('.').last.toLowerCase();
    final mime = fileExt == 'png' ? 'image/png' : 'image/jpeg';
    return uploadProfileImageBytes(
      userId,
      bytes,
      extension: fileExt == 'png' ? 'png' : 'jpg',
      mimeType: mime,
    );
  }
}
