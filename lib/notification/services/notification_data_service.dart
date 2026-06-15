import 'package:flutter/foundation.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class NotificationDataService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// Get all notifications for the current user
  static Future<List<NotificationItem>> getUserNotifications({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List<dynamic>)
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
      return [];
    }
  }

  /// Get unread notification count for the current user
  static Future<int> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc<int>(
        'get_unread_notification_count',
        params: {'user_uuid': user.id},
      );

      return response;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  /// Check if user has unread notifications
  static Future<bool> hasUnreadNotifications() async {
    try {
      final count = await getUnreadCount();
      return count > 0;
    } catch (e) {
      debugPrint('Error checking unread notifications: $e');
      return false; // Safe default
    }
  }

  /// Mark a notification as read
  static Future<bool> markAsRead(String notificationId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client.rpc<Map<String, dynamic>>(
        'mark_notification_as_read',
        params: {'notification_uuid': notificationId, 'user_uuid': user.id},
      );

      return (response as bool?) ?? false;
    } catch (e) {
      debugPrint('Error marking notification as read: $e');
      return false;
    }
  }

  /// Mark all notifications as read for the current user
  static Future<int> markAllAsRead() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc<int>(
        'mark_all_notifications_as_read',
        params: {'user_uuid': user.id},
      );

      return (response as int?) ?? 0;
    } catch (e) {
      debugPrint('Error marking all notifications as read: $e');
      return 0;
    }
  }

  /// Create a notification for an arbitrary user (alias used by delivery layer).
  static Future<bool> createNotificationForUser({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    int priority = 2,
    Map<String, dynamic>? data,
    String? actionUrl,
    DateTime? expiresAt,
  }) {
    return createNotification(
      userId: userId,
      title: title,
      message: message,
      type: type,
      priority: priority,
      data: data,
      actionUrl: actionUrl,
      expiresAt: expiresAt,
    );
  }

  /// Create a new notification
  static Future<bool> createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
    int priority = 1,
    Map<String, dynamic>? data,
    String? actionUrl,
    DateTime? expiresAt,
  }) async {
    try {
      await _client.from('notifications').insert({
        'user_id': userId,
        'title': title,
        'message': message,
        'type': type.name,
        'priority': priority,
        'data': data ?? {},
        'action_url': actionUrl,
        'expires_at': expiresAt?.toIso8601String(),
      });

      return true;
    } catch (e) {
      debugPrint('Error creating notification: $e');
      return false;
    }
  }

  /// Delete a notification
  static Future<bool> deleteNotification(String notificationId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      await _client
          .from('notifications')
          .delete()
          .eq('id', notificationId)
          .eq('user_id', user.id);

      return true;
    } catch (e) {
      debugPrint('Error deleting notification: $e');
      return false;
    }
  }

  /// Delete all read notifications for the current user
  static Future<int> deleteReadNotifications() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      // استفاده از RPC function برای حذف اعلان‌های خوانده شده
      final response = await _client.rpc<int>(
        'delete_read_notifications',
        params: {'user_uuid': user.id},
      );

      return (response as int?) ?? 0;
    } catch (e) {
      debugPrint('Error deleting read notifications: $e');
      return 0;
    }
  }

  /// Get notifications by type
  static Future<List<NotificationItem>> getNotificationsByType(
    NotificationType type, {
    int limit = 20,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      final response = await _client
          .from('notifications')
          .select()
          .eq('user_id', user.id)
          .eq('type', type.name)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List<dynamic>)
          .map(
            (json) => NotificationItem.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      debugPrint('Error fetching notifications by type: $e');
      return [];
    }
  }

  /// Listen to notifications changes for real-time updates
  static Stream<List<NotificationItem>> listenToNotifications() {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return Stream.value([]);

      return _client
          .from('notifications')
          .stream(primaryKey: ['id'])
          .eq('user_id', user.id)
          .order('created_at')
          .map((data) => data.map(NotificationItem.fromJson).toList());
    } catch (e) {
      debugPrint('Error listening to notifications: $e');
      return Stream.value([]);
    }
  }
}
