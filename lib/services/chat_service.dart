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
          .eq('user_id', user.id)
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
    String? attachmentUrl,
    String? attachmentType,
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
        'attachment_url': attachmentUrl,
        'attachment_type': attachmentType,
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

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase.from('chat_messages').delete().eq('id', messageId);
    } catch (e) {
      debugPrint('Error deleting message: $e');
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
    final channel = _supabase.channel('chat_messages');
    final subscription = channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) {
            final message = ChatMessage.fromJson(payload.newRecord);
            // Filter messages for this conversation only
            if ((message.senderId == userId &&
                    message.receiverId == otherUserId) ||
                (message.senderId == otherUserId &&
                    message.receiverId == userId)) {
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

    // First, subscribe to new messages
    final channel = _supabase.channel('chat_conversations');
    final subscription = channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'chat_messages',
          callback: (payload) async {
            final message = ChatMessage.fromJson(payload.newRecord);
            // Filter messages for this user only
            if (message.senderId == userId || message.receiverId == userId) {
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

      // Get trainers for this client
      final response = await _supabase
          .from('trainer_clients')
          .select('trainer:trainer_id(id, profiles(id, full_name, avatar_url))')
          .eq('client_id', user.id);

      return (response as List).map((item) {
        final trainer = item['trainer']['profiles'];
        return {
          'id': trainer['id'],
          'name': trainer['full_name'],
          'avatar': trainer['avatar_url'],
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

      // Get clients for this trainer
      final response = await _supabase
          .from('trainer_clients')
          .select('client:client_id(id, profiles(id, full_name, avatar_url))')
          .eq('trainer_id', user.id);

      return (response as List).map((item) {
        final client = item['client']['profiles'];
        return {
          'id': client['id'],
          'name': client['full_name'],
          'avatar': client['avatar_url'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting clients: $e');
      rethrow;
    }
  }
}
