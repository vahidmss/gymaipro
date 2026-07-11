import 'package:gymaipro/profile/repositories/profile_repository.dart';

/// Read-only adapter for profile rows.
class ProfileContextAdapter {
  ProfileContextAdapter({ProfileRepository? profileRepository})
    : _profileRepository = profileRepository ?? ProfileRepository.instance;

  final ProfileRepository _profileRepository;

  /// Returns the raw profile row for [userId].
  Future<Map<String, Object?>?> getProfile(String userId) async {
    final profile = await _profileRepository.fetchProfile(userId);
    if (profile == null) return null;
    return Map<String, Object?>.from(profile);
  }
}
