import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت حضور کاربران در چت
class ChatPresenceService {
  factory ChatPresenceService() => _instance;
  ChatPresenceService._internal();
  static final ChatPresenceService _instance = ChatPresenceService._internal();

  final SupabaseClient _supabase = Supabase.instance.client;

  // Heartbeat timer per conversation
  final Map<String, Timer> _conversationHeartbeatTimers = {};
  Duration heartbeatInterval = const Duration(seconds: 20);
  Duration activeThreshold = const Duration(seconds: 45);

  /// ثبت حضور کاربر در مکالمه
  Future<void> markUserAsActiveInChat({
    required String userId,
    required String conversationId,
  }) async {
    try {
      // بررسی وجود حضور قبلی برای این مکالمه
      final existingPresence = await _supabase
          .from('chat_presence')
          .select('id')
          .eq('user_id', userId)
          .eq('conversation_id', conversationId)
          .maybeSingle();

      if (existingPresence == null) {
        // ثبت حضور جدید فقط اگر قبلاً وجود نداشته باشد
        await _supabase.from('chat_presence').insert({
          'user_id': userId,
          'conversation_id': conversationId,
          'is_active': true,
          'last_seen': DateTime.now().toIso8601String(),
        });
      } else {
        // بروزرسانی حضور موجود
        await _supabase
            .from('chat_presence')
            .update({
              'is_active': true,
              'last_seen': DateTime.now().toIso8601String(),
            })
            .eq('user_id', userId)
            .eq('conversation_id', conversationId);
      }
    } catch (_) {}
  }

  /// Start periodic heartbeat for a conversation
  void startHeartbeat({
    required String userId,
    required String conversationId,
  }) {
    // Avoid duplicate timers
    stopHeartbeat(conversationId: conversationId);

    _conversationHeartbeatTimers[conversationId] = Timer.periodic(
      heartbeatInterval,
      (_) => markUserAsActiveInChat(
        userId: userId,
        conversationId: conversationId,
      ),
    );
    // Fire immediately once
    unawaited(
      markUserAsActiveInChat(userId: userId, conversationId: conversationId),
    );
  }

  /// Stop periodic heartbeat for a conversation
  void stopHeartbeat({required String conversationId}) {
    _conversationHeartbeatTimers.remove(conversationId)?.cancel();
  }

  /// حذف حضور کاربر از مکالمه
  Future<void> markUserAsInactiveInChat({
    required String userId,
    required String conversationId,
  }) async {
    try {
      // به جای حذف، is_active را false کنیم
      await _supabase
          .from('chat_presence')
          .update({
            'is_active': false,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('conversation_id', conversationId);
    } catch (_) {}
  }

  /// Mark all of current user's presences inactive (used on app pause/detach)
  Future<void> markAllInactiveForCurrentUser() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return;
      await _supabase
          .from('chat_presence')
          .update({
            'is_active': false,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('user_id', user.id);
    } catch (_) {}
  }

  /// بررسی اینکه آیا هر دو کاربر در مکالمه فعال هستند
  Future<bool> areBothUsersActiveInChat({
    required String conversationId,
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      // دریافت حضور کاربران از دیتابیس
      final cutoffIso = DateTime.now()
          .subtract(activeThreshold)
          .toIso8601String();
      final response = await _supabase
          .from('chat_presence')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .eq('is_active', true)
          .gt('last_seen', cutoffIso);

      final activeUserIds = response
          .map((row) => row['user_id'] as String)
          .toSet();

      return activeUserIds.contains(user1Id) && activeUserIds.contains(user2Id);
    } catch (_) {
      return false;
    }
  }

  /// دریافت مکالمه فعال کاربر
  Future<String?> getUserActiveConversation(String userId) async {
    try {
      final cutoffIso = DateTime.now()
          .subtract(activeThreshold)
          .toIso8601String();
      final response = await _supabase
          .from('chat_presence')
          .select('conversation_id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('last_seen', cutoffIso)
          .maybeSingle();

      return response?['conversation_id'] as String?;
    } catch (_) {
      return null;
    }
  }

  /// دریافت لیست کاربران فعال در مکالمه
  Future<Set<String>> getActiveUsersInConversation(
    String conversationId,
  ) async {
    try {
      final cutoffIso = DateTime.now()
          .subtract(activeThreshold)
          .toIso8601String();
      final response = await _supabase
          .from('chat_presence')
          .select('user_id')
          .eq('conversation_id', conversationId)
          .eq('is_active', true)
          .gt('last_seen', cutoffIso);

      return response.map((row) => row['user_id'] as String).toSet();
    } catch (_) {
      return <String>{};
    }
  }

  /// پاک کردن حضورهای قدیمی (بیش از 24 ساعت)
  Future<void> cleanupOldPresence() async {
    try {
      final cutoffTime = DateTime.now().subtract(const Duration(hours: 24));
      await _supabase
          .from('chat_presence')
          .delete()
          .lt('created_at', cutoffTime.toIso8601String());
    } catch (_) {}
  }

  /// پاک کردن تمام حضورهای غیرفعال
  Future<void> cleanupInactivePresence() async {
    try {
      await _supabase.from('chat_presence').delete().eq('is_active', false);
    } catch (_) {}
  }

  /// پاک کردن تمام داده‌های حضور (برای logout)
  Future<void> clearAllPresence() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('chat_presence').delete().eq('user_id', user.id);
      }
    } catch (_) {}
  }

  /// دریافت وضعیت حضور کاربر
  Future<bool> isUserActiveInChat(String userId) async {
    try {
      final cutoffIso = DateTime.now()
          .subtract(activeThreshold)
          .toIso8601String();
      final response = await _supabase
          .from('chat_presence')
          .select('id')
          .eq('user_id', userId)
          .eq('is_active', true)
          .gt('last_seen', cutoffIso)
          .maybeSingle();

      return response != null;
    } catch (_) {
      return false;
    }
  }

  /// دریافت آمار حضور
  Future<Map<String, dynamic>> getPresenceStats() async {
    try {
      final cutoffIso = DateTime.now()
          .subtract(activeThreshold)
          .toIso8601String();
      final response = await _supabase
          .from('chat_presence')
          .select('conversation_id, user_id')
          .eq('is_active', true)
          .gt('last_seen', cutoffIso);

      final Map<String, Set<String>> conversations = {};
      for (final row in response) {
        final conversationId = row['conversation_id'] as String;
        final userId = row['user_id'] as String;
        conversations[conversationId] ??= <String>{};
        conversations[conversationId]!.add(userId);
      }

      return {
        'activeConversations': conversations.length,
        'activeUsers': response.length,
        'conversations': conversations.map(
          (key, value) => MapEntry(key, value.toList()),
        ),
      };
    } catch (_) {
      return {
        'activeConversations': 0,
        'activeUsers': 0,
        'conversations': <String, List<String>>{},
      };
    }
  }
}
