import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ChatService: handles private/direct chat operations using Supabase
/// Uses JSONB model: messages stored in chat_conversations.messages field
class ChatService {
  ChatService() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;

  // Helpers
  List<String> _sortedUserIds(String a, String b) {
    final ids = [a, b]..sort();
    return ids;
  }

  // Get or create conversation
  Future<ChatConversation?> _getOrCreateConversation(
    String currentUserId,
    String otherUserId,
  ) async {
    try {
      final sorted = _sortedUserIds(currentUserId, otherUserId);
      final user1Id = sorted[0];
      final user2Id = sorted[1];

      // Try to find existing conversation
      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('user1_id', user1Id)
          .eq('user2_id', user2Id)
          .maybeSingle();

      if (response != null) {
        return ChatConversation.fromJson(response);
      }

      // Create new conversation
      // First, get user info for names and avatars
      final currentUserInfo = await _supabase
          .from('profiles')
          .select('first_name, last_name, username, avatar_url')
          .eq('id', currentUserId)
          .maybeSingle();

      final otherUserInfo = await _supabase
          .from('profiles')
          .select('first_name, last_name, username, avatar_url')
          .eq('id', otherUserId)
          .maybeSingle();

      String currentUserName = '';
      if (currentUserInfo != null) {
        final firstName = currentUserInfo['first_name'] as String? ?? '';
        final lastName = currentUserInfo['last_name'] as String? ?? '';
        final username = currentUserInfo['username'] as String? ?? '';
        currentUserName = firstName.isNotEmpty && lastName.isNotEmpty
            ? '$firstName $lastName'
            : (username.isNotEmpty ? username : 'کاربر');
      }

      String otherUserName = '';
      if (otherUserInfo != null) {
        final firstName = otherUserInfo['first_name'] as String? ?? '';
        final lastName = otherUserInfo['last_name'] as String? ?? '';
        final username = otherUserInfo['username'] as String? ?? '';
        otherUserName = firstName.isNotEmpty && lastName.isNotEmpty
            ? '$firstName $lastName'
            : (username.isNotEmpty ? username : 'کاربر');
      }

      final newConv = {
        'user1_id': user1Id,
        'user2_id': user2Id,
        'user1_name': currentUserId == user1Id ? currentUserName : otherUserName,
        'user2_name': currentUserId == user1Id ? otherUserName : currentUserName,
        'user1_avatar': currentUserId == user1Id
            ? (currentUserInfo?['avatar_url'] as String?)
            : (otherUserInfo?['avatar_url'] as String?),
        'user2_avatar': currentUserId == user1Id
            ? (otherUserInfo?['avatar_url'] as String?)
            : (currentUserInfo?['avatar_url'] as String?),
        'messages': <Map<String, dynamic>>[],
        'message_count': 0,
        'user1_unread_count': 0,
        'user2_unread_count': 0,
      };

      final inserted = await _supabase
          .from('chat_conversations')
          .insert(newConv)
          .select()
          .single();

      return ChatConversation.fromJson(inserted);
    } catch (e) {
      debugPrint('ChatService._getOrCreateConversation error: $e');
      return null;
    }
  }

  // Conversations
  Future<void> ensureConversationExists(String otherUserId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return;
    await _getOrCreateConversation(me, otherUserId);
  }

