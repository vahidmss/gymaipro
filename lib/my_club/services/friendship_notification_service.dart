import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/in_app_notification_delivery_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// اعلان درخواست دوستی: ردیف در notifications + نوتیف محلی + FCM اختیاری.
class FriendshipNotificationService {
  static final SupabaseClient _client = Supabase.instance.client;

  static Future<void> notifyFriendRequestReceived({
    required String recipientAuthId,
    required String requesterAuthId,
    required String requesterDisplayName,
    required String requestId,
    /// false = فقط trigger دیتابیس ردیف می‌سازد (INSERT جدید)
    bool persistInApp = true,
  }) async {
    if (!await _isFriendRequestEnabled(recipientAuthId)) return;

    const title = 'درخواست دوستی جدید';
    final body = '$requesterDisplayName می‌خواهد با شما دوست شود';
    final data = <String, dynamic>{
      'type': 'friend_request',
      'route': '/my-club',
      'initialTab': 2,
      'request_id': requestId,
      'requester_id': requesterAuthId,
    };

    await InAppNotificationDeliveryService.deliver(
      recipientUserId: recipientAuthId,
      title: title,
      body: body,
      type: NotificationType.system,
      data: data,
      dedupeKey: 'friend_request:$requestId',
      skipPersist: !persistInApp,
    );
  }

  static Future<void> notifyFriendRequestAccepted({
    required String requesterAuthId,
    required String accepterDisplayName,
    required String friendAuthId,
  }) async {
    if (!await _isFriendRequestEnabled(requesterAuthId)) return;

    const title = 'درخواست دوستی پذیرفته شد';
    final body = '$accepterDisplayName درخواست دوستی شما را پذیرفت';
    final data = <String, dynamic>{
      'type': 'friend_request_accepted',
      'route': '/my-club',
      'initialTab': 2,
      'friend_id': friendAuthId,
    };

    await InAppNotificationDeliveryService.deliver(
      recipientUserId: requesterAuthId,
      title: title,
      body: body,
      type: NotificationType.system,
      data: data,
      dedupeKey: 'friend_accepted:$requesterAuthId:$friendAuthId',
    );
  }

  static Future<bool> _isFriendRequestEnabled(String recipientAuthId) async {
    try {
      final row = await _client
          .from('user_notification_settings')
          .select('friend_request_notifications')
          .eq('user_id', recipientAuthId)
          .maybeSingle();
      return (row?['friend_request_notifications'] as bool?) ?? true;
    } catch (e) {
      debugPrint('FriendshipNotificationService settings check: $e');
      return true;
    }
  }

  /// برای realtime وقتی ردیف از trigger سرور می‌آید (دستگاه گیرنده).
  static Future<void> showLocalAlertFromNotificationRow({
    required Map<String, dynamic> record,
  }) async {
    final dataRaw = record['data'];
    Map<String, dynamic> data = {};
    if (dataRaw is Map) {
      data = Map<String, dynamic>.from(dataRaw);
    } else if (dataRaw is String) {
      try {
        data = Map<String, dynamic>.from(
          json.decode(dataRaw) as Map<dynamic, dynamic>,
        );
      } catch (_) {}
    }

    final type = data['type']?.toString();
    if (type != 'friend_request' && type != 'friend_request_accepted') {
      return;
    }

    await InAppNotificationDeliveryService.showLocalTrayFromNotificationRow(
      record: record,
    );
  }

  /// نام نمایشی از profiles (auth id یا profile id).
  static Future<String> displayNameForUser(String userId) async {
    try {
      var row = await _client
          .from('profiles')
          .select('username, first_name, last_name, auth_user_id')
          .eq('auth_user_id', userId)
          .maybeSingle();
      row ??= await _client
          .from('profiles')
          .select('username, first_name, last_name')
          .eq('id', userId)
          .maybeSingle();

      if (row == null) return 'کاربر';
      final first = (row['first_name'] as String?)?.trim() ?? '';
      final last = (row['last_name'] as String?)?.trim() ?? '';
      final combined = '$first $last'.trim();
      if (combined.isNotEmpty) return combined;
      final username = (row['username'] as String?)?.trim() ?? '';
      return username.isNotEmpty ? username : 'کاربر';
    } catch (_) {
      return 'کاربر';
    }
  }
}
