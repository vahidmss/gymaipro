import 'package:flutter/foundation.dart';
import 'package:gymaipro/dashboard/services/dashboard_profile_mapper.dart';

/// Lightweight hydrate bag for the dashboard shell (profile + display fields).
/// Section lists (articles / foods / weight history) stay in their own caches.
@immutable
class DashboardSnapshot {
  const DashboardSnapshot({
    required this.profileData,
    required this.username,
    required this.userRole,
    this.latestWeight,
  });

  factory DashboardSnapshot.fromProfileMap(Map<String, dynamic> profile) {
    final latest = profile['latest_weight'];
    return DashboardSnapshot(
      profileData: Map<String, dynamic>.from(profile),
      username: displayNameOf(profile),
      userRole: (profile['role'] as String?) ?? 'athlete',
      latestWeight: latest is num ? latest.toDouble() : null,
    );
  }

  factory DashboardSnapshot.fromRaw(
    Map<String, dynamic> raw, {
    double? latestWeight,
  }) {
    return DashboardSnapshot.fromProfileMap(
      DashboardProfileMapper.fromRaw(raw, latestWeight: latestWeight),
    );
  }

  factory DashboardSnapshot.empty() {
    return DashboardSnapshot.fromProfileMap(const {
      'first_name': '',
      'last_name': '',
      'height': '0',
      'weight': '0',
      'arm_circumference': '',
      'chest_circumference': '',
      'waist_circumference': '',
      'hip_circumference': '',
      'experience_level': '',
      'preferred_training_days': '',
      'preferred_training_time': '',
      'fitness_goals': '',
      'medical_conditions': '',
      'dietary_preferences': '',
      'birth_date': '',
      'gender': 'male',
      'activity_level': 'moderate',
      'weight_history': <dynamic>[],
      'username': '',
      'phone_number': '',
      'avatar_url': '',
      'role': 'athlete',
      'login_streak': 0,
    });
  }

  final Map<String, dynamic> profileData;
  final String username;
  final String userRole;
  final double? latestWeight;

  String? get avatarUrl {
    final value = profileData['avatar_url']?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  String? get userId {
    final value = profileData['id']?.toString();
    if (value == null || value.isEmpty) return null;
    return value;
  }

  int get loginStreak =>
      (profileData['login_streak'] as num?)?.toInt() ?? 0;

  static String displayNameOf(Map<String, dynamic> profileData) {
    final firstName = (profileData['first_name'] ?? '').toString();
    final lastName = (profileData['last_name'] ?? '').toString();
    final username = (profileData['username'] ?? '').toString();
    final phone = (profileData['phone_number'] ?? '').toString();
    final email = (profileData['email'] ?? '').toString();

    final fullName = '$firstName $lastName'.trim();
    if (fullName.isNotEmpty) return fullName;
    if (username.isNotEmpty) return username;
    if (phone.isNotEmpty) return phone;
    if (email.isNotEmpty) return email.split('@').first;
    return 'کاربر عزیز';
  }
}
