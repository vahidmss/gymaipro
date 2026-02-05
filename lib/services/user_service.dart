import 'package:flutter/foundation.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // دریافت پروفایل کاربر بر اساس ID
  Future<UserProfile?> getUserProfile(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .single();

      return UserProfile.fromJson(response);
    } catch (e) {
      debugPrint('⚠️ Error getting user profile for $userId: $e');
      return null;
    }
  }

  // دریافت نام نمایشی کاربر
  Future<String> getDisplayName(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        if (profile.firstName != null && profile.lastName != null) {
          final name = '${profile.firstName} ${profile.lastName}'.trim();
          if (name.isNotEmpty) return name;
        }
        if (profile.firstName != null && profile.firstName!.isNotEmpty) {
          return profile.firstName!;
        }
        if (profile.lastName != null && profile.lastName!.isNotEmpty) {
          return profile.lastName!;
        }
        if (profile.username.isNotEmpty) {
          return profile.username;
        }
        if (profile.phoneNumber != null &&
            profile.phoneNumber!.isNotEmpty) {
          return profile.phoneNumber!.replaceRange(0, 7, '***');
        }
        debugPrint('⚠️ User $userId has no display name fields');
        return 'کاربر ناشناس';
      }
      debugPrint('⚠️ Profile not found for user: $userId');
      return 'کاربر ناشناس';
    } catch (e) {
      debugPrint('⚠️ Error getting display name for $userId: $e');
      return 'کاربر ناشناس';
    }
  }

  // دریافت آواتار کاربر
  Future<String?> getUserAvatar(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.avatarUrl;
    } catch (e) {
      return null;
    }
  }

  // دریافت نقش کاربر
  Future<String> getUserRole(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      return profile?.role ?? 'athlete';
    } catch (e) {
      return 'athlete';
    }
  }
}
