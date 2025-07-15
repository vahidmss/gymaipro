class ChatMessage {
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

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.message,
    this.messageType = 'text',
    required this.createdAt,
    required this.updatedAt,
    this.isRead = false,
    this.isDeleted = false,
    this.attachmentUrl,
    this.attachmentType,
    this.attachmentName,
    this.attachmentSize,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      receiverId: json['receiver_id'] as String,
      message: json['message'] as String,
      messageType: json['message_type'] as String? ?? 'text',
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isRead: json['is_read'] as bool? ?? false,
      isDeleted: json['is_deleted'] as bool? ?? false,
      attachmentUrl: json['attachment_url'] as String?,
      attachmentType: json['attachment_type'] as String?,
      attachmentName: json['attachment_name'] as String?,
      attachmentSize: json['attachment_size'] as int?,
    );
  }

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
  final String id;
  final String userId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserAvatar;
  final String? otherUserRole;
  final DateTime lastMessageAt;
  final String? lastMessageText;
  final String? lastMessageType;
  final int unreadCount;
  final bool isSentByMe;

  ChatConversation({
    required this.id,
    required this.userId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserAvatar,
    this.otherUserRole,
    required this.lastMessageAt,
    this.lastMessageText,
    this.lastMessageType,
    this.unreadCount = 0,
    this.isSentByMe = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      otherUserId: json['other_user_id'] as String,
      otherUserName: json['other_user_name'] as String,
      otherUserAvatar: json['other_user_avatar'] as String?,
      otherUserRole: json['other_user_role'] as String?,
      lastMessageAt: DateTime.parse(json['last_message_at'] as String),
      lastMessageText: json['last_message_text'] as String?,
      lastMessageType: json['last_message_type'] as String?,
      unreadCount: json['unread_count'] as int? ?? 0,
      isSentByMe: json['is_sent_by_me'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'other_user_id': otherUserId,
      'other_user_name': otherUserName,
      'other_user_avatar': otherUserAvatar,
      'other_user_role': otherUserRole,
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message_text': lastMessageText,
      'last_message_type': lastMessageType,
      'unread_count': unreadCount,
      'is_sent_by_me': isSentByMe,
    };
  }

  bool get hasUnread => unreadCount > 0;
  bool get isTrainer => otherUserRole == 'trainer';
  bool get isAthlete => otherUserRole == 'athlete';
}

class ChatRoom {
  final String id;
  final String name;
  final String? description;
  final String createdBy;
  final String roomType; // direct, group
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;

  ChatRoom({
    required this.id,
    required this.name,
    this.description,
    required this.createdBy,
    this.roomType = 'direct',
    required this.createdAt,
    required this.updatedAt,
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
  final String id;
  final String roomId;
  final String userId;
  final DateTime joinedAt;
  final bool isAdmin;
  final bool isMuted;

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
