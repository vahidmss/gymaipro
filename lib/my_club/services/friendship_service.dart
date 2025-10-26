import 'package:gymaipro/models/friendship_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendshipService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  // =============================================
  // جستجوی کاربران
  // =============================================

  /// جستجوی کاربران بر اساس نام کاربری
  static Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('id, username, first_name, last_name, avatar_url, is_online')
          .ilike('username', '%$query%')
          .neq('id', _supabase.auth.currentUser?.id ?? '')
          .limit(20);

      return (response as List<dynamic>)
          .map((user) => UserProfile.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('خطا در جستجوی کاربران: $e');
    }
  }

  /// جستجوی کاربران پیشنهادی (غیر دوست و غیر بلاک)
  static Future<List<UserProfile>> getSuggestedUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      // دریافت کاربرانی که دوست نیستند و بلاک نشده‌اند
      final response = await _supabase.rpc<List<dynamic>>(
        'get_suggested_users',
        params: {'current_user_id': currentUserId, 'limit_count': 10},
      );

      return response
          .map((user) => UserProfile.fromJson(user as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت پیشنهادات: $e');
    }
  }

  // =============================================
  // مدیریت درخواست‌های دوستی
  // =============================================

  /// ارسال درخواست دوستی
  static Future<void> sendFriendRequest(
    String requestedUserId, {
    String? message,
  }) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      // بررسی اینکه قبلاً درخواست ارسال نشده باشد
      final existingRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', currentUserId)
          .eq('requested_id', requestedUserId)
          .maybeSingle();

      if (existingRequest != null) {
        if (existingRequest['status'] == 'pending') {
          throw Exception('درخواست دوستی قبلاً ارسال شده است');
        } else if (existingRequest['status'] == 'accepted') {
          throw Exception('شما قبلاً با این کاربر دوست هستید');
        }
      }

      await _supabase.from('friendship_requests').insert({
        'requester_id': currentUserId,
        'requested_id': requestedUserId,
        'message': message,
        'status': 'pending',
      });
    } catch (e) {
      throw Exception('خطا در ارسال درخواست دوستی: $e');
    }
  }

  /// دریافت درخواست‌های دوستی دریافتی
  static Future<List<FriendshipRequest>> getReceivedRequests() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('friendship_requests_with_users')
          .select()
          .eq('requested_id', currentUserId)
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (request) =>
                FriendshipRequest.fromJson(request as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت درخواست‌ها: $e');
    }
  }

  /// دریافت درخواست‌های دوستی ارسالی
  static Future<List<FriendshipRequest>> getSentRequests() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('friendship_requests_with_users')
          .select()
          .eq('requester_id', currentUserId)
          .inFilter('status', ['pending', 'rejected'])
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (request) =>
                FriendshipRequest.fromJson(request as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت درخواست‌های ارسالی: $e');
    }
  }

  /// تایید درخواست دوستی
  static Future<void> acceptFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('خطا در تایید درخواست دوستی: $e');
    }
  }

  /// رد درخواست دوستی
  static Future<void> rejectFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .update({'status': 'rejected'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('خطا در رد درخواست دوستی: $e');
    }
  }

  /// لغو درخواست دوستی
  static Future<void> cancelFriendRequest(String requestId) async {
    try {
      await _supabase
          .from('friendship_requests')
          .update({'status': 'cancelled'})
          .eq('id', requestId);
    } catch (e) {
      throw Exception('خطا در لغو درخواست دوستی: $e');
    }
  }

  // =============================================
  // مدیریت دوستان
  // =============================================

  /// دریافت لیست دوستان
  static Future<List<UserProfile>> getFriends() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('user_friends_with_info')
          .select()
          .eq('user_id', currentUserId)
          .order('created_at', ascending: false);

      return (response as List)
          .map(
            (friend) => UserProfile.fromJson({
              'id': friend['friend_id'],
              'username': friend['friend_username'],
              'first_name': friend['friend_full_name']?.split(' ').first ?? '',
              'last_name':
                  friend['friend_full_name']?.split(' ').skip(1).join(' ') ??
                  '',
              'avatar_url': friend['friend_avatar'],
              'is_online': friend['friend_is_online'],
            }),
          )
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت لیست دوستان: $e');
    }
  }

  /// حذف دوست
  static Future<void> removeFriend(String friendId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      await _supabase
          .from('user_friends')
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendId);
    } catch (e) {
      throw Exception('خطا در حذف دوست: $e');
    }
  }

  /// بررسی وضعیت دوستی
  static Future<FriendshipStatus> getFriendshipStatus(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      // بررسی دوستی
      final friendship = await _supabase
          .from('user_friends')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('friend_id', userId)
          .maybeSingle();

      if (friendship != null) {
        return FriendshipStatus.friends;
      }

      // بررسی درخواست ارسالی
      final sentRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', currentUserId)
          .eq('requested_id', userId)
          .maybeSingle();

      if (sentRequest != null) {
        switch (sentRequest['status']) {
          case 'pending':
            return FriendshipStatus.requestSent;
          case 'rejected':
            return FriendshipStatus.requestRejected;
          default:
            return FriendshipStatus.none;
        }
      }

      // بررسی درخواست دریافتی
      final receivedRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', userId)
          .eq('requested_id', currentUserId)
          .maybeSingle();

      if (receivedRequest != null) {
        switch (receivedRequest['status']) {
          case 'pending':
            return FriendshipStatus.requestReceived;
          default:
            return FriendshipStatus.none;
        }
      }

      return FriendshipStatus.none;
    } catch (e) {
      throw Exception('خطا در بررسی وضعیت دوستی: $e');
    }
  }

  // =============================================
  // مدیریت بلاک کردن
  // =============================================

  /// بلاک کردن کاربر
  static Future<void> blockUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      // حذف دوستی اگر وجود دارد
      await _supabase
          .from('user_friends')
          .delete()
          .or(
            '(user_id.eq.$currentUserId,friend_id.eq.$userId),(user_id.eq.$userId,friend_id.eq.$currentUserId)',
          );

      // لغو درخواست‌های دوستی
      await _supabase
          .from('friendship_requests')
          .update({'status': 'cancelled'})
          .or(
            '(requester_id.eq.$currentUserId,requested_id.eq.$userId),(requester_id.eq.$userId,requested_id.eq.$currentUserId)',
          );

      // اضافه کردن به لیست بلاک
      await _supabase.from('user_blocks').insert({
        'blocker_id': currentUserId,
        'blocked_id': userId,
      });
    } catch (e) {
      throw Exception('خطا در بلاک کردن کاربر: $e');
    }
  }

  /// آنبلاک کردن کاربر
  static Future<void> unblockUser(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      await _supabase
          .from('user_blocks')
          .delete()
          .eq('blocker_id', currentUserId)
          .eq('blocked_id', userId);
    } catch (e) {
      throw Exception('خطا در آنبلاک کردن کاربر: $e');
    }
  }

  /// دریافت لیست کاربران بلاک شده
  static Future<List<UserProfile>> getBlockedUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      final response = await _supabase
          .from('user_blocks')
          .select(
            'blocked_id, profiles!user_blocks_blocked_id_fkey(id, username, first_name, last_name, avatar_url)',
          )
          .eq('blocker_id', currentUserId);

      return (response as List<dynamic>)
          .map(
            (block) =>
                UserProfile.fromJson(block['profiles'] as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      throw Exception('خطا در دریافت لیست کاربران بلاک شده: $e');
    }
  }

  // =============================================
  // آمار و اطلاعات
  // =============================================

  /// دریافت آمار دوستی
  static Future<FriendshipStats> getFriendshipStats() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      // تعداد دوستان
      final friendsResponse = await _supabase
          .from('user_friends')
          .select('id')
          .eq('user_id', currentUserId);

      // تعداد درخواست‌های دریافتی
      final receivedRequestsResponse = await _supabase
          .from('friendship_requests')
          .select('id')
          .eq('requested_id', currentUserId)
          .eq('status', 'pending');

      // تعداد درخواست‌های ارسالی
      final sentRequestsResponse = await _supabase
          .from('friendship_requests')
          .select('id')
          .eq('requester_id', currentUserId)
          .eq('status', 'pending');

      return FriendshipStats(
        friendsCount: friendsResponse.length,
        receivedRequestsCount: receivedRequestsResponse.length,
        sentRequestsCount: sentRequestsResponse.length,
      );
    } catch (e) {
      throw Exception('خطا در دریافت آمار دوستی: $e');
    }
  }

  // =============================================
  // Real-time Updates
  // =============================================

  /// گوش دادن به تغییرات درخواست‌های دوستی
  static Stream<List<FriendshipRequest>> watchReceivedRequests() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('کاربر وارد نشده است');

    return _supabase
        .from('friendship_requests_with_users')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .where(
                (request) =>
                    request['requested_id'] == currentUserId &&
                    request['status'] == 'pending',
              )
              .map(FriendshipRequest.fromJson)
              .toList(),
        );
  }

  /// گوش دادن به تغییرات دوستان
  static Stream<List<UserProfile>> watchFriends() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('کاربر وارد نشده است');

    return _supabase
        .from('user_friends_with_info')
        .stream(primaryKey: ['id'])
        .map(
          (data) => data
              .where((friend) => friend['user_id'] == currentUserId)
              .map(
                (friend) => UserProfile.fromJson({
                  'id': friend['friend_id'],
                  'username': friend['friend_username'],
                  'first_name':
                      friend['friend_full_name']?.split(' ').first ?? '',
                  'last_name':
                      friend['friend_full_name']
                          ?.split(' ')
                          .skip(1)
                          .join(' ') ??
                      '',
                  'avatar_url': friend['friend_avatar'],
                  'is_online': friend['friend_is_online'],
                }),
              )
              .toList(),
        );
  }
}
