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
      return null;
    }
  }

  // دریافت نام نمایشی کاربر
  Future<String> getDisplayName(String userId) async {
    try {
      final profile = await getUserProfile(userId);
      if (profile != null) {
        if (profile.firstName != null && profile.lastName != null) {
          return '${profile.firstName} ${profile.lastName}';
        } else if (profile.firstName != null) {
          return profile.firstName!;
        } else if (profile.lastName != null) {
          return profile.lastName!;
        } else if (profile.username.isNotEmpty) {
          return profile.username;
        } else if (profile.phoneNumber != null &&
            profile.phoneNumber!.isNotEmpty) {
          return profile.phoneNumber!.replaceRange(0, 7, '***');
        } else {
          return 'کاربر ناشناس';
        }
      }
      return 'کاربر ناشناس';
    } catch (e) {
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
