class PublicChatMessage {
  final String id;
  final String senderId;
  final String message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isDeleted;
  final String? senderName;
  final String? senderAvatar;
  final String? senderRole;

  PublicChatMessage({
    required this.id,
    required this.senderId,
    required this.message,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.senderName,
    this.senderAvatar,
    this.senderRole,
  });

  factory PublicChatMessage.fromJson(Map<String, dynamic> json) {
    return PublicChatMessage(
      id: json['id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      isDeleted: json['is_deleted'] as bool? ?? false,
      senderName: json['sender_name'] as String?,
      senderAvatar: json['sender_avatar'] as String?,
      senderRole: json['sender_role'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sender_id': senderId,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'is_deleted': isDeleted,
      'sender_name': senderName,
      'sender_avatar': senderAvatar,
      'sender_role': senderRole,
    };
  }

  PublicChatMessage copyWith({
    String? id,
    String? senderId,
    String? message,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    String? senderName,
    String? senderAvatar,
    String? senderRole,
  }) {
    return PublicChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      senderName: senderName ?? this.senderName,
      senderAvatar: senderAvatar ?? this.senderAvatar,
      senderRole: senderRole ?? this.senderRole,
    );
  }
}
