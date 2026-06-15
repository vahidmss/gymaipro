import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';

/// Single entry point for profile reads across the app.
///
/// - Current user → [SimpleProfileService] (cache + auth_user_id linkage)
/// - Other users → [UserProfileService] (id / auth_user_id lookup)
class ProfileRepository {
  ProfileRepository._();

  static final ProfileRepository instance = ProfileRepository._();

  /// Cached profile for the logged-in user.
  Future<Map<String, dynamic>?> getCurrentProfile() =>
      SimpleProfileService.getCurrentProfile();

  /// Raw profile row for any user id or auth user id.
  Future<Map<String, dynamic>?> fetchProfile(String userIdOrAuthId) =>
      UserProfileService.fetchProfile(userIdOrAuthId);

  Future<UserProfile?> getUserProfile(String userIdOrAuthId) =>
      UserProfileService.getUserProfile(userIdOrAuthId);

  Future<String> getDisplayName(String userIdOrAuthId) =>
      UserProfileService.getDisplayName(userIdOrAuthId);

  Future<String?> getUserAvatar(String userIdOrAuthId) =>
      UserProfileService.getUserAvatar(userIdOrAuthId);

  Future<String> getUserRole(String userIdOrAuthId) =>
      UserProfileService.getUserRole(userIdOrAuthId);

  Future<Map<String, int>> getUserStats(String userIdOrAuthId) =>
      UserProfileService.getUserStats(userIdOrAuthId);

  String displayNameFromMap(
    Map<String, dynamic>? profile, {
    String fallback = 'کاربر ناشناس',
  }) =>
      UserProfileService.displayNameFromMap(profile, fallback: fallback);

  Future<List<Map<String, dynamic>>> fetchProfilesByAuthUserIds(
    List<String> authUserIds,
  ) =>
      UserProfileService.fetchProfilesByAuthUserIds(authUserIds);

  Future<String> resolveAuthUserId(String profileOrAuthId) =>
      UserProfileService.resolveAuthUserId(profileOrAuthId);

  Future<List<Map<String, dynamic>>> fetchProfilesByIds(
    List<String> profileIds, {
    String columns =
        'id, auth_user_id, username, first_name, last_name, avatar_url, role',
  }) =>
      UserProfileService.fetchProfilesByIds(profileIds, columns: columns);

  Future<Map<String, Map<String, dynamic>>> fetchProfilesByIdsMap(
    List<String> profileIds, {
    String columns = 'id, username, first_name, last_name, avatar_url',
  }) =>
      UserProfileService.fetchProfilesByIdsMap(
        profileIds,
        columns: columns,
      );

  Future<List<Map<String, dynamic>>> fetchProfilesByIdentifiers(
    List<String> identifiers,
  ) =>
      UserProfileService.fetchProfilesByIdentifiers(identifiers);

  Future<List<Map<String, dynamic>>> searchByUsername(String query) =>
      UserProfileService.searchByUsername(query);

  Future<List<Map<String, dynamic>>> searchByUsernameAndRole(
    String query, {
    required String role,
    String columns =
        'id, username, full_name, bio, height, weight, fitness_goals',
    int limit = 25,
  }) =>
      UserProfileService.searchByUsernameAndRole(
        query,
        role: role,
        columns: columns,
        limit: limit,
      );

  Future<Map<String, dynamic>?> fetchProfileByUsername(String username) =>
      UserProfileService.fetchProfileByUsername(username);

  Future<List<Map<String, dynamic>>> fetchProfilesByRole(
    String role, {
    String columns = 'id',
    int? limit,
  }) =>
      UserProfileService.fetchProfilesByRole(
        role,
        columns: columns,
        limit: limit,
      );

  Future<List<Map<String, dynamic>>> fetchProfilesByReferrerUsername(
    String referrerUsername, {
    String columns =
        'id, username, first_name, last_name, avatar_url, referred_at',
  }) =>
      UserProfileService.fetchProfilesByReferrerUsername(
        referrerUsername,
        columns: columns,
      );

  Future<List<Map<String, dynamic>>> fetchTrainers({
    int? limit = 10,
    bool orderByCreatedAtDesc = false,
  }) =>
      UserProfileService.fetchTrainers(
        limit: limit,
        orderByCreatedAtDesc: orderByCreatedAtDesc,
      );

  Future<List<Map<String, dynamic>>> fetchTrainersByRanking() =>
      UserProfileService.fetchTrainersByRanking();

  Future<List<Map<String, dynamic>>> searchTrainers(String query) =>
      UserProfileService.searchTrainers(query);

  Future<List<Map<String, dynamic>>> fetchOnlineTrainers() =>
      UserProfileService.fetchOnlineTrainers();

  Future<List<Map<String, dynamic>>> fetchTopTrainers({int limit = 10}) =>
      UserProfileService.fetchTopTrainers(limit: limit);

  Future<List<String>> fetchActiveProfileIds({
    Duration within = const Duration(days: 30),
  }) =>
      UserProfileService.fetchActiveProfileIds(within: within);

  Future<List<Map<String, dynamic>>> fetchTrainerSpecializationRows() =>
      UserProfileService.fetchTrainerSpecializationRows();
}
