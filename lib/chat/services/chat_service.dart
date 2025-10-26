import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ChatService: handles private/direct chat operations using Supabase
class ChatService {
  ChatService() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;

  // Helpers
  String _sortedConversationId(String a, String b) {
    final ids = [a, b]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  bool _belongsToPair(Map<String, dynamic> row, String u1, String u2) {
    final s = row['sender_id'] as String?;
    final r = (row['receiver_id'] ?? row['recipient_id']) as String?;
    if (s == null || r == null) return false;
    return (s == u1 && r == u2) || (s == u2 && r == u1);
  }

  // Conversations
  Future<void> ensureConversationExists(String otherUserId) async {
    // Using message aggregation, no physical conversation row required.
    return;
  }

  Future<ChatConversation?> getConversationByUserId(String otherUserId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return null;
    try {
      final response = await _supabase
          .from('chat_messages')
          .select()
          .or(
            'and(sender_id.eq.$me,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$me)',
          )
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(1);

      if (response.isEmpty) {
        // no messages yet → still return a minimal conversation stub
        final convId = _sortedConversationId(me, otherUserId);
        return ChatConversation(
          id: convId,
          user1Id: convId.split('_')[0],
          user2Id: convId.split('_')[1],
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }

      final latest = response.first;
      final unreadCount = await _supabase
          .from('chat_messages')
          .select('id')
          .eq('receiver_id', me)
          .eq('sender_id', otherUserId)
          .eq('is_read', false)
          .eq('is_deleted', false);

      final convId = _sortedConversationId(me, otherUserId);
      final user1 = convId.split('_')[0];
      final user2 = convId.split('_')[1];
      final lastAt = latest['created_at'] != null
          ? DateTime.parse(latest['created_at'] as String)
          : DateTime.now();
      final lastMsg = latest['message'] as String?;
      final lastSender = latest['sender_id'] as String?;

      return ChatConversation(
        id: convId,
        user1Id: user1,
        user2Id: user2,
        lastMessage: lastMsg,
        lastMessageAt: lastAt,
        lastMessageSenderId: lastSender,
        user1UnreadCount: me == user1 ? unreadCount.length : 0,
        user2UnreadCount: me == user2 ? unreadCount.length : 0,
        createdAt: lastAt,
        updatedAt: lastAt,
      );
    } catch (e) {
      debugPrint('ChatService.getConversationByUserId error: $e');
      return null;
    }
  }

  Future<List<ChatConversation>> getConversations() async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return [];
    try {
      final rows = await _supabase
          .from('chat_messages')
          .select()
          .or('sender_id.eq.$me,receiver_id.eq.$me')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .limit(300);

      final Map<String, List<Map<String, dynamic>>> grouped = {};
      for (final row in rows.cast<Map<String, dynamic>>()) {
        final sender = row['sender_id'] as String?;
        final receiver = (row['receiver_id'] ?? row['recipient_id']) as String?;
        if (sender == null || receiver == null) continue;
        final other = sender == me ? receiver : sender;
        grouped.putIfAbsent(other, () => <Map<String, dynamic>>[]).add(row);
      }

      final List<ChatConversation> conversations = [];
      for (final entry in grouped.entries) {
        final other = entry.key;
        final list = entry.value;
        list.sort(
          (a, b) => DateTime.parse(
            b['created_at'] as String,
          ).compareTo(DateTime.parse(a['created_at'] as String)),
        );
        final latest = list.first;
        final unread = list
            .where(
              (m) =>
                  (m['receiver_id'] as String?) == me &&
                  (m['is_read'] as bool?) == false,
            )
            .length;

        final convId = _sortedConversationId(me, other);
        final user1 = convId.split('_')[0];
        final user2 = convId.split('_')[1];
        final lastAt = latest['created_at'] != null
            ? DateTime.parse(latest['created_at'] as String)
            : DateTime.now();

        conversations.add(
          ChatConversation(
            id: convId,
            user1Id: user1,
            user2Id: user2,
            lastMessage: latest['message'] as String?,
            lastMessageAt: lastAt,
            lastMessageSenderId: latest['sender_id'] as String?,
            user1UnreadCount: me == user1 ? unread : 0,
            user2UnreadCount: me == user2 ? unread : 0,
            createdAt: lastAt,
            updatedAt: lastAt,
          ),
        );
      }

      // sort newest first
      conversations.sort(
        (a, b) => b.lastMessageDateTime.compareTo(a.lastMessageDateTime),
      );
      return conversations;
    } catch (e) {
      debugPrint('ChatService.getConversations error: $e');
      return [];
    }
  }

  Stream<ChatConversation> subscribeToConversations() {
    final me = _supabase.auth.currentUser?.id;
    final controller = StreamController<ChatConversation>.broadcast();
    if (me == null) return controller.stream;

    final channel = _supabase.channel('chat_conversations_$me');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async {
            final row = payload.newRecord;
            final sender = row['sender_id'] as String?;
            final receiver =
                (row['receiver_id'] ?? row['recipient_id']) as String?;
            if (sender == null || receiver == null) return;
            if (sender != me && receiver != me) return;
            final other = sender == me ? receiver : sender;
            final conv = await getConversationByUserId(other);
            if (conv != null) controller.add(conv);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async {
            final row = payload.newRecord;
            final sender = row['sender_id'] as String?;
            final receiver =
                (row['receiver_id'] ?? row['recipient_id']) as String?;
            if (sender == null || receiver == null) return;
            if (sender != me && receiver != me) return;
            final other = sender == me ? receiver : sender;
            final conv = await getConversationByUserId(other);
            if (conv != null) controller.add(conv);
          },
        )
        .subscribe();

    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }

  Future<List<ChatMessage>> getMessages(
    String otherUserId, {
    int limit = 50,
    int offset = 0,
  }) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return [];
    try {
      final rows = await _supabase
          .from('chat_messages')
          .select()
          .or(
            'and(sender_id.eq.$me,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$me)',
          )
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return rows
          .cast<Map<String, dynamic>>()
          .map(ChatMessage.fromJson)
          .toList();
    } catch (e) {
      debugPrint('ChatService.getMessages error: $e');
      return [];
    }
  }