  Future<ChatConversation?> getConversationByUserId(String otherUserId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return null;

    try {
      return await _getOrCreateConversation(me, otherUserId);
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
          .from('chat_conversations')
          .select()
          .or('user1_id.eq.$me,user2_id.eq.$me')
          .order('updated_at', ascending: false);

      return rows
          .cast<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
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
          table: 'chat_conversations',
          callback: (payload) async {
            final row = payload.newRecord;
            final user1Id = row['user1_id'] as String?;
            final user2Id = row['user2_id'] as String?;
            if (user1Id == null || user2Id == null) return;
            if (user1Id != me && user2Id != me) return;
            final conv = ChatConversation.fromJson(row);
            controller.add(conv);
          },
        )
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_conversations',
          callback: (payload) async {
            final row = payload.newRecord;
            final user1Id = row['user1_id'] as String?;
            final user2Id = row['user2_id'] as String?;
            if (user1Id == null || user2Id == null) return;
            if (user1Id != me && user2Id != me) return;
            final conv = ChatConversation.fromJson(row);
            controller.add(conv);
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
      final conversation = await _getOrCreateConversation(me, otherUserId);
      if (conversation == null) return [];

      // Get messages from JSONB field
      final response = await _supabase
          .from('chat_conversations')
          .select('messages')
          .eq('id', conversation.id)
          .single();

      final messagesJson = response['messages'] as List<dynamic>? ?? [];
      final allMessages = messagesJson
          .cast<Map<String, dynamic>>()
          .map((json) {
            try {
              // Ensure created_at and updated_at are strings for parsing
              final jsonCopy = Map<String, dynamic>.from(json);
              if (jsonCopy['created_at'] != null && jsonCopy['created_at'] is! String) {
                jsonCopy['created_at'] = (jsonCopy['created_at'] as DateTime).toIso8601String();
              }
              if (jsonCopy['updated_at'] != null && jsonCopy['updated_at'] is! String) {
                jsonCopy['updated_at'] = (jsonCopy['updated_at'] as DateTime).toIso8601String();
              }
              return ChatMessage.fromJson(jsonCopy);
            } catch (e) {
              debugPrint('Error parsing message: $e');
              debugPrint('Message JSON: $json');
              return null;
            }
          })
          .whereType<ChatMessage>()
          .where((msg) {
            // پیام‌های admin_warning همیشه نمایش داده می‌شوند
            if (msg.messageType == 'admin_warning') {
              return true;
            }
            // پیام‌های عادی فقط اگر حذف نشده باشند
            return !msg.isDeleted;
          })
          .toList();

      // Sort by created_at ascending (oldest first) for proper display with reverse ListView
      allMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      // Apply pagination (get latest messages first when offset is 0)
      if (offset == 0) {
        // Return latest messages (last N messages)
        final start = allMessages.length > limit 
            ? allMessages.length - limit 
            : 0;
        return allMessages.sublist(start);
      } else {
        // For pagination, return older messages
        final start = offset;
        final end = offset + limit;
        if (start >= allMessages.length) return [];
        return allMessages.sublist(
          start,
          end < allMessages.length ? end : allMessages.length,
        );
      }
    } catch (e) {
      debugPrint('ChatService.getMessages error: $e');
      return [];
    }
  }

