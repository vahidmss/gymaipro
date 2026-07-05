import 'package:gymaipro/dashboard/services/dashboard_cache_service.dart' show DashboardCacheService;

/// Maps a raw Supabase profile row to the shape stored in [DashboardCacheService].
class DashboardProfileMapper {
  DashboardProfileMapper._();

  static Map<String, dynamic> fromRaw(
    Map<String, dynamic> profileData, {
    double? latestWeight,
  }) {
    return {
      'id': profileData['id'] ?? '',
      'first_name': profileData['first_name'] ?? '',
      'last_name': profileData['last_name'] ?? '',
      'height': profileData['height']?.toString() ?? '0',
      'weight': profileData['weight']?.toString() ?? '0',
      'arm_circumference': profileData['arm_circumference']?.toString() ?? '',
      'chest_circumference':
          profileData['chest_circumference']?.toString() ?? '',
      'waist_circumference':
          profileData['waist_circumference']?.toString() ?? '',
      'hip_circumference': profileData['hip_circumference']?.toString() ?? '',
      'experience_level': profileData['experience_level'] ?? '',
      'preferred_training_days':
          profileData['preferred_training_days']?.join(',') ?? '',
      'preferred_training_time': profileData['preferred_training_time'] ?? '',
      'fitness_goals': profileData['fitness_goals']?.join(',') ?? '',
      'medical_conditions': profileData['medical_conditions']?.join(',') ?? '',
      'dietary_preferences':
          profileData['dietary_preferences']?.join(',') ?? '',
      'birth_date': profileData['birth_date']?.toString() ?? '',
      'gender': profileData['gender'] ?? 'male',
      'activity_level': profileData['activity_level'] ?? 'moderate',
      'weight_history': (profileData['weight_history'] as List<dynamic>?) ?? [],
      'username': profileData['username'] ?? '',
      'phone_number': profileData['phone_number'] ?? '',
      'avatar_url': profileData['avatar_url'] ?? '',
      'role': profileData['role'] ?? 'athlete',
      'latest_weight': latestWeight,
      'login_streak': (profileData['login_streak'] as num?)?.toInt() ?? 0,
    };
  }
}
