import 'dart:async';


import 'package:flutter/foundation.dart';
import 'package:gymaipro/models/friendship_models.dart';
import 'package:gymaipro/my_club/services/friendship_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FriendshipService {
  static final SupabaseClient _supabase = Supabase.instance.client;

  /// تبدیل profile id به auth.users id (برای جداول دوستی).
  static Future<String> resolveAuthUserId(String profileOrAuthId) async {
    if (profileOrAuthId.isEmpty) return profileOrAuthId;
    try {
      final byAuth = await _supabase
          .from('profiles')
          .select('auth_user_id')
          .eq('auth_user_id', profileOrAuthId)
          .maybeSingle();
      if (byAuth != null) return profileOrAuthId;

      final row = await _supabase
          .from('profiles')
          .select('auth_user_id, id')
          .eq('id', profileOrAuthId)
          .maybeSingle();
      if (row == null) return profileOrAuthId;
      final authId = (row['auth_user_id'] as String?)?.trim();
      if (authId != null && authId.isNotEmpty) return authId;
      return (row['id'] as String?) ?? profileOrAuthId;
    } catch (_) {
      return profileOrAuthId;
    }
  }

  static Future<bool> _isBlockedBetween(String userA, String userB) async {
    final blocked = await _supabase
        .from('user_blocks')
        .select('id')
        .or(
          'and(blocker_id.eq.$userA,blocked_id.eq.$userB),'
          'and(blocker_id.eq.$userB,blocked_id.eq.$userA)',
        )
        .maybeSingle();
    return blocked != null;
  }

  // =============================================
  // جستجوی کاربران
  // =============================================

  /// جستجوی کاربران بر اساس نام کاربری
  static Future<List<UserProfile>> searchUsers(String query) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id ?? '';

      final response = await _supabase
          .from('profiles')
          .select(
            'id, auth_user_id, username, first_name, last_name, avatar_url, is_online',
          )
          .ilike('username', '%$query%')
          .limit(25);

      final results = <UserProfile>[];
      for (final raw in response as List<dynamic>) {
        final user = raw as Map<String, dynamic>;
        final authId =
            (user['auth_user_id'] as String?)?.trim().isNotEmpty ?? false
            ? (user['auth_user_id'] as String).trim()
            : (user['id'] as String?) ?? '';
        if (authId.isEmpty || authId == currentUserId) continue;
        results.add(
          UserProfile.fromJson({
            ...user,
            'id': authId,
          }),
        );
        if (results.length >= 20) break;
      }
      return results;
    } catch (e) {
      throw Exception('خطا در جستجوی کاربران: $e');
    }
  }

  /// جستجوی کاربران پیشنهادی (غیر دوست و غیر بلاک)
  static Future<List<UserProfile>> getSuggestedUsers() async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

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

      final requestedAuthId = await resolveAuthUserId(requestedUserId);
      if (requestedAuthId == currentUserId) {
        throw Exception('نمی‌توانید به خودتان درخواست دوستی بفرستید');
      }

      if (await _isBlockedBetween(currentUserId, requestedAuthId)) {
        throw Exception('امکان ارسال درخواست به این کاربر وجود ندارد');
      }

      final friendship = await _supabase
          .from('user_friends')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('friend_id', requestedAuthId)
          .maybeSingle();
      if (friendship != null) {
        throw Exception('شما قبلاً با این کاربر دوست هستید');
      }

      // اگر طرف مقابل قبلاً برای ما درخواست pending فرستاده → تایید خودکار
      final reversePending = await _supabase
          .from('friendship_requests')
          .select('id')
          .eq('requester_id', requestedAuthId)
          .eq('requested_id', currentUserId)
          .eq('status', 'pending')
          .maybeSingle();

      if (reversePending != null) {
        await acceptFriendRequest(reversePending['id'] as String);
        return;
      }

      final existingRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', currentUserId)
          .eq('requested_id', requestedAuthId)
          .maybeSingle();

      String? requestId;

      if (existingRequest != null) {
        final status = existingRequest['status'] as String?;
        if (status == 'pending') {
          throw Exception('درخواست دوستی قبلاً ارسال شده است');
        }
        if (status == 'accepted') {
          throw Exception('شما قبلاً با این کاربر دوست هستید');
        }
        // rejected / cancelled → ارسال مجدد
        final updated = await _supabase
            .from('friendship_requests')
            .update({
              'status': 'pending',
              'message': message,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingRequest['id'] as String)
            .select('id')
            .single();
        requestId = updated['id'] as String?;
      } else {
        final inserted = await _supabase
            .from('friendship_requests')
            .insert({
              'requester_id': currentUserId,
              'requested_id': requestedAuthId,
              'message': message,
              'status': 'pending',
            })
            .select('id')
            .single();
        requestId = inserted['id'] as String?;
      }

      if (requestId != null) {
        final requesterName =
            await FriendshipNotificationService.displayNameForUser(
              currentUserId,
            );
        unawaited(
          FriendshipNotificationService.notifyFriendRequestReceived(
            recipientAuthId: requestedAuthId,
            requesterAuthId: currentUserId,
            requesterDisplayName: requesterName,
            requestId: requestId,
          ),
        );
      }
    } on Exception {
      rethrow;
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
          .eq('status', 'pending')
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

  /// شناسه درخواست pending ارسالی به یک کاربر
  static Future<String?> getPendingSentRequestId(String requestedUserId) async {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;
    final requestedAuthId = await resolveAuthUserId(requestedUserId);
    final row = await _supabase
        .from('friendship_requests')
        .select('id')
        .eq('requester_id', currentUserId)
        .eq('requested_id', requestedAuthId)
        .eq('status', 'pending')
        .maybeSingle();
    return row?['id'] as String?;
  }

  /// لغو درخواست pending ارسالی به یک کاربر
  static Future<void> cancelFriendRequestToUser(String requestedUserId) async {
    final requestId = await getPendingSentRequestId(requestedUserId);
    if (requestId == null) {
      throw Exception('درخواست در انتظاری یافت نشد');
    }
    await cancelFriendRequest(requestId);
  }

  /// تایید درخواست دوستی از طرف کاربری که درخواست فرستاده
  static Future<void> acceptFriendRequestFromRequester(
    String requesterId,
  ) async {
    final requesterAuthId = await resolveAuthUserId(requesterId);
    final list = await getReceivedRequests();
    FriendshipRequest? request;
    for (final r in list) {
      if (r.requesterId == requesterAuthId) {
        request = r;
        break;
      }
    }
    if (request == null) throw Exception('درخواست دوستی یافت نشد');
    await acceptFriendRequest(request.id);
  }

  /// تایید درخواست دوستی
  static Future<void> acceptFriendRequest(String requestId) async {
    try {
      final response = await _supabase
          .from('friendship_requests')
          .update({'status': 'accepted'})
          .eq('id', requestId)
          .select()
          .single();

      if (response['status'] != 'accepted') {
        throw Exception('درخواست تایید نشد');
      }

      await Future<void>.delayed(const Duration(milliseconds: 200));

      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        final requesterId = response['requester_id'] as String;
        final requestedId = response['requested_id'] as String;
        final friendId = currentUserId == requestedId
            ? requesterId
            : requestedId;

        final friendship = await _supabase
            .from('user_friends')
            .select('id')
            .eq('user_id', currentUserId)
            .eq('friend_id', friendId)
            .maybeSingle();

        if (friendship == null) {
          debugPrint(
            '⚠️ Friendship not created by trigger. Requester: $requesterId, Requested: $requestedId',
          );
        }

        if (currentUserId == requestedId) {
          final accepterName =
              await FriendshipNotificationService.displayNameForUser(
                currentUserId,
              );
          unawaited(
            FriendshipNotificationService.notifyFriendRequestAccepted(
              requesterAuthId: requesterId,
              accepterDisplayName: accepterName,
              friendAuthId: currentUserId,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error accepting friend request: $e');
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

  /// حذف دوست (دوطرفه — هر دو کاربر از لیست یکدیگر حذف می‌شوند)
  static Future<void> removeFriend(String friendId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');
      final friendAuthId = await resolveAuthUserId(friendId);

      try {
        await _supabase.rpc<void>(
          'remove_friend_bidirectional',
          params: {'p_friend_id': friendAuthId},
        );
        return;
      } catch (e) {
        debugPrint(
          'remove_friend_bidirectional RPC unavailable, using fallback: $e',
        );
      }

      await _supabase
          .from('user_friends')
          .delete()
          .eq('user_id', currentUserId)
          .eq('friend_id', friendAuthId);

      // اگر trigger سمت سرور نبود، سطر معکوس را هم حذف کن
      await _supabase
          .from('user_friends')
          .delete()
          .eq('user_id', friendAuthId)
          .eq('friend_id', currentUserId);
    } catch (e) {
      throw Exception('خطا در حذف دوست: $e');
    }
  }

  /// بررسی وضعیت دوستی
  static Future<FriendshipStatus> getFriendshipStatus(String userId) async {
    try {
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId == null) throw Exception('کاربر وارد نشده است');

      final targetAuthId = await resolveAuthUserId(userId);

      if (await _isBlockedBetween(currentUserId, targetAuthId)) {
        return FriendshipStatus.blocked;
      }

      final friendship = await _supabase
          .from('user_friends')
          .select('id')
          .eq('user_id', currentUserId)
          .eq('friend_id', targetAuthId)
          .maybeSingle();

      if (friendship != null) {
        return FriendshipStatus.friends;
      }

      final sentRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', currentUserId)
          .eq('requested_id', targetAuthId)
          .maybeSingle();

      if (sentRequest != null) {
        switch (sentRequest['status']) {
          case 'pending':
            return FriendshipStatus.requestSent;
          case 'rejected':
            return FriendshipStatus.requestRejected;
          default:
            break;
        }
      }

      final receivedRequest = await _supabase
          .from('friendship_requests')
          .select('id, status')
          .eq('requester_id', targetAuthId)
          .eq('requested_id', currentUserId)
          .maybeSingle();

      if (receivedRequest != null) {
        switch (receivedRequest['status']) {
          case 'pending':
            return FriendshipStatus.requestReceived;
          default:
            break;
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
      final blockedAuthId = await resolveAuthUserId(userId);

      await _supabase
          .from('user_friends')
          .delete()
          .or(
            '(user_id.eq.$currentUserId,friend_id.eq.$blockedAuthId),'
            '(user_id.eq.$blockedAuthId,friend_id.eq.$currentUserId)',
          );

      await _supabase
          .from('friendship_requests')
          .update({'status': 'cancelled'})
          .or(
            '(requester_id.eq.$currentUserId,requested_id.eq.$blockedAuthId),'
            '(requester_id.eq.$blockedAuthId,requested_id.eq.$currentUserId)',
          );

      await _supabase.from('user_blocks').insert({
        'blocker_id': currentUserId,
        'blocked_id': blockedAuthId,
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
      final blockedAuthId = await resolveAuthUserId(userId);

      await _supabase
          .from('user_blocks')
          .delete()
          .eq('blocker_id', currentUserId)
          .eq('blocked_id', blockedAuthId);
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
          .select('blocked_id')
          .eq('blocker_id', currentUserId);

      final blockedIds = (response as List<dynamic>)
          .map((b) => b['blocked_id'] as String)
          .where((id) => id.isNotEmpty)
          .toList();

      if (blockedIds.isEmpty) return [];

      final byAuth = await _supabase
          .from('profiles')
          .select(
            'id, auth_user_id, username, first_name, last_name, avatar_url, is_online',
          )
          .inFilter('auth_user_id', blockedIds);

      final results = <UserProfile>[];
      final seen = <String>{};
      for (final raw in byAuth as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final authId =
            (map['auth_user_id'] as String?)?.trim().isNotEmpty ?? false
            ? (map['auth_user_id'] as String).trim()
            : (map['id'] as String?) ?? '';
        if (authId.isEmpty || seen.contains(authId)) continue;
        seen.add(authId);
        results.add(UserProfile.fromJson({...map, 'id': authId}));
      }

      final missing = blockedIds.where((id) => !seen.contains(id)).toList();
      if (missing.isEmpty) return results;

      final byId = await _supabase
          .from('profiles')
          .select(
            'id, auth_user_id, username, first_name, last_name, avatar_url, is_online',
          )
          .inFilter('id', missing);

      for (final raw in byId as List<dynamic>) {
        final map = raw as Map<String, dynamic>;
        final authId =
            (map['auth_user_id'] as String?)?.trim().isNotEmpty ?? false
            ? (map['auth_user_id'] as String).trim()
            : (map['id'] as String?) ?? '';
        if (authId.isEmpty || seen.contains(authId)) continue;
        seen.add(authId);
        results.add(UserProfile.fromJson({...map, 'id': authId}));
      }
      return results;
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

      final friendsResponse = await _supabase
          .from('user_friends')
          .select('id')
          .eq('user_id', currentUserId);

      final receivedRequestsResponse = await _supabase
          .from('friendship_requests')
          .select('id')
          .eq('requested_id', currentUserId)
          .eq('status', 'pending');

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
        .from('friendship_requests')
        .stream(primaryKey: ['id'])
        .eq('requested_id', currentUserId)
        .asyncMap((_) => getReceivedRequests());
  }

  /// گوش دادن به تغییرات دوستان
  static Stream<List<UserProfile>> watchFriends() {
    final currentUserId = _supabase.auth.currentUser?.id;
    if (currentUserId == null) throw Exception('کاربر وارد نشده است');

    return _supabase
        .from('user_friends')
        .stream(primaryKey: ['id'])
        .eq('user_id', currentUserId)
        .asyncMap((_) => getFriends());
  }
}
