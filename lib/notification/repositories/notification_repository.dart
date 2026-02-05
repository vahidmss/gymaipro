import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Result class for paginated notifications
class NotificationResult {
  final List<NotificationItem> notifications;
  final int unreadCount;
  final bool hasMore;

  NotificationResult({
    required this.notifications,
    required this.unreadCount,
    required this.hasMore,
  });
}

/// Repository برای مدیریت داده‌های اعلان‌ها
class NotificationRepository {
  final SupabaseClient _client = Supabase.instance.client;

  /// Get notifications with pagination and filters
  Future<NotificationResult> getNotifications({
    required int page,
    required int pageSize,
    NotificationType? filter,
    bool showOnlyUnread = false,
    String? searchQuery,
  }) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) {
        return NotificationResult(
          notifications: [],
          unreadCount: 0,
          hasMore: false,
        );
      }

      // Build query step by step
      var query = _client.from('notifications').select().eq('user_id', user.id);

      // Apply filters
      if (filter != null) {
        query = query.eq('type', filter.name);
      }

      if (showOnlyUnread) {
        query = query.eq('is_read', false);
      }

      // Apply pagination
      final offset = page * pageSize;
      final limit = pageSize;
      final paginatedQuery = query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final response = await paginatedQuery;

      List<NotificationItem> notifications = [];
      if (response is List) {
        notifications = response
            .map(
              (json) =>
                  NotificationItem.fromJson(Map<String, dynamic>.from(json)),
            )
            .toList();

        // Apply search filter in memory if needed
        if (searchQuery != null && searchQuery.isNotEmpty) {
          final queryLower = searchQuery.toLowerCase();
          notifications = notifications.where((n) {
            return n.title.toLowerCase().contains(queryLower) ||
                n.message.toLowerCase().contains(queryLower);
          }).toList();
        }
      }

      // Get unread count
      final unreadCount = await getUnreadCount();

      // Check if there are more items by trying to fetch one more
      final hasMoreCheck = await query
          .order('created_at', ascending: false)
          .range(offset + limit, offset + limit)
          .limit(1);

      final hasMore = hasMoreCheck is List && hasMoreCheck.isNotEmpty;

      return NotificationResult(
        notifications: notifications,
        unreadCount: unreadCount,
        hasMore: hasMore,
      );
    } catch (e) {
      throw Exception('Error fetching notifications: $e');
    }
  }

  /// Get unread notification count
  Future<int> getUnreadCount() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc<int>(
        'get_unread_notification_count',
        params: {'user_uuid': user.id},
      );

      return response ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Mark notification as read
  Future<bool> markAsRead(String notificationId) async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return false;

      final response = await _client.rpc<bool>(
        'mark_notification_as_read',
        params: {'notification_uuid': notificationId, 'user_uuid': user.id},
      );

      return response ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Mark all notifications as read
  Future<int> markAllAsRead() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return 0;

      final response = await _client.rpc<int>(
        'mark_all_notifications_as_read',
        params: {'user_uuid': user.id},
      );

      return response ?? 0;
    } catch (e) {
      return 0;
    }
  }

  /// Delete notification
  Future<bool> deleteNotification(String notificationId) async {
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
      return false;
    }
  }

  /// Delete all read notifications
  Future<List<String>> deleteReadNotifications() async {
    try {
      final user = _client.auth.currentUser;
      if (user == null) return [];

      // Get all read notification IDs first
      final readNotifications = await _client
          .from('notifications')
          .select('id')
          .eq('user_id', user.id)
          .eq('is_read', true);

      if (readNotifications is! List || readNotifications.isEmpty) {
        return [];
      }

      final ids = readNotifications
          .map((n) => Map<String, dynamic>.from(n)['id'] as String)
          .toList();

      // Delete them
      await _client
          .from('notifications')
          .delete()
          .eq('user_id', user.id)
          .eq('is_read', true);

      return ids;
    } catch (e) {
      return [];
    }
  }
}
