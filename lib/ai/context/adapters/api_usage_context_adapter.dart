import 'package:gymaipro/ai/services/message_rate_limiter_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Read-only local snapshot of AI usage counters.
///
/// Uses existing SharedPreferences keys only. It does not call usage services
/// that may sync or reset counters during reads.
class ApiUsageContextAdapter {
  static const String chatDailyMessagesKey = 'ai_chat_daily_messages';
  static const String chatLastResetDateKey = 'ai_chat_last_reset_date';
  static const String progressFreeUsageCountKey =
      'progress_analysis_free_usage_count';

  /// Mirrors the progress analysis free tier limit (currently 3).
  static const int progressAnalysisFreeLimit = 3;

  /// Returns a read-only usage snapshot for [userId].
  Future<Map<String, Object?>> getUsageSnapshot(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final chatDailyUsed = prefs.getInt(chatDailyMessagesKey) ?? 0;
    final progressFreeUsed = prefs.getInt(progressFreeUsageCountKey) ?? 0;

    return <String, Object?>{
      'user_id': userId,
      'source': 'shared_preferences_read_only',
      'ai_chat': <String, Object?>{
        'daily_used': chatDailyUsed,
        'daily_limit': MessageRateLimiterService.defaultDailyLimit,
        'daily_remaining':
            MessageRateLimiterService.defaultDailyLimit - chatDailyUsed,
        'last_reset_date': prefs.getString(chatLastResetDateKey),
      },
      'progress_analysis': <String, Object?>{
        'free_used': progressFreeUsed,
        'free_limit': progressAnalysisFreeLimit,
        'free_remaining': progressAnalysisFreeLimit - progressFreeUsed,
      },
      // TODO(ai-context): Add subscription entitlement snapshot through a
      // read-only subscription reader. SubscriptionService.getActiveSubscription
      // may update expired rows during reads.
    };
  }
}
