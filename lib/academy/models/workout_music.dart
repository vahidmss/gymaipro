class WorkoutMusic {
  WorkoutMusic({
    required this.id,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.coverImageUrl,
    required this.duration,
    this.category,
    this.description,
    this.createdAt,
    this.createdBy, // شناسه مربی که موزیک را اضافه کرده
    this.author, // نام فرستنده/مربی
    this.visibility = 'public', // 'public' or 'private'
    this.tags = const [], // تگ‌ها برای دسته‌بندی
    this.approved = true, // تایید شده یا نه
    this.isCustom = true, // همه موزیک‌ها از Supabase هستند
    this.likes = 0, // تعداد لایک‌ها
    this.isLikedByUser = false, // آیا کاربر فعلی لایک کرده است
  });

  final int id;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverImageUrl;
  final int duration; // مدت زمان به ثانیه
  final String? category; // دسته‌بندی (اختیاری)
  final String? description;
  final DateTime? createdAt;
  final String? createdBy; // شناسه کاربری که موزیک را ایجاد کرده
  final String? author; // نام فرستنده/مربی
  final String visibility; // 'public' or 'private'
  final List<String> tags; // تگ‌ها برای دسته‌بندی
  final bool approved; // تایید شده یا نه
  final bool isCustom; // همه موزیک‌ها از Supabase هستند
  int likes = 0; // تعداد لایک‌ها
  bool isLikedByUser = false; // آیا کاربر فعلی لایک کرده است

  static WorkoutMusic fromJson(Map<String, dynamic> json) {
    return WorkoutMusic(
      id: json['id'] as int,
      title: json['title'] as String,
      artist: json['artist'] as String,
      audioUrl: json['audio_url'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      duration: json['duration'] as int,
      category: json['category'] as String?,
      description: json['description'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      createdBy: json['created_by'] as String?,
      author: json['author'] as String?,
      visibility: json['visibility'] as String? ?? 'public',
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      approved: json['approved'] as bool? ?? true,
      isCustom: json['is_custom'] as bool? ?? true,
      likes: json['likes'] as int? ?? 0,
      isLikedByUser: json['is_liked_by_user'] as bool? ?? false,
    );
  }

  static String normalizeAudioUrl(String url) {
    var u = url.trim();
    if (u.isEmpty) return u;

    // Decode common HTML entity
    u = u.replaceAll('&amp;', '&');

    // Protocol-relative URL
    if (u.startsWith('//')) {
      return 'https:$u';
    }

    // Relative URL from site root
    if (u.startsWith('/')) {
      return 'https://gymaipro.ir$u';
    }

    // Missing scheme - add https
    if (!u.startsWith('http://') && !u.startsWith('https://')) {
      if (u.startsWith('gymaipro.ir')) {
        return 'https://$u';
      }
    }

    return u;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'category': category,
      'description': description,
      'created_at': createdAt?.toIso8601String(),
      'created_by': createdBy,
      'author': author,
      'visibility': visibility,
      'tags': tags,
      'approved': approved,
      'is_custom': isCustom,
      'likes': likes,
      'is_liked_by_user': isLikedByUser,
    };
  }

  String get formattedDuration {
    final minutes = duration ~/ 60;
    final seconds = duration % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
