class UserProfile {
  UserProfile({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.isOnline = false,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final firstName = (json['first_name'] as String?) ?? '';
    final lastName = (json['last_name'] as String?) ?? '';
    final fullName = (firstName.isNotEmpty || lastName.isNotEmpty)
        ? '$firstName $lastName'.trim()
        : null;

    return UserProfile(
      id: (json['id'] as String?) ?? '',
      username: (json['username'] as String?) ?? '',
      fullName: fullName,
      avatarUrl: json['avatar_url'] as String?,
      isOnline: (json['is_online'] as bool?) ?? false,
    );
  }
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final bool isOnline;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'is_online': isOnline,
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
        return 'درخواست ارسال شده';
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
