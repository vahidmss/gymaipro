import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BroadcastService {
  final SupabaseClient _client = Supabase.instance.client;

  // Send broadcast message to all clients
  Future<bool> sendBroadcastToAll(String senderId, String message,
      {String messageType = 'text'}) async {
    try {
      // Insert broadcast message
      final response = await _client
          .from('broadcast_messages')
          .insert({
            'sender_id': senderId,
            'message': message,
            'message_type': messageType,
            'recipient_type': 'all',
          })
          .select()
          .single();

      final broadcastId = response['id'];

      // Get all active clients for this trainer
      final clients = await _client
          .from('trainer_clients')
          .select('client_id')
          .eq('trainer_id', senderId)
          .eq('status', 'active');

      // Create broadcast recipients for all clients
      if (clients.isNotEmpty) {
        final recipients = clients
            .map((client) => {
                  'broadcast_id': broadcastId,
                  'recipient_id': client['client_id'],
                })
            .toList();

        await _client.from('broadcast_recipients').insert(recipients);
      }

      return true;
    } catch (e) {
      debugPrint('Error sending broadcast to all: $e');
      return false;
    }
  }

  // Send broadcast message to specific clients
  Future<bool> sendBroadcastToSpecific(
      String senderId, String message, List<String> recipientIds,
      {String messageType = 'text'}) async {
    try {
      // Insert broadcast message
      final response = await _client
          .from('broadcast_messages')
          .insert({
            'sender_id': senderId,
            'message': message,
            'message_type': messageType,
            'recipient_type': 'specific',
            'specific_recipients': recipientIds,
          })
          .select()
          .single();

      final broadcastId = response['id'];

      // Create broadcast recipients for specific clients
      final recipients = recipientIds
          .map((clientId) => {
                'broadcast_id': broadcastId,
                'recipient_id': clientId,
              })
          .toList();

      await _client.from('broadcast_recipients').insert(recipients);

      return true;
    } catch (e) {
      debugPrint('Error sending broadcast to specific: $e');
      return false;
    }
  }

  // Get broadcast messages for a user
  Future<List<Map<String, dynamic>>> getBroadcastMessages(String userId) async {
    try {
      final response = await _client
          .from('broadcast_messages')
          .select('''
            *,
            sender:profiles!broadcast_messages_sender_id_fkey(
              id,
              username,
              first_name,
              last_name,
              avatar_url,
              role
            ),
            recipients:broadcast_recipients!broadcast_recipients_broadcast_id_fkey(
              recipient_id,
              is_read,
              read_at
            )
          ''')
          .or('recipient_type.eq.all,recipient_type.eq.specific')
          .order('created_at', ascending: false);

      return response.map((data) {
        final sender = data['sender'] as Map<String, dynamic>;
        final recipients = data['recipients'] as List<dynamic>;

        // Check if current user is a recipient
        final isRecipient = data['recipient_type'] == 'all' ||
            recipients.any((r) => r['recipient_id'] == userId);

        // Check if current user has read this broadcast
        final userRecipient = recipients.firstWhere(
          (r) => r['recipient_id'] == userId,
          orElse: () => {'is_read': false, 'read_at': null},
        );

        return {
          'id': data['id'],
          'sender_id': data['sender_id'],
          'message': data['message'],
          'message_type': data['message_type'],
          'recipient_type': data['recipient_type'],
          'specific_recipients': data['specific_recipients'],
          'created_at': data['created_at'],
          'sender_name':
              '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'
                      .trim()
                      .isNotEmpty
                  ? '${sender['first_name'] ?? ''} ${sender['last_name'] ?? ''}'
                      .trim()
                  : sender['username'] ?? 'کاربر',
          'sender_avatar': sender['avatar_url'],
          'sender_role': sender['role'],
          'is_recipient': isRecipient,
          'is_read': userRecipient['is_read'] ?? false,
          'read_at': userRecipient['read_at'],
        };
      }).toList();
    } catch (e) {
      debugPrint('Error getting broadcast messages: $e');
      return [];
    }
  }

  // Mark broadcast message as read
  Future<bool> markBroadcastAsRead(String broadcastId, String userId) async {
    try {
      await _client
          .from('broadcast_recipients')
          .update({
            'is_read': true,
            'read_at': DateTime.now().toIso8601String(),
          })
          .eq('broadcast_id', broadcastId)
          .eq('recipient_id', userId);

      return true;
    } catch (e) {
      debugPrint('Error marking broadcast as read: $e');
      return false;
    }
  }

  // Get unread broadcast count for a user
  Future<int> getUnreadBroadcastCount(String userId) async {
    try {
      final response = await _client
          .from('broadcast_recipients')
          .select('broadcast_id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread broadcast count: $e');
      return 0;
    }
  }

  // Subscribe to broadcast messages for real-time updates
  Stream<List<Map<String, dynamic>>> subscribeToBroadcastMessages(
      String userId) {
    return _client
        .from('broadcast_messages')
        .stream(primaryKey: ['id'])
        .eq('sender_id', userId)
        .order('created_at')
        .map((event) => event.map((data) => data).toList());
  }
}
