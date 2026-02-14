import 'package:gymaipro/utils/json_parse_utils.dart';

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
      id: JsonParse.integer(json, 'id'),
      title: JsonParse.string(json, 'title'),
      videoUrl: JsonParse.string(json, 'video_url'),
      thumbnailUrl: JsonParse.string(json, 'thumbnail_url'),
      duration: JsonParse.integer(json, 'duration'),
      category: JsonParse.string(json, 'category', 'general'),
      description: JsonParse.stringOrNull(json, 'description'),
      viewCount: JsonParse.integerOrNull(json, 'view_count'),
      likeCount: JsonParse.integerOrNull(json, 'like_count'),
      createdAt: JsonParse.dateTimeOrNull(json, 'created_at'),
    );
  }

  static MotivationalVideo fromWordPressJson(Map<String, dynamic> json) {
    final titleObj = json['title'];
    final title = titleObj is Map
        ? JsonParse.fromStr(titleObj['rendered'])
        : JsonParse.fromStr(titleObj);

    final contentObj = json['content'];
    final description = contentObj is Map
        ? JsonParse.fromStr(contentObj['rendered'])
        : JsonParse.fromStr(contentObj);

    // Extract meta fields (custom fields in WordPress)
    final rawMeta = json['meta'];
    final meta = rawMeta is Map<String, dynamic>
        ? rawMeta
        : <String, dynamic>{};
    final rawAcf = json['acf'];
    final acf = rawAcf is Map<String, dynamic> ? rawAcf : <String, dynamic>{};

    // Try to get video URL from meta or ACF or embedded media
    String videoUrl = '';

    videoUrl = JsonParse.fromStr(meta['video_url']);
    if (videoUrl.isEmpty) videoUrl = JsonParse.fromStr(acf['video_url']);
    if (videoUrl.isEmpty) videoUrl = JsonParse.fromStr(json['video_url']);

    // If not found, try to extract from embedded media
    if (videoUrl.isEmpty && json['_embedded'] != null) {
      final embeddedRaw = json['_embedded'];
      final embedded = embeddedRaw is Map<String, dynamic>
          ? embeddedRaw
          : <String, dynamic>{};

      // Try wp:featuredmedia
      final dynamicFeaturedMedia = embedded['wp:featuredmedia'];
      final featuredMedia = dynamicFeaturedMedia is List
          ? dynamicFeaturedMedia
          : null;
      if (featuredMedia != null && featuredMedia.isNotEmpty) {
        final mediaRaw = featuredMedia[0];
        final media = mediaRaw is Map<String, dynamic>
            ? mediaRaw
            : <String, dynamic>{};
        final mimeType = JsonParse.fromStr(media['mime_type']);
        if (mimeType.startsWith('video/')) {
          videoUrl = JsonParse.fromStr(media['source_url']);
        }
      }

      // Try wp:attachment
      if (videoUrl.isEmpty) {
        final attachmentsRaw = embedded['wp:attachment'];
        final attachments = attachmentsRaw is List ? attachmentsRaw : null;
        if (attachments != null && attachments.isNotEmpty) {
          for (final attachment in attachments) {
            if (attachment is Map<String, dynamic>) {
              final mimeType = JsonParse.fromStr(attachment['mime_type']);
              if (mimeType.startsWith('video/')) {
                videoUrl = JsonParse.fromStr(attachment['source_url']);
                if (videoUrl.isNotEmpty) break;
              }
            }
          }
        }
      }
    }

    // If still empty, try to find video in content
    if (videoUrl.isEmpty) {
      final content = description;
      final videoUrlPattern = RegExp(
        r'(?:https?://[^\s<>"]+\.(?:mp4|webm|ogg|mov|avi|m4v))',
        caseSensitive: false,
      );
      final match = videoUrlPattern.firstMatch(content);
      if (match != null) {
        videoUrl = match.group(0) ?? '';
      }
    }

    // Try to get duration from meta or ACF (safe parse)
    final duration =
        JsonParse.fromIntOrNull(meta['duration']) ??
        JsonParse.fromIntOrNull(acf['duration']) ??
        JsonParse.fromIntOrNull(json['duration']) ??
        0;

    final viewCount =
        JsonParse.fromIntOrNull(meta['view_count']) ??
        JsonParse.fromIntOrNull(acf['view_count']) ??
        JsonParse.fromIntOrNull(json['view_count']);

    final likeCount =
        JsonParse.fromIntOrNull(meta['like_count']) ??
        JsonParse.fromIntOrNull(acf['like_count']) ??
        JsonParse.fromIntOrNull(json['like_count']);

    // Get featured image or thumbnail
    String thumbnailUrl = '';
    if (json['_embedded'] != null) {
      final embeddedRaw = json['_embedded'];
      final embedded = embeddedRaw is Map<String, dynamic>
          ? embeddedRaw
          : <String, dynamic>{};
      final featuredMediaRaw = embedded['wp:featuredmedia'];
      final featuredMedia = featuredMediaRaw is List ? featuredMediaRaw : null;
      if (featuredMedia != null && featuredMedia.isNotEmpty) {
        final mediaRaw = featuredMedia[0];
        final media = mediaRaw is Map<String, dynamic>
            ? mediaRaw
            : <String, dynamic>{};
        final mediaDetails = media['media_details'] is Map<String, dynamic>
            ? media['media_details'] as Map<String, dynamic>
            : null;
        if (mediaDetails != null) {
          final sizes = mediaDetails['sizes'] is Map<String, dynamic>
              ? mediaDetails['sizes'] as Map<String, dynamic>
              : null;
          if (sizes != null) {
            thumbnailUrl = JsonParse.fromStr(sizes['full']?['source_url']);
            if (thumbnailUrl.isEmpty) {
              thumbnailUrl = JsonParse.fromStr(sizes['large']?['source_url']);
            }
            if (thumbnailUrl.isEmpty) {
              thumbnailUrl = JsonParse.fromStr(sizes['medium']?['source_url']);
            }
            if (thumbnailUrl.isEmpty) {
              thumbnailUrl = JsonParse.fromStr(media['source_url']);
            }
          }
          if (thumbnailUrl.isEmpty) {
            thumbnailUrl = JsonParse.fromStr(media['source_url']);
          }
        }
        if (thumbnailUrl.isEmpty) {
          thumbnailUrl = JsonParse.fromStr(media['source_url']);
        }
      }
    }

    if (thumbnailUrl.isEmpty) {
      thumbnailUrl = JsonParse.fromStr(meta['thumbnail_url']);
      if (thumbnailUrl.isEmpty) {
        thumbnailUrl = JsonParse.fromStr(acf['thumbnail_url']);
      }
      if (thumbnailUrl.isEmpty) {
        thumbnailUrl = JsonParse.fromStr(json['thumbnail_url']);
      }
      if (thumbnailUrl.isEmpty) {
        thumbnailUrl = JsonParse.fromStr(json['featured_image']);
      }
    }

    // Parse date (safe)
    final dateStr =
        JsonParse.fromStrOrNull(json['date']) ??
        JsonParse.fromStrOrNull(json['created_at']);
    DateTime? createdAt;
    if (dateStr != null && dateStr.isNotEmpty) {
      createdAt = DateTime.tryParse(dateStr);
    }

    int id = 0;
    try {
      final rawId = json['id'];
      if (rawId is int) {
        id = rawId;
      } else if (rawId != null) {
        id = int.tryParse(rawId.toString()) ?? 0;
      }
    } catch (_) {
      id = 0;
    }

    return MotivationalVideo(
      id: id,
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
