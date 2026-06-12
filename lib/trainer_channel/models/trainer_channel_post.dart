enum TrainerChannelContentType { text, image, video, voice, audio }

class TrainerChannelPost {
  TrainerChannelPost({
    required this.id,
    required this.channelId,
    required this.trainerId,
    required this.contentType,
    required this.createdAt,
    this.updatedAt,
    this.textContent,
    this.mediaUrl,
    this.mediaDurationSeconds,
    this.trainerName,
    this.trainerAvatarUrl,
    this.trainerUsername,
  });

  factory TrainerChannelPost.fromMap(Map<String, dynamic> map) {
    return TrainerChannelPost(
      id: (map['id'] ?? '').toString(),
      channelId: (map['channel_id'] ?? '').toString(),
      trainerId: (map['trainer_id'] ?? '').toString(),
      contentType: _parseContentType(map['content_type']?.toString()),
      textContent: map['text_content']?.toString(),
      mediaUrl: map['media_url']?.toString(),
      mediaDurationSeconds: (map['media_duration_seconds'] as num?)?.toInt(),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at']?.toString() ?? ''),
      trainerName: map['trainer_name']?.toString(),
      trainerAvatarUrl: map['trainer_avatar_url']?.toString(),
      trainerUsername: map['trainer_username']?.toString(),
    );
  }

  final String id;
  final String channelId;
  final String trainerId;
  final TrainerChannelContentType contentType;
  final String? textContent;
  final String? mediaUrl;
  final int? mediaDurationSeconds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? trainerName;
  final String? trainerAvatarUrl;
  final String? trainerUsername;

  bool get hasMedia =>
      contentType != TrainerChannelContentType.text &&
      mediaUrl != null &&
      mediaUrl!.trim().isNotEmpty;

  String get displayCaption {
    final t = textContent?.trim();
    if (t == null || t.isEmpty) return '';
    return t;
  }

  bool get hasCaption => displayCaption.isNotEmpty;

  bool get isEdited {
    if (updatedAt == null) return false;
    return updatedAt!.difference(createdAt).inSeconds > 2;
  }

  /// متن قابل ویرایش: پست متنی یا کپشن (افزودن/تغییر زیر عکس و ویدیو)
  bool get canEditText =>
      contentType == TrainerChannelContentType.text ||
      contentType == TrainerChannelContentType.image ||
      contentType == TrainerChannelContentType.video ||
      contentType == TrainerChannelContentType.audio;

  bool get isPlayableAudio =>
      contentType == TrainerChannelContentType.voice ||
      contentType == TrainerChannelContentType.audio;

  bool get isMediaOnly =>
      hasMedia && !hasCaption && contentType != TrainerChannelContentType.text;

  static TrainerChannelContentType _parseContentType(String? raw) {
    switch (raw) {
      case 'image':
        return TrainerChannelContentType.image;
      case 'video':
        return TrainerChannelContentType.video;
      case 'voice':
        return TrainerChannelContentType.voice;
      case 'audio':
        return TrainerChannelContentType.audio;
      default:
        return TrainerChannelContentType.text;
    }
  }

  static String contentTypeToDb(TrainerChannelContentType type) {
    switch (type) {
      case TrainerChannelContentType.image:
        return 'image';
      case TrainerChannelContentType.video:
        return 'video';
      case TrainerChannelContentType.voice:
        return 'voice';
      case TrainerChannelContentType.audio:
        return 'audio';
      case TrainerChannelContentType.text:
        return 'text';
    }
  }
}
