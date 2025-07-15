import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/public_chat_message.dart';
import 'user_service.dart';

class PublicChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final UserService _userService = UserService();

  // دریافت آخرین پیام‌ها (با ترتیب زمانی)
  Future<List<PublicChatMessage>> getMessages(
      {int limit = 50, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('public_chat_messages')
          .select('''
            *,
            profiles!public_chat_messages_sender_id_fkey (
              first_name,
              last_name,
              avatar_url,
              role
            )
          ''')
          .eq('is_deleted', false)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      List<PublicChatMessage> messages = [];
      for (var item in response) {
        final profile = item['profiles'] as Map<String, dynamic>?;
        String? senderName;
        String? senderAvatar;
        String? senderRole;

        if (profile != null) {
          final firstName = profile['first_name'] as String?;
          final lastName = profile['last_name'] as String?;
          if (firstName != null && lastName != null) {
            senderName = '$firstName $lastName';
          } else if (firstName != null) {
            senderName = firstName;
          } else if (lastName != null) {
            senderName = lastName;
          } else if (item['username'] != null) {
            senderName = item['username'];
          } else {
            senderName = 'کاربر ناشناس';
          }
          senderAvatar = profile['avatar_url'] as String?;
          senderRole = profile['role'] as String?;
        } else {
          // اگر profile وجود ندارد، باز هم username را چک کن
          if (item['username'] != null) {
            senderName = item['username'];
          } else {
            senderName = 'کاربر ناشناس';
          }
        }

        messages.add(PublicChatMessage.fromJson({
          ...item,
          'sender_name': senderName,
          'sender_avatar': senderAvatar,
          'sender_role': senderRole,
        }));
      }

      return messages.reversed.toList();
    } catch (e) {
      rethrow;
    }
  }

  // ارسال پیام عمومی
  Future<PublicChatMessage> sendMessage({
    required String message,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      // ابتدا فقط پیام را ارسال کن (بدون اطلاعات اضافی)
      final data = {
        'sender_id': user.id,
        'message': message,
      };

      final response = await _supabase
          .from('public_chat_messages')
          .insert(data)
          .select()
          .single();

      // حالا اطلاعات کاربر را دریافت کن
      final displayName = await _userService.getDisplayName(user.id);
      final avatar = await _userService.getUserAvatar(user.id);
      final role = await _userService.getUserRole(user.id);

      // پیام را با اطلاعات کامل برگردان
      return PublicChatMessage.fromJson({
        ...response,
        'sender_name': displayName,
        'sender_avatar': avatar,
        'sender_role': role,
      });
    } catch (e) {
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
                final displayName =
                    await _userService.getDisplayName(msg.senderId);
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
    controller.onCancel = () {
      channel.unsubscribe();
    };
    return controller.stream;
  }

  // پاک کردن پیام (برای ادمین)
  Future<void> deleteMessage(String messageId) async {
    try {
      await _supabase
          .from('public_chat_messages')
          .update({'is_deleted': true}).eq('id', messageId);
    } catch (e) {
      rethrow;
    }
  }

  // دریافت تعداد پیام‌های نخوانده
  Future<int> getUnreadCount() async {
    try {
      final response = await _supabase
          .from('public_chat_messages')
          .select('id')
          .eq('is_deleted', false);

      return response.length;
    } catch (e) {
      return 0;
    }
  }
}
