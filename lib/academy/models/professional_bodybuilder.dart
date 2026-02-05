class ProfessionalBodybuilder {
  ProfessionalBodybuilder({
    required this.id,
    required this.name,
    required this.nationality,
    required this.birthDate,
    required this.biography,
    required this.achievements,
    required this.profileImageUrl,
    required this.category, // دسته: classic, bodybuilding, physique, wellness
    this.height,
    this.weight,
    this.instagramHandle,
    this.youtubeChannel,
    this.website,
    this.photos,
    this.videos,
    this.createdAt,
  });

  final int id;
  final String name;
  final String nationality;
  final DateTime birthDate;
  final String biography; // زندگی‌نامه کامل
  final List<String> achievements; // دستاوردها
  final String profileImageUrl;
  final String category;
  final double? height; // قد به سانتی‌متر
  final double? weight; // وزن به کیلوگرم
  final String? instagramHandle;
  final String? youtubeChannel;
  final String? website;
  final List<String>? photos; // گالری عکس
  final List<String>? videos; // ویدیوهای مرتبط
  final DateTime? createdAt;

  static ProfessionalBodybuilder fromJson(Map<String, dynamic> json) {
    return ProfessionalBodybuilder(
      id: json['id'] as int,
      name: json['name'] as String,
      nationality: json['nationality'] as String,
      birthDate: DateTime.parse(json['birth_date'] as String),
      biography: json['biography'] as String,
      achievements: (json['achievements'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      profileImageUrl: json['profile_image_url'] as String,
      category: json['category'] as String,
      height: json['height'] as double?,
      weight: json['weight'] as double?,
      instagramHandle: json['instagram_handle'] as String?,
      youtubeChannel: json['youtube_channel'] as String?,
      website: json['website'] as String?,
      photos: (json['photos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      videos: (json['videos'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'nationality': nationality,
      'birth_date': birthDate.toIso8601String(),
      'biography': biography,
      'achievements': achievements,
      'profile_image_url': profileImageUrl,
      'category': category,
      'height': height,
      'weight': weight,
      'instagram_handle': instagramHandle,
      'youtube_channel': youtubeChannel,
      'website': website,
      'photos': photos,
      'videos': videos,
      'created_at': createdAt?.toIso8601String(),
    };
  }

  int get age {
    final now = DateTime.now();
    int age = now.year - birthDate.year;
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }
    return age;
  }
}

