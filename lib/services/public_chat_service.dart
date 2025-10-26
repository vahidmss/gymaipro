import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/services/user_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // دریافت آخرین پیام‌ها (با ترتیب زمانی)
  Future<List<PublicChatMessage>> getMessages({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // استفاده از view جدید که اطلاعات کامل sender را دارد
      final response = await _supabase
          .from('public_chat_with_senders')
          .select()
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final List<PublicChatMessage> messages = [];
      for (final item in response) {
        // ساخت نام کامل از first_name و last_name
        String? senderName;
        final firstName = item['sender_first_name'] as String?;
        final lastName = item['sender_last_name'] as String?;
        final username = item['sender_username'] as String?;

        if (firstName != null && lastName != null) {
          senderName = '$firstName $lastName';
        } else if (firstName != null) {
          senderName = firstName;
        } else if (lastName != null) {
          senderName = lastName;
        } else if (username != null) {
          senderName = username;
        } else {
          senderName = 'کاربر ناشناس';
        }

        messages.add(
          PublicChatMessage.fromJson({
            'id': item['id'],
            'sender_id': item['sender_id'],
            'message': item['message'],
            'created_at': item['created_at'],
            'updated_at': item['updated_at'],
            'is_deleted': item['is_deleted'],
            'sender_name': senderName,
            'sender_avatar': item['sender_avatar_url'],
            'sender_role': item['sender_role'],
          }),
        );
      }

      return messages.reversed.toList();
    } catch (e) {
      debugPrint('Error loading public chat messages: $e');
      rethrow;
    }
  }

  // ارسال پیام عمومی
  Future<PublicChatMessage> sendMessage({required String message}) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      print(
        '=== PUBLIC CHAT SERVICE: Sending message for user: ${user.id} ===',
      );

      // ابتدا فقط پیام را ارسال کن (بدون اطلاعات اضافی)
      final data = {'sender_id': user.id, 'message': message};

      final response = await _supabase
          .from('public_chat_messages')
          .insert(data)
          .select()
          .single();

      print('=== PUBLIC CHAT SERVICE: Message inserted successfully ===');

      // حالا اطلاعات کاربر را از view دریافت کن
      try {
        final userInfo = await _supabase
            .from('public_chat_with_senders')
            .select(
              'sender_username, sender_first_name, sender_last_name, sender_avatar_url, sender_role',
            )
            .eq('id', response['id'] as Object)
            .single();

        print('=== PUBLIC CHAT SERVICE: User info from view: $userInfo ===');

        final firstName = userInfo['sender_first_name'] as String?;
        final lastName = userInfo['sender_last_name'] as String?;
        final username = userInfo['sender_username'] as String?;
        final avatarUrl = userInfo['sender_avatar_url'] as String?;
        final role = userInfo['sender_role'] as String?;

        String senderName;
        if (firstName != null && lastName != null) {
          senderName = '$firstName $lastName';
        } else if (firstName != null) {
          senderName = firstName;
        } else if (lastName != null) {
          senderName = lastName;
        } else if (username != null && username.isNotEmpty) {
          senderName = username;
        } else {
          senderName = 'کاربر ناشناس';
        }

        print('=== PUBLIC CHAT SERVICE: Sender name: $senderName ===');

        // پیام را با اطلاعات کامل برگردان
        return PublicChatMessage.fromJson({
          ...response,
          'sender_name': senderName,
          'sender_avatar': avatarUrl,
          'sender_role': role ?? 'athlete',
        });
      } catch (e) {
        print(
          '=== PUBLIC CHAT SERVICE: Error getting user info from view: $e ===',
        );
        // اگر نتوانستیم از view اطلاعات بگیریم، از UserService استفاده کن
        final displayName = await _userService.getDisplayName(user.id);
        final avatar = await _userService.getUserAvatar(user.id);
        final role = await _userService.getUserRole(user.id);

        return PublicChatMessage.fromJson({
          ...response,
          'sender_name': displayName,
          'sender_avatar': avatar,
          'sender_role': role,
        });
      }
    } catch (e) {
      print('=== PUBLIC CHAT SERVICE: Error in sendMessage: $e ===');
      rethrow;
    }
  }

  // اشتراک به پیام‌های عمومی (realtime)
  Stream<PublicChatMessage> subscribeMessages() {
    final controller = StreamController<PublicChatMessage>();
    final channel = _supabase.channel('public_chat_messages');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'public_chat_messages',
          callback: (payload) async {
            final msg = PublicChatMessage.fromJson(payload.newRecord);
            if (!msg.isDeleted) {
              // اگر اطلاعات کاربر موجود نباشد، آن را دریافت کن
              if (msg.senderName == null) {
                final displayName = await _userService.getDisplayName(
                  msg.senderId,
                );
                final avatar = await _userService.getUserAvatar(msg.senderId);
                final role = await _userService.getUserRole(msg.senderId);

                final updatedMsg = msg.copyWith(
                  senderName: displayName,
                  senderAvatar: avatar,
                  senderRole: role,
                );
                controller.add(updatedMsg);
              } else {
                controller.add(msg);
              }
            }
          },
        )
        .subscribe();
    controller.onCancel = channel.unsubscribe;
    return controller.stream;
  }

  // پاک کردن پیام (برای ادمین)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('public_chat_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  // دریافت تعداد پیام‌های نخوانده
  Future<int> getUnreadCount() async {
    try {
      final response = await _supabase
          .from('public_chat_with_senders')
          .select('id')
          .eq('is_deleted', false);

      return response.length;
    } catch (e) {
      debugPrint('Error getting unread count: $e');
      return 0;
    }
  }

  // متد تست برای بررسی پیام‌ها
  Future<void> debugMessages() async {
    try {
      debugPrint('=== Debug: Loading public chat messages ===');
      final response = await _supabase
          .from('public_chat_with_senders')
          .select()
          .limit(5);

      debugPrint('Found ${response.length} messages');
      for (final item in response) {
        debugPrint(
          'Message: ${item['message']} from ${item['sender_first_name']} ${item['sender_last_name']}',
        );
      }
    } catch (e) {
      debugPrint('Debug error: $e');
    }
  }
}
