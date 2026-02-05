import 'package:gymaipro/academy/models/workout_music.dart';

/// مدل موزیک اختصاصی مربی
class CustomMusic {
  final String id;
  final String createdBy;
  final String title;
  final String artist;
  final String audioUrl;
  final String coverImageUrl;
  final int duration; // مدت زمان به ثانیه
  final String? category; // دسته‌بندی
  final String? description;
  final String visibility; // 'private' or 'public'
  final int viewsCount;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomMusic({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.artist,
    required this.audioUrl,
    required this.coverImageUrl,
    required this.duration,
    this.category,
    this.description,
    this.visibility = 'private',
    this.viewsCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomMusic.fromJson(Map<String, dynamic> json) {
    return CustomMusic(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      artist: json['artist'] as String,
      audioUrl: json['audio_url'] as String,
      coverImageUrl: json['cover_image_url'] as String,
      duration: json['duration'] as int,
      category: json['category'] as String?,
      description: json['description'] as String?,
      visibility: json['visibility'] as String? ?? 'private',
      viewsCount: json['views_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'artist': artist,
      'audio_url': audioUrl,
      'cover_image_url': coverImageUrl,
      'duration': duration,
      'category': category,
      'description': description,
      'visibility': visibility,
      'views_count': viewsCount,
      'likes_count': likesCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// تبدیل CustomMusic به WorkoutMusic
  WorkoutMusic toWorkoutMusic({String? authorName}) {
    // ساخت ID منحصر به فرد از UUID با استفاده از hash
    // محدوده INTEGER در PostgreSQL: -2,147,483,648 تا 2,147,483,647
    // استفاده از hash برای تبدیل UUID به عدد در محدوده INTEGER
    final hashValue = id.hashCode;
    // تبدیل به عدد مثبت و محدود به محدوده INTEGER (1,000,000 تا 1,000,000,000)
    // استفاده از modulo کوچکتر برای اطمینان از قرارگیری در محدوده
    final uniqueId = (hashValue.abs() % 999000000) + 1000000;
    
    return WorkoutMusic(
      id: uniqueId,
      title: title,
      artist: artist,
      audioUrl: audioUrl,
      coverImageUrl: coverImageUrl,
      duration: duration,
      category: category,
      description: description,
      createdAt: createdAt,
      createdBy: createdBy,
      author: authorName,
      visibility: visibility,
      tags: const [],
      approved: true, // همیشه تایید شده (چون فقط مربی می‌تواند اضافه کند)
      isCustom: true, // همه موزیک‌ها از Supabase هستند
      likes: likesCount, // استفاده از likes_count از دیتابیس
      isLikedByUser: false, // بعداً از سرویس لایک پر می‌شود
    );
  }
}