  Stream<ChatMessage> subscribeToMessages(String otherUserId) {
    final me = _supabase.auth.currentUser?.id;
    final controller = StreamController<ChatMessage>.broadcast();
    if (me == null) return controller.stream;

    final channel = _supabase.channel('chat_messages_${me}_$otherUserId');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'chat_conversations',
          callback: (payload) async {
            final row = payload.newRecord;
            final user1Id = row['user1_id'] as String?;
            final user2Id = row['user2_id'] as String?;
            if (user1Id == null || user2Id == null) return;

            // Check if this conversation involves current user and other user
            final sorted = _sortedUserIds(me, otherUserId);
            if (user1Id != sorted[0] || user2Id != sorted[1]) return;

            // Get latest message from messages array
            final messagesJson = row['messages'] as List<dynamic>? ?? [];
            if (messagesJson.isNotEmpty) {
              try {
                final latestMsgJson = messagesJson.last as Map<String, dynamic>;
                final message = ChatMessage.fromJson(latestMsgJson);
                controller.add(message);
              } catch (e) {
                debugPrint('Error parsing message from stream: $e');
              }
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
      throw Exception('کاربر احراز هویت نشده است');
    }

    if (receiverId.isEmpty) {
      throw Exception('شناسه دریافت‌کننده معتبر نیست');
    }

    if (message.trim().isEmpty) {
      throw Exception('پیام نمی‌تواند خالی باشد');
    }

    try {
      debugPrint('=== CHAT SERVICE: Attempting to send message ===');
      debugPrint('Sender: $me');
      debugPrint('Receiver: $receiverId');
      debugPrint('Message length: ${message.length}');

      // Get or create conversation
      final conversation = await _getOrCreateConversation(me, receiverId);
      if (conversation == null) {
        throw Exception('خطا در ایجاد یا یافتن مکالمه');
      }

      // Create new message with unique ID
      final now = DateTime.now();
      final messageId = '${me}_${receiverId}_${now.millisecondsSinceEpoch}_${message.hashCode}';
      
      final newMessage = ChatMessage(
        id: messageId,
        senderId: me,
        receiverId: receiverId,
        message: message.trim(),
        messageType: messageType,
        attachmentUrl: attachmentUrl,
        attachmentType: attachmentType,
        attachmentName: attachmentName,
        attachmentSize: attachmentSize,
        createdAt: now,
        updatedAt: now,
        isRead: false,
        isDeleted: false,
      );

      // Get current messages
      final response = await _supabase
          .from('chat_conversations')
          .select('messages, user1_id, user2_id')
          .eq('id', conversation.id)
          .single();

      final currentMessages = (response['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      // Add new message to the end (will be sorted when retrieved)
      currentMessages.add(newMessage.toJson());
      
      // Sort messages by created_at to maintain chronological order
      currentMessages.sort((a, b) {
        try {
          final aTime = a['created_at'] is String
              ? DateTime.parse(a['created_at'] as String)
              : (a['created_at'] as DateTime? ?? DateTime.now());
          final bTime = b['created_at'] is String
              ? DateTime.parse(b['created_at'] as String)
              : (b['created_at'] as DateTime? ?? DateTime.now());
          return aTime.compareTo(bTime);
        } catch (e) {
          debugPrint('Error sorting messages: $e');
          return 0;
        }
      });

      // Determine which user is sender for unread count
      final user1Id = response['user1_id'] as String;
      final isUser1Sender = me == user1Id;

      // Update conversation
      final updateData = {
        'messages': currentMessages,
        'message_count': currentMessages.length,
        'last_message': message.trim(),
        'last_message_at': DateTime.now().toIso8601String(),
        'last_message_sender_id': me,
        'updated_at': DateTime.now().toIso8601String(),
        if (isUser1Sender) 'user2_unread_count': (response['user2_unread_count'] as int? ?? 0) + 1,
        if (!isUser1Sender) 'user1_unread_count': (response['user1_unread_count'] as int? ?? 0) + 1,
      };

      await _supabase
          .from('chat_conversations')
          .update(updateData)
          .eq('id', conversation.id);

      debugPrint('=== CHAT SERVICE: Message sent successfully ===');

      // ارسال نوتیفیکیشن به گیرنده
      try {
        // دریافت نام فرستنده از پروفایل
        String senderName = 'کاربر';
        try {
          final senderProfile = await _supabase
              .from('profiles')
              .select('first_name, last_name, username')
              .eq('id', me)
              .maybeSingle();
          
          if (senderProfile != null) {
            final firstName = (senderProfile['first_name'] as String?)?.trim() ?? '';
            final lastName = (senderProfile['last_name'] as String?)?.trim() ?? '';
            final username = (senderProfile['username'] as String?)?.trim() ?? '';
            
            if (firstName.isNotEmpty && lastName.isNotEmpty) {
              senderName = '$firstName $lastName';
            } else if (firstName.isNotEmpty) {
              senderName = firstName;
            } else if (lastName.isNotEmpty) {
              senderName = lastName;
            } else if (username.isNotEmpty) {
              senderName = username;
            }
          }
        } catch (e) {
          debugPrint('⚠️ Error getting sender name for notification: $e');
        }

        // ارسال نوتیفیکیشن
        final notificationService = NotificationService();
        await notificationService.sendChatNotification(
          receiverId: receiverId,
          senderId: me,
          senderName: senderName,
          message: message.trim(),
          messageId: messageId,
          messageType: messageType,
          conversationId: conversation.id,
        );
        debugPrint('✅ Chat notification sent successfully');
      } catch (e) {
        // در صورت خطا در ارسال نوتیفیکیشن، پیام همچنان ارسال شده است
        debugPrint('⚠️ Error sending chat notification: $e');
      }

      return newMessage;
    } on PostgrestException catch (e) {
      debugPrint('=== CHAT SERVICE: PostgrestException in sendMessage ===');
      debugPrint('Code: ${e.code}');
      debugPrint('Message: ${e.message}');
      debugPrint('Details: ${e.details}');
      debugPrint('Hint: ${e.hint}');

      // Handle specific error codes
      if (e.code == '42P01') {
        throw Exception(
          'جدول مکالمات در دیتابیس وجود ندارد. لطفاً با پشتیبانی تماس بگیرید.',
        );
      } else if (e.code == 'PGRST116' || e.code == '404') {
        throw Exception(
          'خطا در ارسال پیام: جدول یا دسترسی مورد نیاز یافت نشد. لطفاً اتصال اینترنت خود را بررسی کنید.',
        );
      } else if (e.code == '42501') {
        throw Exception(
          'شما اجازه ارسال پیام ندارید. لطفاً دوباره وارد شوید.',
        );
      } else {
        final errorMsg = e.message is Map
            ? e.message.toString()
            : (e.code ?? 'خطای ناشناخته');
        throw Exception('خطا در ارسال پیام: $errorMsg');
      }
    } catch (e) {
      debugPrint('=== CHAT SERVICE: Unexpected error in sendMessage: $e ===');
      throw Exception('خطا در ارسال پیام: $e');
    }
  }

  Future<void> deleteMessage(String messageId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return;

    try {
      // Find conversation containing this message
      final conversations = await _supabase
          .from('chat_conversations')
          .select('id, messages, user1_id, user2_id')
          .or('user1_id.eq.$me,user2_id.eq.$me');

      for (final conv in conversations) {
        final messages = (conv['messages'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .toList();

        final messageIndex = messages.indexWhere(
          (m) => m['id'] == messageId && m['sender_id'] == me,
        );

        if (messageIndex != -1) {
          // Mark as deleted
          messages[messageIndex]['is_deleted'] = true;
          messages[messageIndex]['updated_at'] = DateTime.now().toIso8601String();

          await _supabase
              .from('chat_conversations')
              .update({
                'messages': messages,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', conv['id'] as String);
          return;
        }
      }
    } catch (e) {
      debugPrint('ChatService.deleteMessage error: $e');
    }
  }

  Future<void> editMessage(String messageId, String newText) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return;

    try {
      // Find conversation containing this message
      final conversations = await _supabase
          .from('chat_conversations')
          .select('id, messages')
          .or('user1_id.eq.$me,user2_id.eq.$me');

      for (final conv in conversations) {
        final messages = (conv['messages'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .toList();

        final messageIndex = messages.indexWhere(
          (m) => m['id'] == messageId && m['sender_id'] == me,
        );

        if (messageIndex != -1) {
          messages[messageIndex]['message'] = newText;
          messages[messageIndex]['updated_at'] = DateTime.now().toIso8601String();

          await _supabase
              .from('chat_conversations')
              .update({
                'messages': messages,
                'updated_at': DateTime.now().toIso8601String(),
              })
              .eq('id', conv['id'] as String);
          return;
        }
      }
    } catch (e) {
      debugPrint('ChatService.editMessage error: $e');
    }
  }

  Future<void> markConversationAsRead(String conversationId) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return;

    try {
      final conversation = await _supabase
          .from('chat_conversations')
          .select('id, user1_id, user2_id, messages')
          .eq('id', conversationId)
          .maybeSingle();

      if (conversation == null) return;

      final user1Id = conversation['user1_id'] as String;
      final isUser1 = me == user1Id;

      // Update messages to mark as read
      final messages = (conversation['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      bool updated = false;
      for (final msg in messages) {
        if (msg['receiver_id'] == me && msg['is_read'] == false) {
          msg['is_read'] = true;
          updated = true;
        }
      }

      if (updated) {
        final updateData = {
          'messages': messages,
          if (isUser1) 'user1_unread_count': 0,
          if (!isUser1) 'user2_unread_count': 0,
          if (isUser1) 'user1_last_read_at': DateTime.now().toIso8601String(),
          if (!isUser1) 'user2_last_read_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };

        await _supabase
            .from('chat_conversations')
            .update(updateData)
            .eq('id', conversationId);
      }
    } catch (e) {
      debugPrint('ChatService.markConversationAsRead error: $e');
    }
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);
    } catch (e) {
      debugPrint('ChatService.deleteConversation error: $e');
    }
  }
}
