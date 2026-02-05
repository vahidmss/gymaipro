class MotivationalVideo {
  MotivationalVideo({
    required this.id,
    required this.title,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.duration,
    required this.category,
    this.description,
    this.viewCount,
    this.likeCount,
    this.createdAt,
  });

  final int id;
  final String title;
  final String videoUrl;
  final String thumbnailUrl;
  final int duration; // مدت زمان به ثانیه
  final String
  category; // دسته‌بندی: motivation, transformation, competition, training
  final String? description;
  final int? viewCount;
  final int? likeCount;
  final DateTime? createdAt;

  static MotivationalVideo fromJson(Map<String, dynamic> json) {
    return MotivationalVideo(
      id: json['id'] as int,
      title: json['title'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String,
      duration: json['duration'] as int,
      category: json['category'] as String,
      description: json['description'] as String?,
      viewCount: json['view_count'] as int?,
      likeCount: json['like_count'] as int?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  static MotivationalVideo fromWordPressJson(Map<String, dynamic> json) {
    // Handle WordPress title object
    final titleObj = json['title'];
    final title = titleObj is Map
        ? (titleObj['rendered'] as String? ?? '')
        : (titleObj as String? ?? '');

    // Handle WordPress content/description
    final contentObj = json['content'];
    final description = contentObj is Map
        ? (contentObj['rendered'] as String? ?? '')
        : (contentObj as String? ?? '');

    // Extract meta fields (custom fields in WordPress)
    final meta = json['meta'] as Map<String, dynamic>? ?? {};
    final acf = json['acf'] as Map<String, dynamic>? ?? {};

    // Try to get video URL from meta or ACF or embedded media
    String videoUrl = '';

    // First try meta/ACF fields
    videoUrl =
        meta['video_url'] as String? ??
        acf['video_url'] as String? ??
        json['video_url'] as String? ??
        '';

    // If not found, try to extract from embedded media
    if (videoUrl.isEmpty && json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;

      // Try wp:featuredmedia
      final featuredMedia = embedded['wp:featuredmedia'] as List?;
      if (featuredMedia != null && featuredMedia.isNotEmpty) {
        final media = featuredMedia[0] as Map<String, dynamic>;
        final mimeType = media['mime_type'] as String? ?? '';
        if (mimeType.startsWith('video/')) {
          videoUrl = media['source_url'] as String? ?? '';
        }
      }

      // Try wp:attachment
      if (videoUrl.isEmpty) {
        final attachments = embedded['wp:attachment'] as List?;
        if (attachments != null && attachments.isNotEmpty) {
          for (final attachment in attachments) {
            if (attachment is Map<String, dynamic>) {
              final mimeType = attachment['mime_type'] as String? ?? '';
              if (mimeType.startsWith('video/')) {
                videoUrl = attachment['source_url'] as String? ?? '';
                if (videoUrl.isNotEmpty) break;
              }
            }
          }
        }
      }
    }

    // If still empty, try to find video in content
    if (videoUrl.isEmpty) {
      final content = description ?? '';
      final videoUrlPattern = RegExp(
        r'(?:https?://[^\s<>"]+\.(?:mp4|webm|ogg|mov|avi|m4v))',
        caseSensitive: false,
      );
      final match = videoUrlPattern.firstMatch(content);
      if (match != null) {
        videoUrl = match.group(0) ?? '';
      }
    }

    // Try to get duration from meta or ACF
    final duration =
        meta['duration'] as int? ??
        acf['duration'] as int? ??
        json['duration'] as int? ??
        0;

    // Try to get view count from meta or ACF
    final viewCount =
        meta['view_count'] as int? ??
        acf['view_count'] as int? ??
        json['view_count'] as int?;

    // Try to get like count from meta or ACF
    final likeCount =
        meta['like_count'] as int? ??
        acf['like_count'] as int? ??
        json['like_count'] as int?;

    // Get featured image or thumbnail
    String thumbnailUrl = '';
    if (json['_embedded'] != null) {
      final embedded = json['_embedded'] as Map<String, dynamic>;
      final featuredMedia = embedded['wp:featuredmedia'] as List?;
      if (featuredMedia != null && featuredMedia.isNotEmpty) {
        final media = featuredMedia[0] as Map<String, dynamic>;
        final mediaDetails = media['media_details'] as Map<String, dynamic>?;
        if (mediaDetails != null) {
          final sizes = mediaDetails['sizes'] as Map<String, dynamic>?;
          if (sizes != null) {
            thumbnailUrl =
                sizes['full']?['source_url'] as String? ??
                sizes['large']?['source_url'] as String? ??
                sizes['medium']?['source_url'] as String? ??
                media['source_url'] as String? ??
                '';
          }
          if (thumbnailUrl.isEmpty) {
            thumbnailUrl = media['source_url'] as String? ?? '';
          }
        }
        if (thumbnailUrl.isEmpty) {
          thumbnailUrl = media['source_url'] as String? ?? '';
        }
      }
    }

    // Fallback to direct image URL
    if (thumbnailUrl.isEmpty) {
      thumbnailUrl =
          meta['thumbnail_url'] as String? ??
          acf['thumbnail_url'] as String? ??
          json['thumbnail_url'] as String? ??
          json['featured_image'] as String? ??
          '';
    }

    // Parse date
    DateTime? createdAt;
    try {
      final dateStr = json['date'] as String? ?? json['created_at'] as String?;
      if (dateStr != null) {
        createdAt = DateTime.parse(dateStr);
      }
    } catch (_) {}

    return MotivationalVideo(
      id: json['id'] as int,
      title: title,
      videoUrl: videoUrl,
      thumbnailUrl: thumbnailUrl,
      duration: duration,
      category: 'general', // Default category, no filtering needed
      description: description,
      viewCount: viewCount,
      likeCount: likeCount,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'video_url': videoUrl,
      'thumbnail_url': thumbnailUrl,
      'duration': duration,
      'category': category,
      'description': description,
      'view_count': viewCount,
      'like_count': likeCount,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
