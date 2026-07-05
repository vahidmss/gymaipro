import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/push_notification_policy.dart';
import 'package:gymaipro/notification/services/notification_push_invoker.dart';
import 'package:gymaipro/notification/utils/notification_tray_dedupe.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/notification/services/push_health_monitor.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// تحویل اعلان درون‌برنامه‌ای: ردیف در DB + نوتیف محلی (اگر گیرنده همین دستگاه است).
/// FCM فقط وقتی [PushNotificationPolicy.shouldAttemptServerPush] روشن باشد.
class InAppNotificationDeliveryService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// اعلان خرید برنامه برای مربی — ثبت در DB سمت سرور + پوش FCM (اگر فعال باشد).
  static Future<bool> deliverTrainerProgramPurchase({
    required String trainerProfileId,
    required String trainerAuthUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? dedupeKey,
    String? actionUrl,
    int priority = 3,
  }) async {
    final payloadData = {
      ...data,
      'type': data['type'] ?? 'payment',
      'event': data['event'] ?? 'trainer_program_purchase',
    };

    var serverOk = false;
    try {
      final response = await _client.functions.invoke(
        'send-notifications',
        body: {
          'mode': 'trainer_notify',
          'trainer_id': trainerProfileId,
          'title': title,
          'body': body,
          'data': payloadData,
          'notification': {
            'user_id': trainerAuthUserId,
            'title': title,
            'message': body,
            'type': 'payment',
            'priority': priority,
            'data': payloadData,
            'action_url': actionUrl,
          },
        },
      );
      serverOk = response.status == 200;
      if (kDebugMode && !serverOk) {
        debugPrint(
          'deliverTrainerProgramPurchase server status=${response.status} '
          'data=${response.data}',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('deliverTrainerProgramPurchase server failed: $e');
      }
    }

    if (serverOk) return true;

    return deliver(
      recipientUserId: trainerAuthUserId,
      title: title,
      body: body,
      type: NotificationType.payment,
      priority: priority,
      data: payloadData,
      actionUrl: actionUrl,
      dedupeKey: dedupeKey,
      trainerProfileIdForFcm: trainerProfileId,
    );
  }

  /// درج در notifications + نمایش tray برای کاربر فعلی + FCM اختیاری.
  static Future<bool> deliver({
    required String recipientUserId,
    required String title,
    required String body,
    required NotificationType type,
    required Map<String, dynamic> data,
    int priority = 2,
    String? actionUrl,
    String? dedupeKey,
    bool skipPersist = false,
    bool skipLocalTray = false,
    bool skipFcm = false,
    /// برای mode=trainer_new_student در Edge Function
    String? trainerProfileIdForFcm,
  }) async {
    try {
      if (!skipPersist) {
        if (dedupeKey != null) {
          final dup = await _hasPersistedDuplicate(
            userId: recipientUserId,
            dedupeKey: dedupeKey,
            data: data,
          );
          if (dup) return true;
        }

        final ok = await NotificationDataService.createNotificationForUser(
          userId: recipientUserId,
          title: title,
          message: body,
          type: type,
          priority: priority,
          data: data,
          actionUrl: actionUrl,
        );
        if (!ok && kDebugMode) {
          debugPrint(
            'InAppNotificationDelivery: persist failed for $recipientUserId',
          );
        }
      }

      // Push attempt targets the RECIPIENT — it only needs server capability
      // (edge functions), not this device's FCM health.
      final willSendFcm =
          !skipFcm && PushNotificationPolicy.shouldAttemptServerPush;

      // The local tray only fires when the current user IS the recipient. Show
      // it only when THIS device won't receive the FCM push (filtered network /
      // no token) so the alert is never duplicated nor silently lost.
      final deviceWillGetPush = PushHealthMonitor.instance.canReceivePushNow;
      if (!skipLocalTray && !deviceWillGetPush) {
        unawaited(
          _maybeShowLocalTray(
            recipientUserId: recipientUserId,
            title: title,
            body: body,
            data: data,
            dedupeKey: dedupeKey ?? title,
          ),
        );
      }

      if (willSendFcm) {
        unawaited(
          _deliverFcmBestEffort(
            recipientUserId: recipientUserId,
            title: title,
            body: body,
            data: data,
            trainerProfileIdForFcm: trainerProfileIdForFcm,
          ),
        );
      }

      return true;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('InAppNotificationDelivery: $e');
        debugPrint('$st');
      }
      return false;
    }
  }

  static Future<bool> _hasPersistedDuplicate({
    required String userId,
    required String dedupeKey,
    required Map<String, dynamic> data,
  }) async {
    try {
      if (dedupeKey.startsWith('friend_request:')) {
        final requestId = dedupeKey.split(':').last;
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('data->>type', 'friend_request')
            .eq('data->>request_id', requestId)
            .limit(1);
        return (rows as List<dynamic>).isNotEmpty;
      }
      if (dedupeKey.startsWith('friend_accepted:')) {
        final parts = dedupeKey.split(':');
        if (parts.length < 3) return false;
        final friendId = parts[2];
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('data->>type', 'friend_request_accepted')
            .eq('data->>friend_id', friendId)
            .limit(1);
        return (rows as List<dynamic>).isNotEmpty;
      }
      if (dedupeKey.startsWith('program_ready:')) {
        final parts = dedupeKey.split(':');
        if (parts.length < 3) return false;
        final kind = parts[1];
        final programId = parts[2];
        final type = kind == 'diet' ? 'diet_program' : 'workout_program';
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('data->>type', type)
            .eq('data->>program_id', programId)
            .limit(1);
        return (rows as List<dynamic>).isNotEmpty;
      }
      if (dedupeKey.startsWith('trainer_program:')) {
        final subId = dedupeKey.split(':').last;
        if (subId.isEmpty) return false;
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('data->>event', 'trainer_program_purchase')
            .eq('data->>subscription_id', subId)
            .limit(1);
        return (rows as List<dynamic>).isNotEmpty;
      }
      final event = data['event']?.toString();
      final buyerId = data['buyer_user_id']?.toString();
      if (event != null && buyerId != null) {
        final rows = await _client
            .from('notifications')
            .select('id')
            .eq('user_id', userId)
            .eq('data->>event', event)
            .eq('data->>buyer_user_id', buyerId)
            .gte(
              'created_at',
              DateTime.now()
                  .subtract(const Duration(minutes: 30))
                  .toIso8601String(),
            )
            .limit(1);
        return (rows as List<dynamic>).isNotEmpty;
      }
      return false;
    } catch (e) {
      if (kDebugMode) debugPrint('InAppNotificationDelivery dedupe: $e');
      return false;
    }
  }

  static Future<void> _maybeShowLocalTray({
    required String recipientUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String dedupeKey,
  }) async {
    final currentId = _client.auth.currentUser?.id;
    if (currentId == null || currentId != recipientUserId) return;

    if (!NotificationTrayDedupe.shouldShow(dedupeKey)) return;

    final type = data['type']?.toString() ?? '';
    if (type == 'friend_request' || type == 'friend_request_accepted') {
      await NotificationService().showInAppFriendRequestAlert(
        title: title,
        body: body,
        requestId: data['request_id']?.toString(),
        requesterId: data['requester_id']?.toString(),
        friendId: data['friend_id']?.toString(),
        isAccepted: type == 'friend_request_accepted',
      );
      return;
    }

    await NotificationService().showInAppGenericAlert(
      title: title,
      body: body,
      data: data,
    );
  }

  static Future<void> _deliverFcmBestEffort({
    required String recipientUserId,
    required String title,
    required String body,
    required Map<String, dynamic> data,
    String? trainerProfileIdForFcm,
  }) async {
    try {
      if (trainerProfileIdForFcm != null &&
          trainerProfileIdForFcm.isNotEmpty) {
        await NotificationPushInvoker.sendNotifications(
          client: _client,
          body: {
            'mode': 'trainer_notify',
            'trainer_id': trainerProfileIdForFcm,
            'title': title,
            'body': body,
            'data': data,
          },
        );
        return;
      }

      final tokensRes = await _client
          .from('device_tokens')
          .select('token')
          .eq('user_id', recipientUserId)
          .eq('is_push_enabled', true)
          .timeout(const Duration(seconds: 8));

      final tokens = (tokensRes as List<dynamic>)
          .map((e) => (e as Map)['token']?.toString() ?? '')
          .where((t) => t.isNotEmpty)
          .toList();

      if (tokens.isEmpty) return;

      await NotificationPushInvoker.sendNotifications(
        client: _client,
        body: {
          'mode': 'direct',
          'target_type': 'device_tokens',
          'tokens': tokens,
          'title': title,
          'body': body,
          'data': data,
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('InAppNotificationDelivery FCM skipped: $e');
      }
    }
  }

  /// از realtime وقتی ردیف notifications برای کاربر فعلی insert می‌شود.
  static Future<void> showLocalTrayFromNotificationRow({
    required Map<String, dynamic> record,
  }) async {
    final userId = record['user_id']?.toString();
    final currentId = _client.auth.currentUser?.id;
    if (userId == null || currentId == null || userId != currentId) return;

    final title = (record['title'] as String?) ?? 'اعلان';
    final body = (record['message'] as String?) ?? '';
    final dataRaw = record['data'];
    Map<String, dynamic> data = {};
    if (dataRaw is Map) {
      data = Map<String, dynamic>.from(dataRaw);
    }

    // Chat messages are delivered exclusively by ChatUnreadNotifier (on filtered
    // networks) or the FCM foreground handler (unfiltered). The edge function
    // also inserts a `notifications` row for history/badge, so showing a generic
    // tray here would duplicate the dedicated chat alert. Skip it.
    final rowType = record['type']?.toString();
    final dataType = data['type']?.toString();
    final isChatMessage = rowType == 'message' ||
        dataType == 'chat_message' ||
        data.containsKey('conversation_id');
    if (isChatMessage) {
      if (kDebugMode) {
        debugPrint(
          'InAppNotificationDelivery: skip generic tray for chat row '
          '(handled by ChatUnreadNotifier/FCM)',
        );
      }
      return;
    }

    final dedupeKey =
        '${data['type'] ?? 'generic'}:${record['id'] ?? title}';
    await _maybeShowLocalTray(
      recipientUserId: userId,
      title: title,
      body: body,
      data: data,
      dedupeKey: dedupeKey,
    );
  }
}
