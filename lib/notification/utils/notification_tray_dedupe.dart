/// Prevents the same alert from appearing twice within a short window
/// (FCM foreground handler + fallback sync + in-app delivery).
class NotificationTrayDedupe {
  NotificationTrayDedupe._();

  static const Duration ttl = Duration(seconds: 25);
  static final Map<String, DateTime> _recentKeys = {};

  static String chatKey({
    String? messageId,
    String? conversationId,
    String? senderId,
    String? messageAt,
  }) {
    if (messageId != null && messageId.isNotEmpty) {
      return 'chat:id:$messageId';
    }
    return 'chat:${conversationId ?? ''}:${messageAt ?? ''}:${senderId ?? ''}';
  }

  static String friendRequestKey({String? requestId}) =>
      'friend_request:${requestId ?? 'generic'}';

  static String friendAcceptedKey({String? friendId}) =>
      'friend_accepted:${friendId ?? 'generic'}';

  static String genericKey({required String type, String? id}) =>
      '$type:${id ?? 'generic'}';

  /// Returns true if the tray alert should be shown (and records the key).
  static bool shouldShow(String key) {
    final now = DateTime.now();
    _recentKeys.removeWhere(
      (_, at) => now.difference(at) > ttl,
    );

    final last = _recentKeys[key];
    if (last != null && now.difference(last) < ttl) {
      return false;
    }
    _recentKeys[key] = now;
    return true;
  }
}
