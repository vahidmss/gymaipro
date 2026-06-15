import 'package:flutter/material.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/profile/models/user_profile.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت ادمین
/// تمام عملیات‌های مدیریتی را انجام می‌دهد
class AdminService {
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<Map<String, Map<String, dynamic>>> _fetchProfilesByIds(
    Iterable<String?> ids, {
    String columns = 'id, username, first_name, last_name',
  }) async {
    final uniqueIds = ids
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();
    if (uniqueIds.isEmpty) return {};
    return ProfileRepository.instance.fetchProfilesByIdsMap(
      uniqueIds,
      columns: columns,
    );
  }

  List<Map<String, dynamic>> _attachProfileFields(
    List<Map<String, dynamic>> items, {
    required Map<String, Map<String, dynamic>> profilesById,
    required String idField,
    required String profileField,
  }) {
    return items.map((item) {
      final userId = item[idField] as String?;
      return {
        ...item,
        profileField: userId != null ? profilesById[userId] : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _attachUserAndTrainerProfiles(
    List<Map<String, dynamic>> items,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    return items.map((item) {
      final userId = item['user_id'] as String?;
      final trainerId = item['trainer_id'] as String?;
      return {
        ...item,
        'user': userId != null ? profilesById[userId] : null,
        'trainer': trainerId != null ? profilesById[trainerId] : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _attachTrainerAndClientProfiles(
    List<Map<String, dynamic>> items,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    return items.map((item) {
      final trainerId = item['trainer_id'] as String?;
      final clientId = item['client_id'] as String?;
      return {
        ...item,
        'trainer': trainerId != null ? profilesById[trainerId] : null,
        'client': clientId != null ? profilesById[clientId] : null,
      };
    }).toList();
  }

  List<Map<String, dynamic>> _attachAdminAndTargetProfiles(
    List<Map<String, dynamic>> items,
    Map<String, Map<String, dynamic>> profilesById,
  ) {
    return items.map((item) {
      final adminId = item['admin_id'] as String?;
      final targetUserId = item['target_user_id'] as String?;
      return {
        ...item,
        'admin': adminId != null ? profilesById[adminId] : null,
        'target_user':
            targetUserId != null ? profilesById[targetUserId] : null,
      };
    }).toList();
  }

  /// بررسی اینکه آیا کاربر ادمین است یا نه
  /// از SimpleProfileService استفاده می‌کند (همان روشی که در منو کار می‌کند)
  Future<bool> isAdmin() async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) {
        return false;
      }

      final profile = await SimpleProfileService.getCurrentProfile();
      if (profile == null) {
        return false;
      }

      final role = profile['role'] as String?;
      return role == 'admin';
    } catch (e) {
      debugPrint('AdminService.isAdmin error: $e');
      return false;
    }
  }

  // ==================== مدیریت کاربران ====================

  /// دریافت لیست تمام کاربران
  Future<List<UserProfile>> getAllUsers({
    String? searchQuery,
    String? roleFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('profiles').select();

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.or(
          'username.ilike.%$searchQuery%,first_name.ilike.%$searchQuery%,last_name.ilike.%$searchQuery%,phone_number.ilike.%$searchQuery%',
        );
      }

      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response
          .cast<Map<String, dynamic>>()
          .map(UserProfile.fromJson)
          .toList();
    } catch (e) {
      debugPrint('AdminService.getAllUsers error: $e');
      return [];
    }
  }

  /// دریافت تعداد کل کاربران
  Future<int> getTotalUsersCount({String? roleFilter}) async {
    try {
      var query = _supabase.from('profiles').select('id');

      if (roleFilter != null && roleFilter.isNotEmpty) {
        query = query.eq('role', roleFilter);
      }

      final response = await query;
      return response.length;
    } catch (e) {
      debugPrint('AdminService.getTotalUsersCount error: $e');
      return 0;
    }
  }

  /// دریافت اطلاعات کامل یک کاربر
  Future<UserProfile?> getUserById(String userId) =>
      ProfileRepository.instance.getUserProfile(userId);

  /// تغییر نقش کاربر
  Future<bool> updateUserRole(String userId, String newRole) async {
    try {
      if (!['athlete', 'trainer', 'admin'].contains(newRole)) {
        throw Exception('نقش نامعتبر است');
      }

      await _supabase
          .from('profiles')
          .update({'role': newRole})
          .eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('AdminService.updateUserRole error: $e');
      return false;
    }
  }

  /// حذف اکانت کاربر
  Future<bool> deleteUserAccount(String userId) async {
    try {
      // حذف از auth.users باعث حذف cascade از profiles می‌شود
      // اما باید از service role key استفاده کنیم
      // در اینجا فقط از client استفاده می‌کنیم، پس باید از Supabase Admin API استفاده شود
      // برای حالا، فقط پروفایل را حذف می‌کنیم
      await _supabase.from('profiles').delete().eq('id', userId);
      return true;
    } catch (e) {
      debugPrint('AdminService.deleteUserAccount error: $e');
      return false;
    }
  }

  /// مسدود کردن کاربر
  Future<bool> banUser(String userId, {String? reason}) async {
    try {
      // می‌توانیم یک جدول banned_users ایجاد کنیم یا از metadata استفاده کنیم
      // برای حالا، یک فیلد is_banned به profiles اضافه می‌کنیم (باید در SQL اضافه شود)
      await _supabase
          .from('profiles')
          .update({'is_banned': true, if (reason != null) 'ban_reason': reason})
          .eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('AdminService.banUser error: $e');
      return false;
    }
  }

  /// رفع مسدودیت کاربر
  Future<bool> unbanUser(String userId) async {
    try {
      await _supabase
          .from('profiles')
          .update({'is_banned': false, 'ban_reason': null})
          .eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('AdminService.unbanUser error: $e');
      return false;
    }
  }

  // ==================== مدیریت بلاک چت عمومی ====================

  /// مسدود کردن کاربر در چت عمومی برای مدت مشخص (مثلاً 3 روز)
  Future<bool> blockUserInPublicChat({
    required String userId,
    required Duration duration,
    required String reason,
  }) async {
    try {
      final admin = _supabase.auth.currentUser;
      if (admin == null) return false;

       // برای رعایت FK، باید id پروفایل ادمین را ذخیره کنیم، نه auth.uid
       final adminProfile = await SimpleProfileService.getCurrentProfile();
       final adminProfileId = adminProfile?['id'] as String?;

      final blockedUntil = DateTime.now().toUtc().add(duration).toIso8601String();

      await _supabase.from('profiles').update({
        'public_chat_blocked_until': blockedUntil,
        'public_chat_block_reason': reason,
        'public_chat_block_created_at': DateTime.now().toUtc().toIso8601String(),
        // اگر پروفایل پیدا نشد، مقدار را null می‌گذاریم تا FK نقض نشود
        'public_chat_block_created_by': adminProfileId,
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('AdminService.blockUserInPublicChat error: $e');
      return false;
    }
  }

  /// رفع بلاک چت عمومی
  Future<bool> unblockUserInPublicChat(String userId) async {
    try {
      await _supabase.from('profiles').update({
        'public_chat_blocked_until': null,
        'public_chat_block_reason': null,
        'public_chat_block_created_at': null,
        'public_chat_block_created_by': null,
      }).eq('id', userId);

      return true;
    } catch (e) {
      debugPrint('AdminService.unblockUserInPublicChat error: $e');
      return false;
    }
  }

  /// دریافت لیست کاربران مسدود در چت عمومی
  Future<List<Map<String, dynamic>>> getPublicChatBlockedUsers() async {
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      final response = await _supabase
          .from('profiles')
          .select(
            'id, username, first_name, last_name, phone_number, role, public_chat_blocked_until, public_chat_block_reason, public_chat_block_created_at, public_chat_block_created_by',
          )
          .gt('public_chat_blocked_until', now)
          .order('public_chat_blocked_until');

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminService.getPublicChatBlockedUsers error: $e');
      return [];
    }
  }

  // ==================== مدیریت چت‌های خصوصی ====================

  /// دریافت تمام مکالمات خصوصی
  Future<List<Map<String, dynamic>>> getAllPrivateConversations({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // ابتدا مکالمات را بدون join بگیریم
      final conversations = await _supabase
          .from('chat_conversations')
          .select()
          .order('updated_at', ascending: false)
          .range(offset, offset + limit - 1);

      final convList = List<Map<String, dynamic>>.from(
        conversations as List,
      );
      final profilesById = await _fetchProfilesByIds(
        convList.expand(
          (conv) => [conv['user1_id'] as String?, conv['user2_id'] as String?],
        ),
        columns: 'id, username, first_name, last_name, avatar_url, role',
      );

      final List<Map<String, dynamic>> result = [];

      for (final conv in convList) {
        final user1Id = conv['user1_id'] as String?;
        final user2Id = conv['user2_id'] as String?;

        result.add({
          ...conv,
          'user1': user1Id != null ? profilesById[user1Id] : null,
          'user2': user2Id != null ? profilesById[user2Id] : null,
        });
      }

      return result;
    } catch (e) {
      debugPrint('AdminService.getAllPrivateConversations error: $e');
      debugPrint('Error details: $e');
      return [];
    }
  }

  /// دریافت پیام‌های یک مکالمه
  Future<List<Map<String, dynamic>>> getConversationMessages(
    String conversationId,
  ) async {
    try {
      final response = await _supabase
          .from('chat_conversations')
          .select('messages, user1_id, user2_id')
          .eq('id', conversationId)
          .maybeSingle();

      if (response == null) return [];

      final messages = (response['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      // دریافت اطلاعات کاربران برای نمایش نام
      final user1Id = response['user1_id'] as String?;
      final user2Id = response['user2_id'] as String?;

      final profilesById = await _fetchProfilesByIds([user1Id, user2Id]);
      final user1Info = user1Id != null ? profilesById[user1Id] : null;
      final user2Info = user2Id != null ? profilesById[user2Id] : null;

      // اضافه کردن اطلاعات کاربر به هر پیام
      final enrichedMessages = messages.map((message) {
        final senderId = message['sender_id'] as String?;
        String? senderName;

        if (senderId == user1Id && user1Info != null) {
          final firstName = user1Info['first_name'] as String?;
          final lastName = user1Info['last_name'] as String?;
          final username = user1Info['username'] as String?;
          if (firstName != null && lastName != null) {
            senderName = '$firstName $lastName';
          } else if (firstName != null) {
            senderName = firstName;
          } else if (username != null) {
            senderName = username;
          }
        } else if (senderId == user2Id && user2Info != null) {
          final firstName = user2Info['first_name'] as String?;
          final lastName = user2Info['last_name'] as String?;
          final username = user2Info['username'] as String?;
          if (firstName != null && lastName != null) {
            senderName = '$firstName $lastName';
          } else if (firstName != null) {
            senderName = firstName;
          } else if (username != null) {
            senderName = username;
          }
        }

        // اگر پیام از ادمین است، نام ادمین را بگیر
        if (message['message_type'] == 'admin_warning' || senderName == null) {
          // بررسی اینکه آیا sender_id یک ادمین است
          // برای حالا، اگر message_type admin_warning است، نام را "ادمین" می‌گذاریم
          if (message['message_type'] == 'admin_warning') {
            senderName = 'ادمین';
          } else {
            senderName = senderName ?? 'کاربر ناشناس';
          }
        }

        return {...message, 'sender_name': senderName};
      }).toList();

      return enrichedMessages;
    } catch (e) {
      debugPrint('AdminService.getConversationMessages error: $e');
      return [];
    }
  }

  /// حذف یک مکالمه خصوصی
  Future<bool> deletePrivateConversation(String conversationId) async {
    try {
      await _supabase
          .from('chat_conversations')
          .delete()
          .eq('id', conversationId);

      return true;
    } catch (e) {
      debugPrint('AdminService.deletePrivateConversation error: $e');
      return false;
    }
  }

  /// ارسال هشدار به یک مکالمه خصوصی
  Future<bool> sendWarningToConversation(
    String conversationId,
    String warningMessage,
  ) async {
    try {
      // دریافت اطلاعات مکالمه
      final conversation = await _supabase
          .from('chat_conversations')
          .select('user1_id, user2_id, messages')
          .eq('id', conversationId)
          .maybeSingle();

      if (conversation == null) return false;

      final currentMessages = (conversation['messages'] as List<dynamic>? ?? [])
          .cast<Map<String, dynamic>>()
          .toList();

      // ایجاد پیام هشدار از طرف ادمین
      final adminUser = _supabase.auth.currentUser;
      if (adminUser == null) return false;

      // دریافت نام ادمین
      String adminName = 'ادمین';
      try {
        final adminProfile =
            await ProfileRepository.instance.fetchProfile(adminUser.id);
        if (adminProfile != null) {
          final firstName = adminProfile['first_name'] as String?;
          final lastName = adminProfile['last_name'] as String?;
          final username = adminProfile['username'] as String?;

          if (firstName != null && lastName != null) {
            adminName = '$firstName $lastName (ادمین)';
          } else if (firstName != null) {
            adminName = '$firstName (ادمین)';
          } else if (username != null) {
            adminName = '$username (ادمین)';
          }
        }
      } catch (e) {
        debugPrint('Error fetching admin profile: $e');
      }

      final now = DateTime.now();
      final timestamp = now.millisecondsSinceEpoch;

      // ایجاد یک پیام هشدار که برای هر دو کاربر قابل مشاهده است
      // این پیام در مکالمه نمایش داده می‌شود و هر دو کاربر آن را می‌بینند
      final warningMessageData = {
        'id': 'admin_warning_${conversationId}_$timestamp',
        'sender_id': adminUser.id,
        'receiver_id': null, // null یعنی برای هر دو کاربر
        'message': '⚠️ هشدار ادمین: $warningMessage',
        'message_type': 'admin_warning',
        'sender_name': adminName,
        'created_at': now.toIso8601String(),
        'updated_at': now.toIso8601String(),
        'is_read': false,
        'is_deleted': false,
      };

      // فقط یک پیام اضافه می‌کنیم (نه دو تا)
      currentMessages.add(warningMessageData);

      // مرتب‌سازی پیام‌ها بر اساس تاریخ
      currentMessages.sort((a, b) {
        try {
          final aTime =
              DateTime.tryParse(a['created_at']?.toString() ?? '') ??
              DateTime(1970);
          final bTime =
              DateTime.tryParse(b['created_at']?.toString() ?? '') ??
              DateTime(1970);
          return aTime.compareTo(bTime);
        } catch (e) {
          return 0;
        }
      });

      // به‌روزرسانی مکالمه
      await _supabase
          .from('chat_conversations')
          .update({
            'messages': currentMessages,
            'last_message': '⚠️ هشدار ادمین: $warningMessage',
            'last_message_at': now.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', conversationId);

      return true;
    } catch (e) {
      debugPrint('AdminService.sendWarningToConversation error: $e');
      return false;
    }
  }

  // ==================== مدیریت چت عمومی ====================

  /// دریافت تمام پیام‌های چت عمومی
  Future<List<Map<String, dynamic>>> getAllPublicChatMessages({
    int limit = 50,
    int offset = 0,
    bool includeDeleted = false,
  }) async {
    try {
      var query = _supabase.from('public_chat_messages').select('''
            *,
            sender:profiles!public_chat_messages_sender_id_fkey(id, username, first_name, last_name, avatar_url, role)
          ''');

      if (!includeDeleted) {
        query = query.eq('is_deleted', false);
      }

      final response = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminService.getAllPublicChatMessages error: $e');
      return [];
    }
  }

  /// حذف پیام از چت عمومی
  Future<bool> deletePublicChatMessage(String messageId) async {
    try {
      await _supabase
          .from('public_chat_messages')
          .update({'is_deleted': true})
          .eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint('AdminService.deletePublicChatMessage error: $e');
      return false;
    }
  }

  /// بازیابی پیام حذف شده از چت عمومی
  Future<bool> restorePublicChatMessage(String messageId) async {
    try {
      await _supabase
          .from('public_chat_messages')
          .update({'is_deleted': false})
          .eq('id', messageId);

      return true;
    } catch (e) {
      debugPrint('AdminService.restorePublicChatMessage error: $e');
      return false;
    }
  }

  // ==================== مدیریت عکس‌ها و فایل‌ها ====================

  /// دریافت لیست تمام عکس‌های آپلود شده
  Future<List<Map<String, dynamic>>> getAllUploadedImages({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final List<Map<String, dynamic>> allImages = [];

      // جستجو در chat_conversations برای عکس‌های چت (از فیلد messages JSONB)
      try {
        final conversations = await _supabase
            .from('chat_conversations')
            .select('messages, user1_id, user2_id')
            .range(offset, offset + limit - 1);

        for (final conv in conversations) {
          final messages = (conv['messages'] as List<dynamic>? ?? [])
              .cast<Map<String, dynamic>>()
              .toList();

          for (final message in messages) {
            final attachmentUrl = message['attachment_url'] as String?;
            final attachmentType = message['attachment_type'] as String?;
            final senderId = message['sender_id'] as String?;

            if (attachmentUrl != null &&
                attachmentType == 'image' &&
                senderId != null) {
              allImages.add({
                'type': 'chat_attachment',
                'url': attachmentUrl,
                'name': message['attachment_name'] as String? ?? 'عکس چت',
                'user_id': senderId,
                'created_at':
                    message['created_at'] as String? ??
                    DateTime.now().toIso8601String(),
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching chat attachments: $e');
        // ادامه می‌دهیم حتی اگر خطا رخ داد
      }

      // جستجو در profiles برای avatar_url
      try {
        final profileAvatars = await _supabase
            .from('profiles')
            .select('id, username, avatar_url, created_at')
            .not('avatar_url', 'is', null)
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1);

        for (final profile in profileAvatars) {
          allImages.add({
            'type': 'avatar',
            'url': profile['avatar_url'],
            'name': 'آواتار ${profile['username']}',
            'user_id': profile['id'],
            'created_at': profile['created_at'],
          });
        }
      } catch (e) {
        debugPrint('Error fetching avatars: $e');
      }

      // جستجو در confidential_user_info برای photo_album
      try {
        final bodyPhotos = await _supabase
            .from('confidential_user_info')
            .select('user_id, photo_album')
            .not('photo_album', 'is', null)
            .range(offset, offset + limit - 1);

        for (final info in bodyPhotos) {
          final photoAlbum = info['photo_album'] as List<dynamic>? ?? [];
          for (final photo in photoAlbum) {
            if (photo is Map<String, dynamic> && photo['url'] != null) {
              allImages.add({
                'type': 'body_photo',
                'url': photo['url'],
                'name': photo['notes'] ?? 'عکس بدنی',
                'user_id': info['user_id'],
                'created_at': photo['taken_at'] ?? info['created_at'],
              });
            }
          }
        }
      } catch (e) {
        debugPrint('Error fetching body photos: $e');
      }

      // مرتب‌سازی بر اساس تاریخ
      allImages.sort((a, b) {
        final aDate =
            DateTime.tryParse(a['created_at']?.toString() ?? '') ??
            DateTime(1970);
        final bDate =
            DateTime.tryParse(b['created_at']?.toString() ?? '') ??
            DateTime(1970);
        return bDate.compareTo(aDate);
      });

      // محدود کردن تعداد نتایج
      if (allImages.length > limit) {
        return allImages.sublist(0, limit);
      }

      return allImages;
    } catch (e) {
      debugPrint('AdminService.getAllUploadedImages error: $e');
      return [];
    }
  }

  // ==================== آمار و گزارشات ====================

  /// دریافت آمار کلی سیستم
  Future<Map<String, dynamic>> getSystemStats() async {
    try {
      final totalUsers = await getTotalUsersCount();
      final totalAthletes = await getTotalUsersCount(roleFilter: 'athlete');
      final totalTrainers = await getTotalUsersCount(roleFilter: 'trainer');
      final totalAdmins = await getTotalUsersCount(roleFilter: 'admin');

      // تعداد مکالمات
      final conversationsCount = await _supabase
          .from('chat_conversations')
          .select('id');
      final totalConversations = conversationsCount.length;

      // تعداد پیام‌های چت عمومی
      final publicMessagesCount = await _supabase
          .from('public_chat_messages')
          .select('id')
          .eq('is_deleted', false);
      final totalPublicMessages = publicMessagesCount.length;

      // کاربران جدید امروز
      final today = DateTime.now();
      final startOfDay = DateTime(today.year, today.month, today.day);
      final newUsersToday = await _supabase
          .from('profiles')
          .select('id')
          .gte('created_at', startOfDay.toIso8601String());
      final newUsersCount = newUsersToday.length;

      // تعداد برنامه‌های تمرینی
      final workoutProgramsCount = await _supabase
          .from('workout_programs')
          .select('id')
          .eq('is_deleted', false);
      final totalWorkoutPrograms = workoutProgramsCount.length;

      // تعداد برنامه‌های رژیمی
      final mealPlansCount = await _supabase
          .from('meal_plans')
          .select('id')
          .eq('is_deleted', false);
      final totalMealPlans = mealPlansCount.length;

      // تعداد روابط مربی-شاگرد
      final trainerClientsCount = await _supabase
          .from('trainer_clients')
          .select('id');
      final totalTrainerClients = trainerClientsCount.length;

      // تعداد تراکنش‌های پرداخت
      final transactionsCount = await _supabase
          .from('payment_transactions')
          .select('id');
      final totalTransactions = transactionsCount.length;

      // تعداد کیف پول‌ها
      final walletsCount = await _supabase.from('wallets').select('id');
      final totalWallets = walletsCount.length;

      // تعداد کدهای تخفیف
      final discountCodesCount = await _supabase
          .from('discount_codes')
          .select('id');
      final totalDiscountCodes = discountCodesCount.length;

      // گزارش مالی
      final financialReport = await getFinancialReport();

      return {
        'total_users': totalUsers,
        'total_athletes': totalAthletes,
        'total_trainers': totalTrainers,
        'total_admins': totalAdmins,
        'total_conversations': totalConversations,
        'total_public_messages': totalPublicMessages,
        'new_users_today': newUsersCount,
        'total_workout_programs': totalWorkoutPrograms,
        'total_meal_plans': totalMealPlans,
        'total_trainer_clients': totalTrainerClients,
        'total_transactions': totalTransactions,
        'total_wallets': totalWallets,
        'total_discount_codes': totalDiscountCodes,
        'total_revenue': financialReport['total_revenue'] ?? 0,
        'net_revenue': financialReport['net_revenue'] ?? 0,
      };
    } catch (e) {
      debugPrint('AdminService.getSystemStats error: $e');
      return {};
    }
  }

  // ==================== مدیریت برنامه‌های تمرینی و رژیمی ====================

  /// دریافت تمام برنامه‌های تمرینی
  Future<List<Map<String, dynamic>>> getAllWorkoutPrograms({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final programs = List<Map<String, dynamic>>.from(
        await _supabase
            .from('workout_programs')
            .select()
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        programs.map((program) => program['user_id'] as String?),
      );

      return _attachProfileFields(
        programs,
        profilesById: profilesById,
        idField: 'user_id',
        profileField: 'user',
      );
    } catch (e) {
      debugPrint('AdminService.getAllWorkoutPrograms error: $e');
      return [];
    }
  }

  /// دریافت تمام برنامه‌های رژیمی
  Future<List<Map<String, dynamic>>> getAllMealPlans({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final plans = List<Map<String, dynamic>>.from(
        await _supabase
            .from('meal_plans')
            .select()
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        plans.expand(
          (plan) => [
            plan['user_id'] as String?,
            plan['trainer_id'] as String?,
          ],
        ),
      );

      return _attachUserAndTrainerProfiles(plans, profilesById);
    } catch (e) {
      debugPrint('AdminService.getAllMealPlans error: $e');
      return [];
    }
  }

  /// حذف برنامه تمرینی
  Future<bool> deleteWorkoutProgram(String programId) async {
    try {
      await _supabase
          .from('workout_programs')
          .update({'is_deleted': true})
          .eq('id', programId);

      return true;
    } catch (e) {
      debugPrint('AdminService.deleteWorkoutProgram error: $e');
      return false;
    }
  }

  /// حذف برنامه رژیمی
  Future<bool> deleteMealPlan(String mealPlanId) async {
    try {
      await _supabase
          .from('meal_plans')
          .update({'is_deleted': true})
          .eq('id', mealPlanId);

      return true;
    } catch (e) {
      debugPrint('AdminService.deleteMealPlan error: $e');
      return false;
    }
  }

  // ==================== مدیریت روابط مربی-شاگرد ====================

  /// دریافت تمام روابط مربی-شاگرد
  Future<List<Map<String, dynamic>>> getAllTrainerClients({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('trainer_clients').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final relationships = List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        relationships.expand(
          (relationship) => [
            relationship['trainer_id'] as String?,
            relationship['client_id'] as String?,
          ],
        ),
      );

      return _attachTrainerAndClientProfiles(relationships, profilesById);
    } catch (e) {
      debugPrint('AdminService.getAllTrainerClients error: $e');
      return [];
    }
  }

  /// تغییر وضعیت رابطه مربی-شاگرد
  Future<bool> updateTrainerClientStatus(
    String relationshipId,
    String newStatus,
  ) async {
    try {
      await _supabase
          .from('trainer_clients')
          .update({'status': newStatus})
          .eq('id', relationshipId);

      return true;
    } catch (e) {
      debugPrint('AdminService.updateTrainerClientStatus error: $e');
      return false;
    }
  }

  /// حذف رابطه مربی-شاگرد
  Future<bool> deleteTrainerClient(String relationshipId) async {
    try {
      await _supabase.from('trainer_clients').delete().eq('id', relationshipId);

      return true;
    } catch (e) {
      debugPrint('AdminService.deleteTrainerClient error: $e');
      return false;
    }
  }

  // ==================== مدیریت پرداخت‌ها ====================

  /// دریافت تمام تراکنش‌های پرداخت
  Future<List<Map<String, dynamic>>> getAllPaymentTransactions({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('payment_transactions').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final transactions = List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        transactions.map((transaction) => transaction['user_id'] as String?),
      );

      return _attachProfileFields(
        transactions,
        profilesById: profilesById,
        idField: 'user_id',
        profileField: 'user',
      );
    } catch (e) {
      debugPrint('AdminService.getAllPaymentTransactions error: $e');
      return [];
    }
  }

  /// بازپرداخت تراکنش
  Future<bool> refundTransaction(String transactionId) async {
    try {
      // دریافت اطلاعات تراکنش
      final transaction = await _supabase
          .from('payment_transactions')
          .select('user_id, amount, status')
          .eq('id', transactionId)
          .maybeSingle();

      if (transaction == null || transaction['status'] != 'completed') {
        return false;
      }

      // ایجاد تراکنش بازپرداخت
      await _supabase.from('payment_transactions').insert({
        'user_id': transaction['user_id'],
        'amount': transaction['amount'],
        'type': 'refund',
        'status': 'completed',
        'description': 'بازپرداخت تراکنش $transactionId',
        'reference_id': transactionId,
      });

      // به‌روزرسانی وضعیت تراکنش اصلی
      await _supabase
          .from('payment_transactions')
          .update({'status': 'refunded'})
          .eq('id', transactionId);

      return true;
    } catch (e) {
      debugPrint('AdminService.refundTransaction error: $e');
      return false;
    }
  }

  // ==================== مدیریت کیف پول ====================

  /// دریافت تمام کیف پول‌ها
  Future<List<Map<String, dynamic>>> getAllWallets({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final wallets = List<Map<String, dynamic>>.from(
        await _supabase
            .from('wallets')
            .select()
            .order('balance', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        wallets.map((wallet) => wallet['user_id'] as String?),
      );

      return _attachProfileFields(
        wallets,
        profilesById: profilesById,
        idField: 'user_id',
        profileField: 'user',
      );
    } catch (e) {
      debugPrint('AdminService.getAllWallets error: $e');
      return [];
    }
  }

  /// شارژ دستی کیف پول (فقط موجودی را تغییر می‌دهد، total_charged را تغییر نمی‌دهد)
  Future<bool> chargeWalletManually(
    String userId,
    int amount,
    String description,
  ) async {
    try {
      // دریافت کیف پول کاربر
      final wallet = await _supabase
          .from('wallets')
          .select('id, balance, available_balance, blocked_balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (wallet == null) {
        // ایجاد کیف پول اگر وجود ندارد
        final newWallet = await _supabase
            .from('wallets')
            .insert({
              'user_id': userId,
              'balance': amount,
              'available_balance': amount,
              'blocked_balance': 0,
              'total_charged':
                  0, // شارژ دستی ادمین در total_charged حساب نمی‌شود
              'last_transaction_date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        final newWalletId = newWallet['id'] as String;

        // ثبت تراکنش برای کیف پول جدید
        final transactionId = PaymentConstants.generateTransactionId();
        await _supabase.from('wallet_transactions').insert({
          'id': transactionId,
          'wallet_id': newWalletId,
          'user_id': userId,
          'type': 'charge',
          'amount': amount,
          'balance_before': 0,
          'balance_after': amount,
          'description': description,
          'reference_id':
              'admin_manual_charge_${DateTime.now().millisecondsSinceEpoch}',
        });

        // ثبت عملیات ادمین
        final adminUser = _supabase.auth.currentUser;
        if (adminUser != null) {
          await _supabase.from('admin_wallet_actions').insert({
            'admin_id': adminUser.id,
            'target_user_id': userId,
            'action_type': 'charge',
            'amount': amount,
            'balance_before': 0,
            'balance_after': amount,
            'available_balance_before': 0,
            'available_balance_after': amount,
            'description': description,
            'wallet_id': newWalletId,
            'transaction_id': transactionId,
          });
        }
      } else {
        // به‌روزرسانی موجودی (بدون تغییر total_charged)
        final walletId = wallet['id'] as String;
        final balanceBefore = wallet['balance'] as int? ?? 0;
        final availableBalanceBefore = wallet['available_balance'] as int? ?? 0;
        final newBalance = balanceBefore + amount;
        final newAvailableBalance = availableBalanceBefore + amount;

        await _supabase
            .from('wallets')
            .update({
              'balance': newBalance,
              'available_balance': newAvailableBalance,
              'last_transaction_date': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              // total_charged و total_spent تغییر نمی‌کنند
            })
            .eq('id', walletId);

        // ثبت تراکنش
        final transactionId = PaymentConstants.generateTransactionId();
        await _supabase.from('wallet_transactions').insert({
          'id': transactionId,
          'wallet_id': walletId,
          'user_id': userId,
          'type': 'charge',
          'amount': amount,
          'balance_before': balanceBefore,
          'balance_after': newBalance,
          'description': description,
          'reference_id':
              'admin_manual_charge_${DateTime.now().millisecondsSinceEpoch}',
        });

        // ثبت عملیات ادمین
        final adminUser = _supabase.auth.currentUser;
        if (adminUser != null) {
          await _supabase.from('admin_wallet_actions').insert({
            'admin_id': adminUser.id,
            'target_user_id': userId,
            'action_type': 'charge',
            'amount': amount,
            'balance_before': balanceBefore,
            'balance_after': newBalance,
            'available_balance_before': availableBalanceBefore,
            'available_balance_after': newAvailableBalance,
            'description': description,
            'wallet_id': walletId,
            'transaction_id': transactionId,
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('AdminService.chargeWalletManually error: $e');
      return false;
    }
  }

  /// اصلاح مستقیم موجودی کیف پول (مثلاً از 500 به 300)
  Future<bool> updateWalletBalanceDirectly(
    String userId,
    int newBalance,
    String description,
  ) async {
    try {
      // دریافت کیف پول کاربر
      final wallet = await _supabase
          .from('wallets')
          .select('id, balance, available_balance, blocked_balance')
          .eq('user_id', userId)
          .maybeSingle();

      if (newBalance < 0) {
        throw Exception('موجودی نمی‌تواند منفی شود');
      }

      if (wallet == null) {
        // ایجاد کیف پول اگر وجود ندارد
        final newWallet = await _supabase
            .from('wallets')
            .insert({
              'user_id': userId,
              'balance': newBalance,
              'available_balance': newBalance,
              'blocked_balance': 0,
              'total_charged': 0,
              'last_transaction_date': DateTime.now().toIso8601String(),
            })
            .select()
            .single();

        final newWalletId = newWallet['id'] as String;

        // ثبت تراکنش
        final transactionId = PaymentConstants.generateTransactionId();
        await _supabase.from('wallet_transactions').insert({
          'id': transactionId,
          'wallet_id': newWalletId,
          'user_id': userId,
          'type':
              'bonus', // استفاده از 'bonus' به جای 'adjustment' چون در constraint وجود دارد
          'amount': newBalance,
          'balance_before': 0,
          'balance_after': newBalance,
          'description': description,
          'reference_id':
              'admin_manual_adjustment_${DateTime.now().millisecondsSinceEpoch}',
        });

        // ثبت عملیات ادمین
        final adminUser = _supabase.auth.currentUser;
        if (adminUser != null) {
          await _supabase.from('admin_wallet_actions').insert({
            'admin_id': adminUser.id,
            'target_user_id': userId,
            'action_type': 'adjustment',
            'amount': newBalance,
            'balance_before': 0,
            'balance_after': newBalance,
            'available_balance_before': 0,
            'available_balance_after': newBalance,
            'description': description,
            'wallet_id': newWalletId,
            'transaction_id': transactionId,
          });
        }
      } else {
        // به‌روزرسانی موجودی (بدون تغییر total_charged و total_spent)
        final walletId = wallet['id'] as String;
        final balanceBefore = wallet['balance'] as int? ?? 0;
        final blockedBalance = wallet['blocked_balance'] as int? ?? 0;
        final difference = newBalance - balanceBefore;

        // محاسبه available_balance جدید
        // balance = available_balance + blocked_balance
        // پس: available_balance = balance - blocked_balance
        final newAvailableBalance = newBalance - blockedBalance;

        // بررسی اینکه available_balance منفی نشود
        if (newAvailableBalance < 0) {
          throw Exception(
            'موجودی قابل استفاده نمی‌تواند منفی شود. موجودی مسدود شده: ${PaymentConstants.formatAmount(blockedBalance)}',
          );
        }

        await _supabase
            .from('wallets')
            .update({
              'balance': newBalance,
              'available_balance': newAvailableBalance,
              'last_transaction_date': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
              // total_charged و total_spent تغییر نمی‌کنند
            })
            .eq('id', walletId);

        // ثبت تراکنش
        final transactionId = PaymentConstants.generateTransactionId();
        await _supabase.from('wallet_transactions').insert({
          'id': transactionId,
          'wallet_id': walletId,
          'user_id': userId,
          'type':
              'bonus', // استفاده از 'bonus' به جای 'adjustment' چون در constraint وجود دارد
          'amount': difference.abs(),
          'balance_before': balanceBefore,
          'balance_after': newBalance,
          'description': description,
          'reference_id':
              'admin_manual_adjustment_${DateTime.now().millisecondsSinceEpoch}',
        });

        // ثبت عملیات ادمین
        final adminUser = _supabase.auth.currentUser;
        if (adminUser != null) {
          final availableBalanceBefore =
              wallet['available_balance'] as int? ?? 0;
          await _supabase.from('admin_wallet_actions').insert({
            'admin_id': adminUser.id,
            'target_user_id': userId,
            'action_type': 'adjustment',
            'amount': difference.abs(),
            'balance_before': balanceBefore,
            'balance_after': newBalance,
            'available_balance_before': availableBalanceBefore,
            'available_balance_after': newAvailableBalance,
            'description': description,
            'wallet_id': walletId,
            'transaction_id': transactionId,
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint('AdminService.updateWalletBalanceDirectly error: $e');
      return false;
    }
  }

  /// دریافت تاریخچه تراکنش‌های کیف پول
  Future<List<Map<String, dynamic>>> getWalletTransactions(
    String walletId, {
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminService.getWalletTransactions error: $e');
      return [];
    }
  }

  // ==================== تاریخچه عملیات ادمین روی کیف پول ====================

  /// دریافت تاریخچه تمام عملیات ادمین روی کیف پول‌ها
  Future<List<Map<String, dynamic>>> getAdminWalletActions({
    String? adminId,
    String? targetUserId,
    String? actionType,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      // بدون join - اطلاعات کاربران را جداگانه می‌گیریم
      var query = _supabase.from('admin_wallet_actions').select();

      if (adminId != null && adminId.isNotEmpty) {
        query = query.eq('admin_id', adminId);
      }

      if (targetUserId != null && targetUserId.isNotEmpty) {
        query = query.eq('target_user_id', targetUserId);
      }

      if (actionType != null && actionType.isNotEmpty) {
        query = query.eq('action_type', actionType);
      }

      final response = List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        response.expand(
          (action) => [
            action['admin_id'] as String?,
            action['target_user_id'] as String?,
          ],
        ),
        columns: 'id, username, first_name, last_name, avatar_url',
      );

      return _attachAdminAndTargetProfiles(response, profilesById);
    } catch (e) {
      debugPrint('AdminService.getAdminWalletActions error: $e');
      return [];
    }
  }

  // ==================== مدیریت کدهای تخفیف ====================

  /// دریافت تمام کدهای تخفیف
  Future<List<Map<String, dynamic>>> getAllDiscountCodes({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _supabase
          .from('discount_codes')
          .select()
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('AdminService.getAllDiscountCodes error: $e');
      return [];
    }
  }

  /// ایجاد کد تخفیف جدید
  Future<bool> createDiscountCode(Map<String, dynamic> codeData) async {
    try {
      final adminUser = _supabase.auth.currentUser;
      if (adminUser == null) return false;

      await _supabase.from('discount_codes').insert({
        ...codeData,
        'created_by': adminUser.id,
      });

      return true;
    } catch (e) {
      debugPrint('AdminService.createDiscountCode error: $e');
      return false;
    }
  }

  /// به‌روزرسانی کد تخفیف
  Future<bool> updateDiscountCode(
    String codeId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _supabase.from('discount_codes').update(updates).eq('id', codeId);

      return true;
    } catch (e) {
      debugPrint('AdminService.updateDiscountCode error: $e');
      return false;
    }
  }

  /// حذف کد تخفیف
  Future<bool> deleteDiscountCode(String codeId) async {
    try {
      await _supabase.from('discount_codes').delete().eq('id', codeId);
      return true;
    } catch (e) {
      debugPrint('AdminService.deleteDiscountCode error: $e');
      return false;
    }
  }

  // ==================== مدیریت اشتراک‌ها ====================

  /// دریافت تمام اشتراک‌ها
  Future<List<Map<String, dynamic>>> getAllSubscriptions({
    String? statusFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('subscriptions').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }

      final subscriptions = List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        subscriptions.map((subscription) => subscription['user_id'] as String?),
      );

      return _attachProfileFields(
        subscriptions,
        profilesById: profilesById,
        idField: 'user_id',
        profileField: 'user',
      );
    } catch (e) {
      debugPrint('AdminService.getAllSubscriptions error: $e');
      return [];
    }
  }

  /// تمدید اشتراک
  Future<bool> extendSubscription(
    String subscriptionId,
    int additionalDays,
  ) async {
    try {
      final subscription = await _supabase
          .from('subscriptions')
          .select('end_date')
          .eq('id', subscriptionId)
          .maybeSingle();

      if (subscription == null) return false;

      final currentEndDate = DateTime.parse(subscription['end_date'] as String);
      final newEndDate = currentEndDate.add(Duration(days: additionalDays));

      await _supabase
          .from('subscriptions')
          .update({
            'end_date': newEndDate.toIso8601String(),
            'status': 'active',
          })
          .eq('id', subscriptionId);

      return true;
    } catch (e) {
      debugPrint('AdminService.extendSubscription error: $e');
      return false;
    }
  }

  /// لغو اشتراک
  Future<bool> cancelSubscription(String subscriptionId) async {
    try {
      await _supabase
          .from('subscriptions')
          .update({'status': 'cancelled'})
          .eq('id', subscriptionId);

      return true;
    } catch (e) {
      debugPrint('AdminService.cancelSubscription error: $e');
      return false;
    }
  }

  // ==================== ارسال نوتیفیکیشن دسته‌ای ====================

  /// ارسال نوتیفیکیشن به تمام کاربران
  Future<bool> sendBroadcastNotification({
    required String title,
    required String body,
    String? targetRole,
    Map<String, dynamic>? data,
  }) async {
    try {
      // این باید از طریق Supabase Edge Function یا Firebase Cloud Messaging انجام شود
      // برای حالا فقط یک لاگ می‌کنیم
      debugPrint('AdminService.sendBroadcastNotification: $title - $body');
      debugPrint('Target role: $targetRole');
      debugPrint('Data: $data');

      // TODO: پیاده‌سازی ارسال واقعی نوتیفیکیشن
      return true;
    } catch (e) {
      debugPrint('AdminService.sendBroadcastNotification error: $e');
      return false;
    }
  }

  // ==================== گزارش‌های مالی ====================

  /// دریافت گزارش مالی
  Future<Map<String, dynamic>> getFinancialReport({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('payment_transactions')
          .select('amount, type, status, created_at');

      if (startDate != null) {
        query = query.gte('created_at', startDate.toIso8601String());
      }
      if (endDate != null) {
        query = query.lte('created_at', endDate.toIso8601String());
      }

      final transactions = await query.eq('status', 'completed');

      int totalRevenue = 0;
      int totalRefunds = 0;
      int transactionCount = 0;

      for (final transaction in transactions) {
        final amount = transaction['amount'] as int? ?? 0;
        final type = transaction['type'] as String? ?? '';

        if (type == 'refund') {
          totalRefunds += amount;
        } else {
          totalRevenue += amount;
        }
        transactionCount++;
      }

      return {
        'total_revenue': totalRevenue,
        'total_refunds': totalRefunds,
        'net_revenue': totalRevenue - totalRefunds,
        'transaction_count': transactionCount,
        'average_transaction': transactionCount > 0
            ? totalRevenue ~/ transactionCount
            : 0,
      };
    } catch (e) {
      debugPrint('AdminService.getFinancialReport error: $e');
      return {};
    }
  }

  // ==================== مدیریت مدارک مربیان ====================

  /// دریافت تمام مدارک (با فیلتر وضعیت)
  Future<List<Map<String, dynamic>>> getAllCertificates({
    String? statusFilter,
    String? typeFilter,
    String? trainerIdFilter,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      var query = _supabase.from('certificates').select();

      if (statusFilter != null && statusFilter.isNotEmpty) {
        query = query.eq('status', statusFilter);
      }
      if (typeFilter != null && typeFilter.isNotEmpty) {
        query = query.eq('type', typeFilter);
      }
      if (trainerIdFilter != null && trainerIdFilter.isNotEmpty) {
        query = query.eq('trainer_id', trainerIdFilter);
      }

      final response = List<Map<String, dynamic>>.from(
        await query
            .order('created_at', ascending: false)
            .range(offset, offset + limit - 1) as List,
      );

      final profilesById = await _fetchProfilesByIds(
        response.map((cert) => cert['trainer_id'] as String?),
        columns: 'id, username, first_name, last_name, avatar_url',
      );

      return _attachProfileFields(
        response,
        profilesById: profilesById,
        idField: 'trainer_id',
        profileField: 'trainer',
      );
    } catch (e) {
      debugPrint('AdminService.getAllCertificates error: $e');
      return [];
    }
  }

  /// دریافت آمار مدارک
  Future<Map<String, dynamic>> getCertificateStats() async {
    try {
      final total = await _supabase.from('certificates').select('id');
      final totalCount = total.length;

      final pending = await _supabase
          .from('certificates')
          .select('id')
          .eq('status', 'pending');
      final pendingCount = pending.length;

      final approved = await _supabase
          .from('certificates')
          .select('id')
          .eq('status', 'approved');
      final approvedCount = approved.length;

      final rejected = await _supabase
          .from('certificates')
          .select('id')
          .eq('status', 'rejected');
      final rejectedCount = rejected.length;

      return {
        'total': totalCount,
        'pending': pendingCount,
        'approved': approvedCount,
        'rejected': rejectedCount,
      };
    } catch (e) {
      debugPrint('AdminService.getCertificateStats error: $e');
      return {'total': 0, 'pending': 0, 'approved': 0, 'rejected': 0};
    }
  }

  /// تایید مدرک
  Future<bool> approveCertificate(String certificateId) async {
    try {
      final adminUser = _supabase.auth.currentUser;
      if (adminUser == null) return false;

      await _supabase
          .from('certificates')
          .update({
            'status': 'approved',
            'approved_by': adminUser.id,
            'approved_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificateId);

      return true;
    } catch (e) {
      debugPrint('AdminService.approveCertificate error: $e');
      return false;
    }
  }

  /// رد مدرک
  Future<bool> rejectCertificate(
    String certificateId,
    String rejectionReason,
  ) async {
    try {
      final adminUser = _supabase.auth.currentUser;
      if (adminUser == null) return false;

      await _supabase
          .from('certificates')
          .update({
            'status': 'rejected',
            'rejection_reason': rejectionReason,
            'approved_by': adminUser.id,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', certificateId);

      return true;
    } catch (e) {
      debugPrint('AdminService.rejectCertificate error: $e');
      return false;
    }
  }

  /// حذف مدرک
  Future<bool> deleteCertificate(String certificateId) async {
    try {
      await _supabase.from('certificates').delete().eq('id', certificateId);
      return true;
    } catch (e) {
      debugPrint('AdminService.deleteCertificate error: $e');
      return false;
    }
  }
}