  Stream<ChatMessage> subscribeToMessages(String otherUserId) {
    final me = _supabase.auth.currentUser?.id;
    final controller = StreamController<ChatMessage>.broadcast();
    if (me == null) return controller.stream;

    final channel = _supabase.channel(
      'chat_messages_${_sortedConversationId(me, otherUserId)}',
    );
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (_belongsToPair(row, me, otherUserId)) {
              controller.add(ChatMessage.fromJson(row));
            }
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final row = payload.newRecord;
            if (_belongsToPair(row, me, otherUserId)) {
              controller.add(ChatMessage.fromJson(row));
            }
          },
        )
        .subscribe();

    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }

  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) {
      throw Exception('User not authenticated');
    }
    final data = {
      'sender_id': me,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
      'is_read': false,
      'is_deleted': false,
    }..removeWhere((key, value) => value == null);

    final inserted = await _supabase
        .from('chat_messages')
        .insert(data)
        .select()
        .single();

    return ChatMessage.fromJson(inserted);
  }

  Future<void> deleteMessage(String messageId) async {
    await _supabase
        .from('chat_messages')
        .update({'is_deleted': true})
        .eq('id', messageId);
  }

  Future<void> editMessage(String messageId, String newText) async {
    await _supabase
        .from('chat_messages')
        .update({
          'message': newText,
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', messageId);
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return;
    final parts = conversationId.split('_');
    if (parts.length != 2) return;
    final user1 = parts[0];
    final user2 = parts[1];
    final other = me == user1 ? user2 : user1;

    await _supabase
        .from('chat_messages')
        .update({'is_read': true})
        .eq('receiver_id', me)
        .eq('sender_id', other)
        .eq('is_deleted', false);
  }

  Future<void> deleteConversation(String conversationId) async {
    final parts = conversationId.split('_');
    if (parts.length != 2) return;
    final u1 = parts[0];
    final u2 = parts[1];

    await _supabase
        .from('chat_messages')
        .update({'is_deleted': true})
        .or(
          'and(sender_id.eq.$u1,receiver_id.eq.$u2),and(sender_id.eq.$u2,receiver_id.eq.$u1)',
        );
  }
}
