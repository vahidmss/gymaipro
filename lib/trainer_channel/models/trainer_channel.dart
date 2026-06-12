class TrainerChannel {
  TrainerChannel({
    required this.id,
    required this.trainerId,
    required this.isEnabled,
    required this.createdAt,
    this.updatedAt,
    this.postCount = 0,
    this.lastPostAt,
  });

  factory TrainerChannel.fromMap(Map<String, dynamic> map) {
    return TrainerChannel(
      id: (map['id'] ?? '').toString(),
      trainerId: (map['trainer_id'] ?? '').toString(),
      isEnabled: map['is_enabled'] == true,
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.tryParse(map['updated_at'].toString())
          : null,
      postCount: (map['post_count'] as num?)?.toInt() ?? 0,
      lastPostAt: map['last_post_at'] != null
          ? DateTime.tryParse(map['last_post_at'].toString())
          : null,
    );
  }

  final String id;
  final String trainerId;
  final bool isEnabled;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final int postCount;
  final DateTime? lastPostAt;

  bool get isVisibleToPublic => isEnabled && postCount > 0;
}
