import 'package:gymaipro/my_club/services/confidential_user_info_service.dart';

/// Read-only adapter for confidential user lifestyle data.
class ConfidentialContextAdapter {
  /// Returns confidential row data for [profileId] when available.
  ///
  /// Uses the existing trainer-safe read path. No writes are performed.
  Future<Map<String, Object?>?> getForProfile(String profileId) async {
    final data = await ConfidentialUserInfoService.loadUserDataForProfile(
      profileId,
    );
    if (data == null) return null;
    return Map<String, Object?>.from(data);
  }
}
