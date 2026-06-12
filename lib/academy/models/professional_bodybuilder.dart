import 'package:gymaipro/utils/json_parse_utils.dart';

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
      id: JsonParse.integer(json, 'id'),
      name: JsonParse.string(json, 'name'),
      nationality: JsonParse.string(json, 'nationality'),
      birthDate: JsonParse.dateTime(json, 'birth_date', DateTime(1900)),
      biography: JsonParse.string(json, 'biography'),
      achievements: JsonParse.listOfStrings(json, 'achievements'),
      profileImageUrl: JsonParse.string(json, 'profile_image_url'),
      category: JsonParse.string(json, 'category'),
      height: JsonParse.doubleOrNull(json, 'height'),
      weight: JsonParse.doubleOrNull(json, 'weight'),
      instagramHandle: JsonParse.stringOrNull(json, 'instagram_handle'),
      youtubeChannel: JsonParse.stringOrNull(json, 'youtube_channel'),
      website: JsonParse.stringOrNull(json, 'website'),
      photos: _stringListOrNull(json['photos']),
      videos: _stringListOrNull(json['videos']),
      createdAt: JsonParse.dateTimeOrNull(json, 'created_at'),
    );
  }

  static List<String>? _stringListOrNull(dynamic v) {
    if (v is! List) return null;
    final out = <String>[];
    for (final e in v) {
      final s = e?.toString().trim();
      if (s != null && s.isNotEmpty) out.add(s);
    }
    return out.isEmpty ? null : out;
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

