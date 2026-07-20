import 'package:shared_preferences/shared_preferences.dart';

/// Read-only local snapshot of AI usage counters.
class ApiUsageContextAdapter {
  static const String progressFreeUsageCountKey =
      'progress_analysis_free_usage_count';

  /// Mirrors the progress analysis free tier limit (currently 3).
  static const int progressAnalysisFreeLimit = 3;

  /// Returns a read-only usage snapshot for [userId].
  Future<Map<String, Object?>> getUsageSnapshot(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final progressFreeUsed = prefs.getInt(progressFreeUsageCountKey) ?? 0;

    return <String, Object?>{
      'user_id': userId,
      'source': 'shared_preferences_read_only',
      'progress_analysis': <String, Object?>{
        'free_used': progressFreeUsed,
        'free_limit': progressAnalysisFreeLimit,
        'free_remaining': progressAnalysisFreeLimit - progressFreeUsed,
      },
    };
  }
}
