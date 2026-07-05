import 'package:gymaipro/notification/push_notification_policy.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Gated wrapper for Edge Function push delivery.
class NotificationPushInvoker {
  NotificationPushInvoker._();

  static Future<bool> sendNotifications({
    required SupabaseClient client,
    required Map<String, dynamic> body,
    Duration timeout = const Duration(seconds: 12),
  }) async {
    if (!PushNotificationPolicy.shouldAttemptServerPush) {
      return false;
    }

    try {
      await client.functions
          .invoke('send-notifications', body: body)
          .timeout(timeout);
      return true;
    } catch (_) {
      return false;
    }
  }
}
