class CommentReaction {
  CommentReaction({
    required this.id,
    required this.commentId,
    required this.userId,
    required this.reactionType,
    required this.createdAt,
  });

  factory CommentReaction.fromJson(Map<String, dynamic> json) {
    return CommentReaction(
      id: json['id'] as String,
      commentId: json['comment_id'] as String,
      userId: json['user_id'] as String,
      reactionType: json['reaction_type'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
  final String id;
  final String commentId;
  final String userId;
  final String reactionType; // 'like', 'heart', 'dislike'
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'comment_id': commentId,
      'user_id': userId,
      'reaction_type': reactionType,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Helper methods
  bool get isLike => reactionType == 'like';
  bool get isHeart => reactionType == 'heart';
  bool get isDislike => reactionType == 'dislike';

  // Get reaction emoji
  String get emoji {
    switch (reactionType) {
      case 'like':
        return '👍';
      case 'heart':
        return '❤️';
      case 'dislike':
        return '👎';
      default:
        return '❓';
    }
  }
}
