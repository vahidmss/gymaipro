import 'package:gymaipro/core/user_presence.dart';

class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isOnline = false,
    this.lastSeenAt,
    this.lastActiveAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    var firstName = (json['first_name'] as String?) ?? '';
    var lastName = (json['last_name'] as String?) ?? '';
    final rpcFullName = (json['full_name'] as String?)?.trim();
    if ((firstName.isEmpty && lastName.isEmpty) &&
        rpcFullName != null &&
        rpcFullName.isNotEmpty) {
      final parts = rpcFullName.split(RegExp(r'\s+'));
      firstName = parts.isNotEmpty ? parts.first : '';
      lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    }
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : (rpcFullName?.isNotEmpty ?? false ? rpcFullName : null);

    final lastSeenRaw = json['last_seen_at'] ?? json['friend_last_seen_at'];
    final lastActiveRaw =
        json['last_active_at'] ?? json['friend_last_active_at'];

    return UserProfile(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      fullName: fullName,
      avatarUrl: json['avatar_url'] as String?,
      lastSeenAt: UserPresence.effectiveLastSeen(
        lastSeenRaw: lastSeenRaw,
        lastActiveRaw: lastActiveRaw,
      ),
      lastActiveAt: () {
        final s = lastActiveRaw?.toString();
        if (s == null || s.isEmpty) return null;
        return DateTime.tryParse(s)?.toLocal();
      }(),
      isOnline: UserPresence.isOnline(
        lastSeenRaw: lastSeenRaw,
        lastActiveRaw: lastActiveRaw,
      ),
    );
  }
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isOnline;
  final DateTime? lastSeenAt;
  final DateTime? lastActiveAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'last_active_at': lastActiveAt?.toIso8601String(),
    };
  }
}

class FriendshipRequest {
  FriendshipRequest({
    required this.id,
    required this.requesterId,
    required this.requestedId,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.message,
    this.requesterUsername,
    this.requesterFullName,
    this.requesterAvatar,
    this.requestedUsername,
    this.requestedFullName,
    this.requestedAvatar,
  });

  factory FriendshipRequest.fromJson(Map<String, dynamic> json) {
    return FriendshipRequest(
      id: (json['id'] as String?) ?? '',
      requesterId: (json['requester_id'] as String?) ?? '',
      requestedId: (json['requested_id'] as String?) ?? '',
      status: (json['status'] as String?) ?? 'pending',
      message: json['message'] as String?,
      createdAt: DateTime.parse(
        (json['created_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        (json['updated_at'] as String?) ?? DateTime.now().toIso8601String(),
      ),
      requesterUsername: json['requester_username'] as String?,
      requesterFullName: json['requester_full_name'] as String?,
      requesterAvatar: json['requester_avatar'] as String?,
      requestedUsername: json['requested_username'] as String?,
      requestedFullName: json['requested_full_name'] as String?,
      requestedAvatar: json['requested_avatar'] as String?,
    );
  }
  final String id;
  final String requesterId;
  final String requestedId;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;

  // اطلاعات کاربر درخواست کننده
  final String? requesterUsername;
  final String? requesterFullName;
  final String? requesterAvatar;

  // اطلاعات کاربر درخواست شونده
  final String? requestedUsername;
  final String? requestedFullName;
  final String? requestedAvatar;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'requester_id': requesterId,
      'requested_id': requestedId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'requester_username': requesterUsername,
      'requester_full_name': requesterFullName,
      'requester_avatar': requesterAvatar,
      'requested_username': requestedUsername,
      'requested_full_name': requestedFullName,
      'requested_avatar': requestedAvatar,
    };
  }
}

class FriendshipStats {
  FriendshipStats({
    required this.friendsCount,
    required this.receivedRequestsCount,
    required this.sentRequestsCount,
  });

  factory FriendshipStats.fromJson(Map<String, dynamic> json) {
    return FriendshipStats(
      friendsCount: (json['friends_count'] as int?) ?? 0,
      receivedRequestsCount: (json['received_requests_count'] as int?) ?? 0,
      sentRequestsCount: (json['sent_requests_count'] as int?) ?? 0,
    );
  }
  final int friendsCount;
  final int receivedRequestsCount;
  final int sentRequestsCount;

  Map<String, dynamic> toJson() {
    return {
      'friends_count': friendsCount,
      'received_requests_count': receivedRequestsCount,
      'sent_requests_count': sentRequestsCount,
    };
  }
}

enum FriendshipStatus {
  none, // هیچ رابطه‌ای نیست
  friends, // دوست هستند
  requestSent, // درخواست ارسال شده
  requestReceived, // درخواست دریافت شده
  requestRejected, // درخواست رد شده
  blocked, // بلاک شده
}

class FriendshipStatusHelper {
  static String getStatusText(FriendshipStatus status) {
    switch (status) {
      case FriendshipStatus.none:
        return 'ارسال درخواست دوستی';
      case FriendshipStatus.friends:
        return 'دوستان';
      case FriendshipStatus.requestSent:
        return 'لغو درخواست';
      case FriendshipStatus.requestReceived:
        return 'تایید درخواست';
      case FriendshipStatus.requestRejected:
        return 'درخواست رد شده';
      case FriendshipStatus.blocked:
        return 'بلاک شده';
    }
  }

  static bool canSendRequest(FriendshipStatus status) {
    return status == FriendshipStatus.none ||
        status == FriendshipStatus.requestRejected;
  }

  static bool canAcceptRequest(FriendshipStatus status) {
    return status == FriendshipStatus.requestReceived;
  }

  static bool canRemoveFriend(FriendshipStatus status) {
    return status == FriendshipStatus.friends;
  }
}

class SearchFilters {
  SearchFilters({this.onlineOnly = false, this.hasAvatar = false, this.sortBy});
  final bool onlineOnly;
  final bool hasAvatar;
  final String? sortBy;

  Map<String, dynamic> toJson() {
    return {
      'online_only': onlineOnly,
      'has_avatar': hasAvatar,
      'sort_by': sortBy,
    };
  }
}
