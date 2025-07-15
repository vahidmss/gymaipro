import 'dart:async';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gymaipro/models/chat_message.dart';
import 'package:gymaipro/services/supabase_service.dart';

class ChatService {
  final SupabaseService _supabaseService;
  final SupabaseClient _supabase;

  ChatService({required SupabaseService supabaseService})
      : _supabaseService = supabaseService,
        _supabase = Supabase.instance.client;

  // Get all conversations for the current user
  Future<List<ChatConversation>> getConversations() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('chat_conversations')
          .select()
          .order('last_message_at', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error getting conversations: $e');
      rethrow;
    }
  }

  // Get messages between current user and another user
  Future<List<ChatMessage>> getMessages(String otherUserId,
      {int limit = 50, int offset = 0}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final userId = user.id;
      final response = await _supabase
          .from('chat_messages')
          .select()
          .or('and(sender_id.eq.$userId,receiver_id.eq.$otherUserId),and(sender_id.eq.$otherUserId,receiver_id.eq.$userId)')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List)
          .map((json) => ChatMessage.fromJson(json))
          .toList()
          .reversed
          .toList(); // Return in chronological order
    } catch (e) {
      debugPrint('Error getting messages: $e');
      rethrow;
    }
  }

  // Send a message to another user
  Future<ChatMessage> sendMessage({
    required String receiverId,
    required String message,
    String messageType = 'text',
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
  }) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final messageData = {
        'sender_id': user.id,
        'receiver_id': receiverId,
        'message': message,
        'message_type': messageType,
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
        'attachment_name': attachmentName,
        'attachment_size': attachmentSize,
      };

      final response = await _supabase
          .from('chat_messages')
          .insert(messageData)
          .select()
          .single();

      return ChatMessage.fromJson(response);
    } catch (e) {
      debugPrint('Error sending message: $e');
      rethrow;
    }
  }

  // Mark messages from a specific sender as read
  Future<void> markMessagesAsRead(String senderId) async {
    try {
      await _supabase
          .rpc('mark_messages_as_read', params: {'p_sender_id': senderId});
    } catch (e) {
      debugPrint('Error marking messages as read: $e');
      rethrow;
    }
  }

  // Mark conversation as read
  Future<void> markConversationAsRead(String otherUserId) async {
    try {
      await _supabase.rpc('mark_conversation_as_read',
          params: {'p_other_user_id': otherUserId});
    } catch (e) {
      debugPrint('Error marking conversation as read: $e');
      rethrow;
    }
  }

  // Get unread message count
  Future<int> getUnreadMessageCount() async {
    try {
      final response = await _supabase.rpc('get_unread_message_count');
      return response as int;
    } catch (e) {
      debugPrint('Error getting unread message count: $e');
      return 0;
    }
  }

  // Delete a message (soft delete)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('chat_messages')
          .update({'is_deleted': true}).eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
      rethrow;
    }
  }

  // Edit a message
  Future<void> editMessage(String messageId, String newMessage) async {
    try {
      await _supabase.from('chat_messages').update({
        'message': newMessage,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', messageId);
    } catch (e) {
      debugPrint('Error editing message: $e');
      rethrow;
    }
  }

  // Subscribe to messages in a conversation
  Stream<ChatMessage> subscribeToMessages(String otherUserId) {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userId = user.id;
    final controller = StreamController<ChatMessage>();

    // Subscribe to messages where current user is sender or receiver
    final channel = _supabase.channel('chat_messages_$otherUserId');
    final subscription = channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final message = ChatMessage.fromJson(payload.newRecord);
            // Filter messages for this conversation only and not deleted
            if (!message.isDeleted &&
                ((message.senderId == userId &&
                        message.receiverId == otherUserId) ||
                    (message.senderId == otherUserId &&
                        message.receiverId == userId))) {
              controller.add(message);
            }
          },
        )
        .subscribe();

    // Close the subscription when the stream is cancelled
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  // Subscribe to conversation updates (new messages from any user)
  Stream<ChatConversation> subscribeToConversations() {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final userId = user.id;
    final controller = StreamController<ChatConversation>();

    // Subscribe to new messages
    final channel = _supabase.channel('chat_conversations_$userId');
    final subscription = channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async {
            final message = ChatMessage.fromJson(payload.newRecord);
            // Filter messages for this user only and not deleted
            if (!message.isDeleted &&
                (message.senderId == userId || message.receiverId == userId)) {
              // When a new message arrives, fetch the updated conversation
              final otherUserId = message.senderId == userId
                  ? message.receiverId
                  : message.senderId;

              try {
                final response = await _supabase
                    .from('chat_conversations')
                    .select()
                    .eq('user_id', userId)
                    .eq('other_user_id', otherUserId)
                    .single();

                controller.add(ChatConversation.fromJson(response));
              } catch (e) {
                debugPrint('Error fetching conversation: $e');
              }
            }
          },
        )
        .subscribe();

    // Close the subscription when the stream is cancelled
    controller.onCancel = () {
      channel.unsubscribe();
    };

    return controller.stream;
  }

  // Get trainers the user can chat with (if user is a client)
  Future<List<Map<String, dynamic>>> getTrainers() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all trainers
      final response = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, role')
          .eq('role', 'trainer')
          .limit(20);

      return (response as List).map((item) {
        return {
          'id': item['id'],
          'name':
              '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim(),
          'avatar': item['avatar_url'],
          'role': item['role'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting trainers: $e');
      rethrow;
    }
  }

  // Get clients the user can chat with (if user is a trainer)
  Future<List<Map<String, dynamic>>> getClients() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // Get all athletes
      final response = await _supabase
          .from('profiles')
          .select('id, first_name, last_name, avatar_url, role')
          .eq('role', 'athlete')
          .limit(20);

      return (response as List).map((item) {
        return {
          'id': item['id'],
          'name':
              '${item['first_name'] ?? ''} ${item['last_name'] ?? ''}'.trim(),
          'avatar': item['avatar_url'],
          'role': item['role'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting clients: $e');
      rethrow;
    }
  }

  // Search conversations
  Future<List<ChatConversation>> searchConversations(String query) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('chat_conversations')
          .select()
          .ilike('other_user_name', '%$query%')
          .order('last_message_at', ascending: false);

      return (response as List)
          .map((json) => ChatConversation.fromJson(json))
          .toList();
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      rethrow;
    }
  }

  // Get conversation by user ID
  Future<ChatConversation?> getConversationByUserId(String otherUserId) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final response = await _supabase
          .from('chat_conversations')
          .select()
          .eq('other_user_id', otherUserId)
          .maybeSingle();

      if (response != null) {
        return ChatConversation.fromJson(response);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting conversation: $e');
      return null;
    }
  }

  // Create a new conversation (if it doesn't exist)
  Future<ChatConversation?> createConversation(String otherUserId) async {
    try {
      // First check if conversation already exists
      final existing = await getConversationByUserId(otherUserId);
      if (existing != null) {
        return existing;
      }

      // If no conversation exists, send a welcome message to create one
      await sendMessage(
        receiverId: otherUserId,
        message: 'سلام! 👋',
        messageType: 'text',
      );

      // Now get the conversation
      return await getConversationByUserId(otherUserId);
    } catch (e) {
      debugPrint('Error creating conversation: $e');
      return null;
    }
  }
}
