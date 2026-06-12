import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// تحویل اعلان درون‌برنامه‌ای: ردیف در DB + نوتیف محلی (اگر گیرنده همین دستگاه است).
/// FCM فقط وقتی [AppConfig.firebasePushEnabled] روشن باشد — در پس‌زمینه و بدون block UI.
class InAppNotificationDeliveryService {
  static final SupabaseClient _client = Supabase.instance.client;
  static final Map<String, DateTime> _recentLocalKeys = {};

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

      if (!skipLocalTray) {
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

      if (!skipFcm && AppConfig.firebasePushEnabled) {
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

    final last = _recentLocalKeys[dedupeKey];
    if (last != null &&
        DateTime.now().difference(last) < const Duration(seconds: 20)) {
      return;
    }
    _recentLocalKeys[dedupeKey] = DateTime.now();

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
    if (!AppConfig.supabaseEdgeFunctionsEnabled) return;

    try {
      if (trainerProfileIdForFcm != null &&
          trainerProfileIdForFcm.isNotEmpty) {
        await _client.functions
            .invoke(
              'send-notifications',
              body: {
                'mode': 'trainer_new_student',
                'trainer_id': trainerProfileIdForFcm,
                'title': title,
                'body': body,
                'data': data,
              },
            )
            .timeout(const Duration(seconds: 12));
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

      await _client.functions
          .invoke(
            'send-notifications',
            body: {
              'mode': 'direct',
              'target_type': 'device_tokens',
              'tokens': tokens,
              'title': title,
              'body': body,
              'data': data,
            },
          )
          .timeout(const Duration(seconds: 12));
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
