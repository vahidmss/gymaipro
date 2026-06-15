import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';

/// Delegates to [ProfileRepository] — kept for existing callers.
class UserService {
  final ProfileRepository _profiles = ProfileRepository.instance;

  Future<UserProfile?> getUserProfile(String userId) =>
      _profiles.getUserProfile(userId);

  Future<String> getDisplayName(String userId) =>
      _profiles.getDisplayName(userId);

  Future<String?> getUserAvatar(String userId) =>
      _profiles.getUserAvatar(userId);

  Future<String> getUserRole(String userId) =>
      _profiles.getUserRole(userId);
}
