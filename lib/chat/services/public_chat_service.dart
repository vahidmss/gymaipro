import 'dart:async';

import 'package:flutter/material.dart';
import 'package:gymaipro/chat/models/public_chat_message.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PublicChatService {
  final SupabaseClient _supabase = Supabase.instance.client;
  final ProfileRepository _profiles = ProfileRepository.instance;

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

      // دریافت profile ID (نه auth user ID) چون foreign key به profiles.id است
      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) {
        throw Exception('Profile not found');
      }

      // بررسی بلاک بودن کاربر در چت عمومی
      final raw = profile['public_chat_blocked_until'];
      final blockedUntilStr = raw is String ? raw : raw?.toString();
      if (blockedUntilStr != null) {
        final blockedUntil = DateTime.tryParse(blockedUntilStr);
        if (blockedUntil != null &&
            blockedUntil.isAfter(DateTime.now().toUtc())) {
          final reason =
              profile['public_chat_block_reason'] as String? ?? '';
          final formattedUntil =
              '${blockedUntil.toLocal().year}/${blockedUntil.toLocal().month.toString().padLeft(2, '0')}/${blockedUntil.toLocal().day.toString().padLeft(2, '0')}';
          // از یک پیشوند اختصاصی استفاده می‌کنیم تا در UI راحت تشخیص دهیم
          final baseMessage = reason.isNotEmpty
              ? reason
              : 'شما تا تاریخ $formattedUntil از ارسال پیام در چت عمومی مسدود هستید.';
          throw Exception('[PUBLIC_CHAT_BLOCK] $baseMessage');
        }
      }

      final profileId = profile['id'] as String;

      // استفاده از profile.id به جای user.id برای foreign key constraint
      final data = {'sender_id': profileId, 'message': message};

      final response = await _supabase
          .from('public_chat_messages')
          .insert(data)
          .select()
          .single();

      // حالا اطلاعات کاربر را از view دریافت کن
      try {
        final userInfo = await _supabase
            .from('public_chat_with_senders')
            .select(
              'sender_username, sender_first_name, sender_last_name, sender_avatar_url, sender_role',
            )
            .eq('id', response['id'] as Object)
            .single();

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

        // پیام را با اطلاعات کامل برگردان
        return PublicChatMessage.fromJson({
          ...response,
          'sender_name': senderName,
          'sender_avatar': avatarUrl,
          'sender_role': role ?? 'athlete',
        });
      } catch (_) {
        // اگر نتوانستیم از view اطلاعات بگیریم، از UserService استفاده کن
        final displayName = await _profiles.getDisplayName(user.id);
        final avatar = await _profiles.getUserAvatar(user.id);
        final role = await _profiles.getUserRole(user.id);

        return PublicChatMessage.fromJson({
          ...response,
          'sender_name': displayName,
          'sender_avatar': avatar,
          'sender_role': role,
        });
      }
    } catch (e) {
      rethrow;
    }
  }

  // اشتراک به پیام‌های عمومی (realtime)
  Stream<PublicChatMessage> subscribeMessages() {
    final controller = StreamController<PublicChatMessage>();
    final channel = _supabase.channel('public_chat_messages');
    // رویدادهای INSERT (پیام جدید)
    channel.onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'public_chat_messages',
      callback: (payload) async {
        final msg = PublicChatMessage.fromJson(payload.newRecord);

        // اگر اطلاعات کاربر موجود نباشد، آن را دریافت کن
        if (msg.senderName == null) {
          final displayName = await _profiles.getDisplayName(
            msg.senderId,
          );
          final avatar = await _profiles.getUserAvatar(msg.senderId);
          final role = await _profiles.getUserRole(msg.senderId);

          final updatedMsg = msg.copyWith(
            senderName: displayName,
            senderAvatar: avatar,
            senderRole: role,
          );
          controller.add(updatedMsg);
        } else {
          controller.add(msg);
        }
      },
    );

    // رویدادهای UPDATE (مثل حذف توسط ادمین: is_deleted = true)
    channel.onPostgresChanges(
      event: PostgresChangeEvent.update,
      schema: 'public',
      table: 'public_chat_messages',
      callback: (payload) async {
        final msg = PublicChatMessage.fromJson(payload.newRecord);

        // برای آپدیت هم همان منطق تکمیل اطلاعات کاربر را حفظ می‌کنیم
        if (msg.senderName == null) {
          final displayName = await _profiles.getDisplayName(
            msg.senderId,
          );
          final avatar = await _profiles.getUserAvatar(msg.senderId);
          final role = await _profiles.getUserRole(msg.senderId);

          final updatedMsg = msg.copyWith(
            senderName: displayName,
            senderAvatar: avatar,
            senderRole: role,
          );
          controller.add(updatedMsg);
        } else {
          controller.add(msg);
        }
      },
    );

    channel.subscribe();
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

}
