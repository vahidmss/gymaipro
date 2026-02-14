import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/auth/utils/phone_utils.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  // نکته: تابع دیتابیس check_user_exists(phone TEXT) پارامتر «phone» می‌گیرد، نه phone_number
  Future<bool> doesUserExist(String phoneNumber) async {
    try {
      final normalizedPhone = normalizePhoneNumber(phoneNumber);

      // ۱) RPC با نام پارامتر درست (مطابق تابع SQL: check_user_exists(phone TEXT))
      try {
        final result = await client.rpc<bool>(
          'check_user_exists',
          params: {'phone': normalizedPhone},
        );
        return result == true;
      } catch (_) {
        // در صورت خطای RPC (مثلاً تابع وجود ندارد یا شبکه) به fallback می‌رویم
      }

      // ۲) Fallback: جستجو با چند فرمت رایج شماره در جدول profiles
      final digits = normalizedPhone.replaceAll(RegExp(r'[^\d]'), '');
      final noLeadingZero = digits.startsWith('0') ? digits.substring(1) : digits;
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
        } catch (_) {
          continue;
        }
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Register user with phone number
  Future<Session?> signUpWithPhone(String phoneNumber, String username) async {
    try {
      await testDatabaseConnection();
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
  Future<void> testDatabaseConnection() async {
    try {
      await client.from('profiles').select('count').limit(1);
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
      final targetEmail = (emailFromProfile?.trim().isNotEmpty == true)
          ? emailFromProfile!.trim()
          : _emailForAuth(normalizedPhone: normalizedDigits);

      final candidatePasswords = <String>{
        normalizedDigits,
        normalizedDigits.replaceFirst(RegExp(r'^0+'), ''),
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
          Session? newSession = up.session ?? (await client.auth.signInWithPassword(
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

      await SimpleProfileService.updateProfile({
        'avatar_url': imageUrlResponse,
      });
      return imageUrlResponse;
    } catch (e) {
      return null;
    }
  }
}
