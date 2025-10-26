import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
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
      debugPrint(
        '=== CHAT PRESENCE: User $userId is now active in conversation $conversationId ===',
      );

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
        debugPrint(
          '=== CHAT PRESENCE: New presence added for conversation $conversationId ===',
        );
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
        debugPrint(
          '=== CHAT PRESENCE: Existing presence updated for conversation $conversationId ===',
        );
      }

      debugPrint('=== CHAT PRESENCE: User presence updated in database ===');
    } catch (e) {
      debugPrint('Error marking user as active in chat: $e');
    }
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
      debugPrint(
        '=== CHAT PRESENCE: User $userId is now inactive in conversation $conversationId ===',
      );

      // به جای حذف، is_active را false کنیم
      await _supabase
          .from('chat_presence')
          .update({
            'is_active': false,
            'last_seen': DateTime.now().toIso8601String(),
          })
          .eq('user_id', userId)
          .eq('conversation_id', conversationId);

      debugPrint('=== CHAT PRESENCE: User presence marked as inactive ===');
    } catch (e) {
      debugPrint('Error marking user as inactive in chat: $e');
    }
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
      debugPrint(
        '=== CHAT PRESENCE: All presences marked inactive for user ===',
      );
    } catch (e) {
      debugPrint('Error marking all presences inactive: $e');
    }
  }

  /// بررسی اینکه آیا هر دو کاربر در مکالمه فعال هستند
  Future<bool> areBothUsersActiveInChat({
    required String conversationId,
    required String user1Id,
    required String user2Id,
  }) async {
    try {
      debugPrint('=== CHAT PRESENCE: Checking if both users are active ===');
      debugPrint('=== CHAT PRESENCE: Conversation: $conversationId ===');
      debugPrint('=== CHAT PRESENCE: User1: $user1Id, User2: $user2Id ===');

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

      final bothActive =
          activeUserIds.contains(user1Id) && activeUserIds.contains(user2Id);

      debugPrint('=== CHAT PRESENCE: Active users: $activeUserIds ===');
      debugPrint('=== CHAT PRESENCE: Both active: $bothActive ===');

      return bothActive;
    } catch (e) {
      debugPrint('Error checking user presence: $e');
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
    } catch (e) {
      debugPrint('Error getting user active conversation: $e');
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
    } catch (e) {
      debugPrint('Error getting active users in conversation: $e');
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
      debugPrint('=== CHAT PRESENCE: Old presence data cleaned up ===');
    } catch (e) {
      debugPrint('Error cleaning up old presence data: $e');
    }
  }

  /// پاک کردن تمام حضورهای غیرفعال
  Future<void> cleanupInactivePresence() async {
    try {
      await _supabase.from('chat_presence').delete().eq('is_active', false);
      debugPrint('=== CHAT PRESENCE: Inactive presence data cleaned up ===');
    } catch (e) {
      debugPrint('Error cleaning up inactive presence data: $e');
    }
  }

  /// پاک کردن تمام داده‌های حضور (برای logout)
  Future<void> clearAllPresence() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user != null) {
        await _supabase.from('chat_presence').delete().eq('user_id', user.id);
      }
      debugPrint('=== CHAT PRESENCE: All presence data cleared ===');
    } catch (e) {
      debugPrint('Error clearing presence data: $e');
    }
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
    } catch (e) {
      debugPrint('Error checking if user is active: $e');
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
    } catch (e) {
      debugPrint('Error getting presence stats: $e');
      return {
        'activeConversations': 0,
        'activeUsers': 0,
        'conversations': <String, List<String>>{},
      };
    }
  }
}
