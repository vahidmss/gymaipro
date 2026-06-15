import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/chat/models/user_chat_message.dart';
import 'package:gymaipro/chat/services/chat_cache_service.dart';
import 'package:gymaipro/notification/notification_service.dart';
import 'package:gymaipro/user_profile/services/user_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ChatService: handles private/direct chat operations using Supabase
/// Uses JSONB model: messages stored in chat_conversations.messages field
class ChatService {
  ChatService() : _supabase = Supabase.instance.client;

  final SupabaseClient _supabase;
  final ChatCacheService _cache = ChatCacheService();

  // Helpers
  List<String> _sortedUserIds(String a, String b) {
    final ids = [a, b]..sort();
    return ids;
  }

  // نمایش نام کاربری بر اساس پروفایل (با fallback معقول)
  String _buildDisplayNameFromProfile(Map<String, dynamic>? profile) =>
      UserProfileService.displayNameFromMap(profile);

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
      final currentUserInfo =
          await UserProfileService.fetchProfile(currentUserId);
      final otherUserInfo = await UserProfileService.fetchProfile(otherUserId);

      final currentUserName = _buildDisplayNameFromProfile(currentUserInfo);
      final otherUserName = _buildDisplayNameFromProfile(otherUserInfo);

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
    } catch (_) {
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
    } catch (_) {
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

      final conversations = rows
          .cast<Map<String, dynamic>>()
          .map(ChatConversation.fromJson)
          .toList();
      unawaited(_cache.persistConversations(conversations));
      return conversations;
    } catch (_) {
      return _cache.getConversationsMemory().isNotEmpty
          ? _cache.getConversationsMemory()
          : await _cache.loadConversationsDisk();
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

  List<ChatMessage> _parseMessagesJson(List<dynamic> messagesJson) {
    return messagesJson
        .cast<Map<String, dynamic>>()
        .map((json) {
          try {
            final jsonCopy = Map<String, dynamic>.from(json);
            if (jsonCopy['created_at'] != null &&
                jsonCopy['created_at'] is! String) {
              jsonCopy['created_at'] =
                  (jsonCopy['created_at'] as DateTime).toIso8601String();
            }
            if (jsonCopy['updated_at'] != null &&
                jsonCopy['updated_at'] is! String) {
              jsonCopy['updated_at'] =
                  (jsonCopy['updated_at'] as DateTime).toIso8601String();
            }
            return ChatMessage.fromJson(jsonCopy);
          } catch (_) {
            return null;
          }
        })
        .whereType<ChatMessage>()
        .where((msg) {
          if (msg.messageType == 'admin_warning') return true;
          return !msg.isDeleted;
        })
        .toList()
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
  }

  /// [loadedFromEnd]: تعداد پیام‌هایی که از انتهای لیست (جدیدترین) قبلاً لود شده.
  /// ۰ = آخرین [limit] پیام؛ برای load-more مقدار فعلی طول لیست روی صفحه.
  List<ChatMessage> _sliceMessagesFromEnd(
    List<ChatMessage> allMessages, {
    required int loadedFromEnd,
    required int limit,
  }) {
    final total = allMessages.length;
    final end = total - loadedFromEnd;
    final start = (end - limit).clamp(0, end);
    if (start >= end) return [];
    return allMessages.sublist(start, end);
  }

  Future<List<ChatMessage>> getMessages(
    String otherUserId, {
    int limit = 50,
    int loadedFromEnd = 0,
    int offset = 0,
  }) async {
    final me = _supabase.auth.currentUser?.id;
    if (me == null) return [];

    final fromEnd = offset > 0 ? offset : loadedFromEnd;

    try {
      final conversation = await _getOrCreateConversation(me, otherUserId);
      if (conversation == null) return [];

      final response = await _supabase
          .from('chat_conversations')
          .select('messages')
          .eq('id', conversation.id)
          .single();

      final allMessages =
          _parseMessagesJson(response['messages'] as List<dynamic>? ?? []);
      final page = _sliceMessagesFromEnd(
        allMessages,
        loadedFromEnd: fromEnd,
        limit: limit,
      );
      if (fromEnd == 0) {
        saveCachedMessages(otherUserId, page);
      }
      return page;
    } catch (_) {
      if (fromEnd == 0) {
        final disk = await _cache.loadMessagesDisk(otherUserId);
        if (disk.isNotEmpty) {
          return _sliceMessagesFromEnd(
            disk,
            loadedFromEnd: 0,
            limit: limit,
          );
        }
      }
      return getCachedMessages(otherUserId);
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
              } catch (_) {}
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
      );

      // Get current messages
      final response = await _supabase
          .from('chat_conversations')
          .select(
            'messages, user1_id, user2_id, user1_unread_count, user2_unread_count',
          )
          .eq('id', conversation.id)
          .single()
          .timeout(const Duration(seconds: 8));

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
        } catch (_) {
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
          .eq('id', conversation.id)
          .timeout(const Duration(seconds: 8));

      final cached = getCachedMessages(receiverId);
      final merged = [
        ...cached.where((m) => m.id != newMessage.id),
        newMessage,
      ];
      saveCachedMessages(receiverId, merged);

      unawaited(
        _sendChatNotificationInBackground(
          receiverId: receiverId,
          senderId: me,
          message: message.trim(),
          messageId: messageId,
          messageType: messageType,
          conversationId: conversation.id,
        ),
      );

      return newMessage;
    } on TimeoutException {
      throw Exception(
        'ارسال پیام بیش از حد طول کشید. اینترنت را بررسی کنید و دوباره تلاش کنید.',
      );
    } on PostgrestException catch (e) {
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
            ? e.message
            : (e.code ?? 'خطای ناشناخته');
        throw Exception('خطا در ارسال پیام: $errorMsg');
      }
    } catch (e) {
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
    } catch (_) {}
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
    } catch (_) {}
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
    } catch (_) {}
  }

  Future<void> deleteConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);
    } catch (_) {}
  }

  List<ChatMessage> getCachedMessages(String otherUserId) {
    return _cache.getMessagesMemory(otherUserId);
  }

  void saveCachedMessages(String otherUserId, List<ChatMessage> messages) {
    final sorted = List<ChatMessage>.from(messages)
      ..sort((a, b) => a.createdAt.compareTo(b.createdAt));
    _cache.setMessagesMemory(otherUserId, sorted);
    unawaited(_cache.persistMessages(otherUserId, sorted));
  }

  Future<void> clearAllCaches() async {
    await _cache.clearAllForCurrentUser();
    ChatCacheService.clearAllMemory();
  }

  Future<List<ChatMessage>> getMessagesByConversationId(
    String conversationId, {
    int limit = 50,
    int loadedFromEnd = 0,
    int offset = 0,
  }) async {
    final fromEnd = offset > 0 ? offset : loadedFromEnd;
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select('messages, user1_id, user2_id')
          .eq('id', conversationId)
          .maybeSingle();
      if (response == null) return [];

      final allMessages =
          _parseMessagesJson(response['messages'] as List<dynamic>? ?? []);
      return _sliceMessagesFromEnd(
        allMessages,
        loadedFromEnd: fromEnd,
        limit: limit,
      );
    } catch (_) {
      return [];
    }
  }

  Future<void> _sendChatNotificationInBackground({
    required String receiverId,
    required String senderId,
    required String message,
    required String messageId,
    required String messageType,
    required String conversationId,
  }) async {
    try {
      final senderName =
          await UserProfileService.getDisplayName(senderId);
      await NotificationService().sendChatNotification(
        receiverId: receiverId,
        senderId: senderId,
        senderName: senderName,
        message: message,
        messageId: messageId,
        messageType: messageType,
        conversationId: conversationId,
      );
    } catch (e) {
      if (kDebugMode) {
        debugPrint('ChatService: background notification failed: $e');
      }
    }
  }
}
