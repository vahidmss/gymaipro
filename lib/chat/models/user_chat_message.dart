class ChatMessage {
  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.messageType = 'text',
    this.isRead = false,
    this.isDeleted = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.attachmentSize,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['sender_id'] as String? ?? '',
      receiverId:
          ((json['receiver_id'] ?? json['recipient_id']) as String?) ?? '',
      message: json['message'] as String? ?? '',
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
    );
  }
  final String id;
  final String senderId;
  final String receiverId;
  final String message;
  final String messageType; // text, image, file, voice
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isRead;
  final bool isDeleted;
  final String? attachmentUrl;
  final String? attachmentType;
  final String? attachmentName;
  final int? attachmentSize;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'receiver_id': receiverId,
      'message': message,
      'message_type': messageType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_read': isRead,
      'is_deleted': isDeleted,
      'attachment_url': attachmentUrl,
      'attachment_type': attachmentType,
      'attachment_name': attachmentName,
      'attachment_size': attachmentSize,
    };
  }

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? message,
    String? messageType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isRead,
    bool? isDeleted,
    String? attachmentUrl,
    String? attachmentType,
    String? attachmentName,
    int? attachmentSize,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      message: message ?? this.message,
      messageType: messageType ?? this.messageType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isRead: isRead ?? this.isRead,
      isDeleted: isDeleted ?? this.isDeleted,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentType: attachmentType ?? this.attachmentType,
      attachmentName: attachmentName ?? this.attachmentName,
      attachmentSize: attachmentSize ?? this.attachmentSize,
    );
  }

  bool get isText => messageType == 'text';
  bool get isImage => messageType == 'image';
  bool get isFile => messageType == 'file';
  bool get isVoice => messageType == 'voice';
}

class ChatConversation {
  ChatConversation({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.updatedAt,
    this.user1Name,
    this.user2Name,
    this.user1Avatar,
    this.user2Avatar,
    this.lastMessage,
    this.lastMessageAt,
    this.lastMessageSenderId,
    this.user1UnreadCount = 0,
    this.user2UnreadCount = 0,
    this.user1LastReadAt,
    this.user2LastReadAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String? ?? '',
      user1Id: json['user1_id'] as String? ?? '',
      user2Id: json['user2_id'] as String? ?? '',
      user1Name: json['user1_name'] as String? ?? 'کاربر',
      user2Name: json['user2_name'] as String? ?? 'کاربر',
      user1Avatar: json['user1_avatar'] as String?,
      user2Avatar: json['user2_avatar'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      lastMessageSenderId: json['last_message_sender_id'] as String?,
      user1UnreadCount: json['user1_unread_count'] as int? ?? 0,
      user2UnreadCount: json['user2_unread_count'] as int? ?? 0,
      user1LastReadAt: json['user1_last_read_at'] != null
          ? DateTime.parse(json['user1_last_read_at'] as String)
          : null,
      user2LastReadAt: json['user2_last_read_at'] != null
          ? DateTime.parse(json['user2_last_read_at'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }
  final String id;
  final String user1Id;
  final String user2Id;
  final String? user1Name;
  final String? user2Name;
  final String? user1Avatar;
  final String? user2Avatar;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final String? lastMessageSenderId;
  final int user1UnreadCount;
  final int user2UnreadCount;
  final DateTime? user1LastReadAt;
  final DateTime? user2LastReadAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'user1_name': user1Name,
      'user2_name': user2Name,
      'user1_avatar': user1Avatar,
      'user2_avatar': user2Avatar,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'last_message_sender_id': lastMessageSenderId,
      'user1_unread_count': user1UnreadCount,
      'user2_unread_count': user2UnreadCount,
      'user1_last_read_at': user1LastReadAt?.toIso8601String(),
      'user2_last_read_at': user2LastReadAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  // Helper methods برای سازگاری با کد قدیمی
  String get userId => user1Id;
  String get otherUserId => user2Id;
  String get otherUserName => user2Name ?? 'کاربر';
  String? get otherUserAvatar => user2Avatar;
  DateTime get lastMessageDateTime => lastMessageAt ?? createdAt;
  String? get lastMessageText => lastMessage;
  int get unreadCount => user1UnreadCount;
  bool get isSentByMe => lastMessageSenderId == user1Id;

  // متد برای تشخیص کاربر دیگر بر اساس کاربر فعلی
  String getOtherUserId(String currentUserId) {
    return currentUserId == user1Id ? user2Id : user1Id;
  }

  String getOtherUserName(String currentUserId) {
    if (currentUserId == user1Id) {
      return (user2Name?.isNotEmpty ?? false) ? user2Name! : 'کاربر';
    } else {
      return (user1Name?.isNotEmpty ?? false) ? user1Name! : 'کاربر';
    }
  }

  String? getOtherUserAvatar(String currentUserId) {
    return currentUserId == user1Id ? user2Avatar : user1Avatar;
  }

  int getUnreadCount(String currentUserId) {
    return currentUserId == user1Id ? user1UnreadCount : user2UnreadCount;
  }

  bool hasUnreadForUser(String currentUserId) {
    return getUnreadCount(currentUserId) > 0;
  }

  bool get isTrainer => false; // این باید از profiles دریافت شود
  bool get isAthlete => false; // این باید از profiles دریافت شود
}

class ChatRoom {
  ChatRoom({
    required this.id,
    required this.name,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.roomType = 'direct',
    this.isActive = true,
  });

  factory ChatRoom.fromJson(Map<String, dynamic> json) {
    return ChatRoom(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      createdBy: json['created_by'] as String,
      roomType: json['room_type'] as String? ?? 'direct',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isActive: json['is_active'] as bool? ?? true,
    );
  }
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String roomType; // direct, group
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'created_by': createdBy,
      'room_type': roomType,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_active': isActive,
    };
  }

  bool get isDirect => roomType == 'direct';
  bool get isGroup => roomType == 'group';
}

class ChatRoomParticipant {
  ChatRoomParticipant({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.joinedAt,
    this.isAdmin = false,
    this.isMuted = false,
  });

  factory ChatRoomParticipant.fromJson(Map<String, dynamic> json) {
    return ChatRoomParticipant(
      id: json['id'] as String,
      roomId: json['room_id'] as String,
      userId: json['user_id'] as String,
      joinedAt: DateTime.parse(json['joined_at'] as String),
      isAdmin: json['is_admin'] as bool? ?? false,
      isMuted: json['is_muted'] as bool? ?? false,
    );
  }
  final String id;
  final String roomId;
  final String userId;
  final DateTime joinedAt;
  final bool isAdmin;
  final bool isMuted;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'room_id': roomId,
      'user_id': userId,
      'joined_at': joinedAt.toIso8601String(),
      'is_admin': isAdmin,
      'is_muted': isMuted,
    };
  }
}
