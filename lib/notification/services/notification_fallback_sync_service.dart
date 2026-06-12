import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/chat/services/chat_service.dart';
import 'package:gymaipro/chat/services/chat_unread_sync_bus.dart';
import 'package:gymaipro/notification/gateway/notification_delivery_gateway.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/notification/repositories/notification_repository.dart';
import 'package:gymaipro/notification/services/notification_sync_bus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum NotificationFallbackSyncState { healthy, degraded, error, skipped, unknown }

class NotificationFallbackHealthSnapshot {
  const NotificationFallbackHealthSnapshot({
    required this.lastSyncAt,
    required this.lastLatencyMs,
    required this.lastStatus,
    required this.successCount,
    required this.failureCount,
    required this.pushUnavailableCount,
    required this.unreadNotifications,
    required this.unreadChats,
  });

  final DateTime? lastSyncAt;
  final int lastLatencyMs;
  final String lastStatus;
  final int successCount;
  final int failureCount;
  final int pushUnavailableCount;
  final int unreadNotifications;
  final int unreadChats;

  NotificationFallbackSyncState get state {
    if (lastStatus.startsWith('ok:')) return NotificationFallbackSyncState.healthy;
    if (lastStatus.startsWith('ok_degraded:')) {
      return NotificationFallbackSyncState.degraded;
    }
    if (lastStatus.startsWith('error:')) return NotificationFallbackSyncState.error;
    if (lastStatus.startsWith('skip_')) return NotificationFallbackSyncState.skipped;
    return NotificationFallbackSyncState.unknown;
  }
}

/// Best-effort fallback sync for notification-critical data.
///
/// هدف: وقتی push در دسترس نیست/ناپایدار است، تجربه کاربر با همگام‌سازی
/// unreadها و ثبت health metrics حفظ شود.
class NotificationFallbackSyncService {
  factory NotificationFallbackSyncService() => _instance;
  NotificationFallbackSyncService._internal();
  static final NotificationFallbackSyncService _instance =
      NotificationFallbackSyncService._internal();

  final NotificationRepository _notificationRepository = NotificationRepository();
  final ChatService _chatService = ChatService();
  final NotificationDeliveryGateway _deliveryGateway =
      FcmNotificationDeliveryGateway();
  final NotificationService _notificationService = NotificationService();
  DateTime? _lastFallbackChatNotifyAt;
  DateTime? _lastFallbackFriendRequestNotifyAt;

  static const String _kLastSyncAtKey = 'notif_fallback_last_sync_at';
  static const String _kLastSyncLatencyMsKey = 'notif_fallback_last_latency_ms';
  static const String _kLastSyncStatusKey = 'notif_fallback_last_status';
  static const String _kSyncSuccessCountKey = 'notif_fallback_success_count';
  static const String _kSyncFailureCountKey = 'notif_fallback_failure_count';
  static const String _kPushUnavailableCountKey = 'notif_push_unavailable_count';
  static const String _kLastUnreadNotificationsKey =
      'notif_fallback_unread_notifications';
  static const String _kLastUnreadChatsKey = 'notif_fallback_unread_chats';
  static const String _kLastPendingFriendRequestsKey =
      'notif_fallback_pending_friend_requests';
  static const int _kDefaultMinIntervalMs = 30000;
  static const int _kConnectivityMinIntervalMs = 12000;
  static const int _kResumedMinIntervalMs = 20000;
  static const int _kInitMinIntervalMs = 25000;

  Future<void> syncOnForeground({String reason = 'resume'}) async {
    final startedAt = DateTime.now();
    final prefs = await SharedPreferences.getInstance();
    if (!_shouldRunSync(prefs: prefs, reason: reason, now: startedAt)) {
      return;
    }

    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        await _markSuccess(
          prefs: prefs,
          startedAt: startedAt,
          status: 'skip_no_user:$reason',
        );
        return;
      }

      final health = await _deliveryGateway.healthCheck();
      if (!health.backendReachable) {
        await _markSuccess(
          prefs: prefs,
          startedAt: startedAt,
          status: 'skip_offline:$reason',
        );
        return;
      }

      final preSyncHealth = await _deliveryGateway.healthCheck();

      // FCM may be blocked (e.g. filtered networks). Never block unread/badge sync.
      unawaited(_syncPushProviderInBackground(reason));

      final postSyncHealth = preSyncHealth;
      final previousUnreadChats = prefs.getInt(_kLastUnreadChatsKey) ?? 0;
      final previousPendingFriendRequests =
          prefs.getInt(_kLastPendingFriendRequestsKey) ?? 0;
      if (!postSyncHealth.canDeliverPush) {
        final pushUnavailableCount =
            (prefs.getInt(_kPushUnavailableCountKey) ?? 0) + 1;
        await prefs.setInt(_kPushUnavailableCountKey, pushUnavailableCount);
      }

