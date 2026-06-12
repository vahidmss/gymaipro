import 'dart:convert';

import 'package:gymaipro/notification/models/notification_model.dart';

/// حذف اعلان‌های تکراری درخواست دوستی در UI (همان request_id).
List<NotificationItem> dedupeFriendshipNotifications(
  List<NotificationItem> items,
) {
  final seenFriendRequest = <String>{};
  final seenFriendAccepted = <String>{};
  final result = <NotificationItem>[];

  for (final item in items) {
    final data = _normalizedData(item.data);
    final type = data['type']?.toString();

    if (type == 'friend_request') {
      final requestId = data['request_id']?.toString();
      if (requestId != null && requestId.isNotEmpty) {
        if (seenFriendRequest.contains(requestId)) continue;
        seenFriendRequest.add(requestId);
      }
    } else if (type == 'friend_request_accepted') {
      final friendId = data['friend_id']?.toString();
      if (friendId != null && friendId.isNotEmpty) {
        if (seenFriendAccepted.contains(friendId)) continue;
        seenFriendAccepted.add(friendId);
      }
    }

    result.add(item);
  }

  return result;
}

bool isDuplicateFriendshipNotification(
  NotificationItem candidate,
  List<NotificationItem> existing,
) {
  final data = _normalizedData(candidate.data);
  final type = data['type']?.toString();
  if (type != 'friend_request' && type != 'friend_request_accepted') {
    return false;
  }

  for (final item in existing) {
    final other = _normalizedData(item.data);
    if (other['type']?.toString() != type) continue;

    if (type == 'friend_request') {
      final a = data['request_id']?.toString();
      final b = other['request_id']?.toString();
      if (a != null && a.isNotEmpty && a == b) return true;
    } else {
      final a = data['friend_id']?.toString();
      final b = other['friend_id']?.toString();
      if (a != null && a.isNotEmpty && a == b) return true;
    }
  }
  return false;
}

Map<String, dynamic> _normalizedData(Map<String, dynamic> raw) {
  if (raw.isEmpty) return raw;
  return raw;
}

/// پارس data از jsonb/string برای dedupe در query دستی.
Map<String, dynamic>? parseNotificationDataField(dynamic data) {
  if (data is Map) {
    return Map<String, dynamic>.from(data);
  }
  if (data is String && data.isNotEmpty) {
    try {
      return Map<String, dynamic>.from(
        json.decode(data) as Map<dynamic, dynamic>,
      );
    } catch (_) {}
  }
  return null;
}