      final unreadNotifications = await _notificationRepository
          .getUnreadCount()
          .timeout(const Duration(seconds: 6), onTimeout: () => 0);
      final unreadChats = await _loadUnreadChats().timeout(
        const Duration(seconds: 8),
        onTimeout: () => 0,
      );
      final pendingFriendRequests = await _loadPendingFriendRequests().timeout(
        const Duration(seconds: 6),
        onTimeout: () => 0,
      );

      await prefs.setInt(_kLastUnreadNotificationsKey, unreadNotifications);
      await prefs.setInt(_kLastUnreadChatsKey, unreadChats);
      await prefs.setInt(
        _kLastPendingFriendRequestsKey,
        pendingFriendRequests,
      );

      await _maybeNotifyChatFallback(
        previousUnreadChats: previousUnreadChats,
        unreadChats: unreadChats,
        reason: reason,
        pushHealthy: postSyncHealth.canDeliverPush,
      );

      await _maybeNotifyFriendRequestFallback(
        previousPending: previousPendingFriendRequests,
        pendingNow: pendingFriendRequests,
        reason: reason,
        pushHealthy: postSyncHealth.canDeliverPush,
      );

      // Push an in-app sync signal so chat/notification badges refresh immediately.
      ChatUnreadSyncBus.instance.ping();
      NotificationSyncBus.instance.ping();

      await _markSuccess(
        prefs: prefs,
        startedAt: startedAt,
        status: 'ok:$reason',
      );
    } catch (e) {
      await _markFailure(prefs: prefs, startedAt: startedAt, error: e.toString());
      if (kDebugMode) {
        debugPrint('NotificationFallbackSync error: $e');
      }
    }
  }

  Future<NotificationFallbackHealthSnapshot> getHealthSnapshot() async {
    final prefs = await SharedPreferences.getInstance();
    final lastSyncAtRaw = prefs.getString(_kLastSyncAtKey);
    return NotificationFallbackHealthSnapshot(
      lastSyncAt: lastSyncAtRaw == null ? null : DateTime.tryParse(lastSyncAtRaw),
      lastLatencyMs: prefs.getInt(_kLastSyncLatencyMsKey) ?? 0,
      lastStatus: prefs.getString(_kLastSyncStatusKey) ?? '',
      successCount: prefs.getInt(_kSyncSuccessCountKey) ?? 0,
      failureCount: prefs.getInt(_kSyncFailureCountKey) ?? 0,
      pushUnavailableCount: prefs.getInt(_kPushUnavailableCountKey) ?? 0,
      unreadNotifications: prefs.getInt(_kLastUnreadNotificationsKey) ?? 0,
      unreadChats: prefs.getInt(_kLastUnreadChatsKey) ?? 0,
    );
  }

  Future<void> _syncPushProviderInBackground(String reason) async {
    try {
      await _deliveryGateway.ensureProviderState().timeout(
        const Duration(seconds: 8),
        onTimeout: () {
          if (kDebugMode) {
            debugPrint(
              'NotificationFallbackSync: FCM probe skipped (timeout, reason=$reason)',
            );
          }
        },
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationFallbackSync: FCM background sync: $e');
      }
    }
  }

  Future<int> _loadUnreadChats() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    final conversations = await _chatService.getConversations();
    return conversations.where((c) => c.hasUnreadForUser(user.id)).length;
  }

  Future<int> _loadPendingFriendRequests() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return 0;

    final rows = await Supabase.instance.client
        .from('friendship_requests')
        .select('id')
        .eq('requested_id', user.id)
        .eq('status', 'pending');
    return (rows as List<dynamic>).length;
  }

  Future<void> _markSuccess({
    required SharedPreferences prefs,
    required DateTime startedAt,
    required String status,
  }) async {
    final latency = DateTime.now().difference(startedAt).inMilliseconds;
    final successCount = (prefs.getInt(_kSyncSuccessCountKey) ?? 0) + 1;

    await prefs.setString(_kLastSyncAtKey, DateTime.now().toIso8601String());
    await prefs.setInt(_kLastSyncLatencyMsKey, latency);
    await prefs.setString(_kLastSyncStatusKey, status);
    await prefs.setInt(_kSyncSuccessCountKey, successCount);
  }

  Future<void> _markFailure({
    required SharedPreferences prefs,
    required DateTime startedAt,
    required String error,
  }) async {
    final latency = DateTime.now().difference(startedAt).inMilliseconds;
    final failureCount = (prefs.getInt(_kSyncFailureCountKey) ?? 0) + 1;

    await prefs.setString(_kLastSyncAtKey, DateTime.now().toIso8601String());
    await prefs.setInt(_kLastSyncLatencyMsKey, latency);
    await prefs.setString(_kLastSyncStatusKey, 'error:$error');
    await prefs.setInt(_kSyncFailureCountKey, failureCount);
  }

  bool _shouldRunSync({
    required SharedPreferences prefs,
    required String reason,
    required DateTime now,
  }) {
    if (reason == 'manual_debug') {
      return true;
    }

    final lastSyncAtRaw = prefs.getString(_kLastSyncAtKey);
    if (lastSyncAtRaw == null || lastSyncAtRaw.isEmpty) {
      return true;
    }

    final lastSyncAt = DateTime.tryParse(lastSyncAtRaw);
    if (lastSyncAt == null) {
      return true;
    }

    final lastStatus = prefs.getString(_kLastSyncStatusKey) ?? '';
    final baseIntervalMs = _baseMinIntervalMsForReason(reason);
    final minIntervalMs = _adaptiveIntervalMs(
      baseIntervalMs: baseIntervalMs,
      lastStatus: lastStatus,
    );

    return now.difference(lastSyncAt).inMilliseconds >= minIntervalMs;
  }

  int _baseMinIntervalMsForReason(String reason) {
    switch (reason) {
      case 'connectivity':
        return _kConnectivityMinIntervalMs;
      case 'resumed':
      case 'resume':
        return _kResumedMinIntervalMs;
      case 'initState':
        return _kInitMinIntervalMs;
      default:
        return _kDefaultMinIntervalMs;
    }
  }

  int _adaptiveIntervalMs({
    required int baseIntervalMs,
    required String lastStatus,
  }) {
    if (lastStatus.startsWith('ok:')) {
      // Healthy state: back off a bit to save network and CPU.
      return baseIntervalMs * 2;
    }

    if (lastStatus.startsWith('ok_degraded:') || lastStatus.startsWith('error:')) {
      // Degraded/error state: keep cadence tighter for faster recovery.
      return baseIntervalMs;
    }

    return baseIntervalMs;
  }

  Future<void> _maybeNotifyChatFallback({
    required int previousUnreadChats,
    required int unreadChats,
    required String reason,
    required bool pushHealthy,
  }) async {
    // No new unread chats.
    if (unreadChats <= previousUnreadChats) return;

    // Avoid notifications during manual debug runs.
    if (reason == 'manual_debug') return;

    // If push is healthy, FCM should handle delivery.
    if (pushHealthy) return;

    // Guard against bursts/duplicate local alerts near realtime path.
    if (_lastFallbackChatNotifyAt != null &&
        DateTime.now().difference(_lastFallbackChatNotifyAt!) <
            const Duration(seconds: 20)) {
      return;
    }

    try {
      final newChats = unreadChats - previousUnreadChats;
      _lastFallbackChatNotifyAt = DateTime.now();
      await _notificationService.showCustomNotification(
        title: '💬 پیام جدید',
        body: newChats > 1
            ? '$newChats گفت‌وگوی جدید پیام نخوانده دارند'
            : 'یک پیام جدید دریافت کردید',
        payload: '{"type":"chat_message_fallback","source":"fallback_sync"}',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('NotificationFallbackSync local chat notify error: $e');
      }
    }
  }

  Future<void> _maybeNotifyFriendRequestFallback({
    required int previousPending,
    required int pendingNow,
    required String reason,
    required bool pushHealthy,
  }) async {
    if (pendingNow <= previousPending) return;
    if (reason == 'manual_debug') return;
    // حتی با FCM token، push ممکن است فیلتر باشد — tray محلی لازم است.

    if (_lastFallbackFriendRequestNotifyAt != null &&
        DateTime.now().difference(_lastFallbackFriendRequestNotifyAt!) <
            const Duration(seconds: 20)) {
      return;
    }

    try {
      final delta = pendingNow - previousPending;
      _lastFallbackFriendRequestNotifyAt = DateTime.now();
      await _notificationService.showInAppFriendRequestAlert(
        title: 'درخواست دوستی جدید',
        body: delta > 1
            ? '$delta درخواست دوستی جدید دارید'
            : 'یک درخواست دوستی جدید دریافت کردید',
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint(
          'NotificationFallbackSync local friend request notify error: $e',
        );
      }
    }
  }
}
