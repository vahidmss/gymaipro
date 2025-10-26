import 'dart:convert';

class Exercise {
  Exercise({
    required this.id,
    required this.title,
    required this.name,
    required this.mainMuscle,
    required this.secondaryMuscles,
    required this.tips,
    required this.videoUrl,
    required this.imageUrl,
    required this.otherNames,
    required this.content,
    this.difficulty = 'متوسط',
    this.equipment = 'بدون تجهیزات',
    this.exerciseType = 'قدرتی',
    this.estimatedDuration = 0,
    this.targetArea = '',
    this.tags = const [],
    this.detailedDescription = '',
    this.isFavorite = false,
    this.likes = 0,
    this.isLikedByUser = false,
  });

  factory Exercise.fromJson(Map<String, dynamic> json) {
    final String modified = (json['modified'] ?? '').toString();

    final meta = json['meta'];
    final Map<String, dynamic> metaMap = (meta is Map<String, dynamic>)
        ? meta
        : <String, dynamic>{};
    String readStr(String key) {
      final v = metaMap[key];
      if (v == null) return '';
      if (v is List) return v.whereType<String>().join(', ');
      return v.toString();
    }

    // tips
    final List<String> tipsList = [];
    if (meta is Map) {
      final t1 = meta['tip_1'];
      final t2 = meta['tip_2'];
      final t3 = meta['tip_3'];
      if (t1 != null && t1.toString().trim().isNotEmpty) {
        tipsList.add(t1.toString().trim());
      }
      if (t2 != null && t2.toString().trim().isNotEmpty) {
        tipsList.add(t2.toString().trim());
      }
      if (t3 != null && t3.toString().trim().isNotEmpty) {
        tipsList.add(t3.toString().trim());
      }
    }

    // other_names as array (or JSON string fallback)
    final List<String> otherNamesList = [];
    if (meta is Map) {
      final on = meta['other_names'];
      if (on is List) {
        for (final entry in on) {
          if (entry is String) {
            final s = entry.trim();
            if (s.isNotEmpty && s.toLowerCase() != 'array') {
              otherNamesList.add(s);
            }
          }
        }
      } else if (on is Map) {
        for (final value in on.values) {
          if (value is String) {
            final s = value.trim();
            if (s.isNotEmpty && s.toLowerCase() != 'array') {
              otherNamesList.add(s);
            }
          }
        }
      } else if (on is String && on.trim().isNotEmpty) {
        final raw = on.trim();
        final rawLower = raw.toLowerCase();
        // Guard against bad values like 'Array' or serialized strings
        final looksSerialized =
            rawLower.startsWith('a:') || rawLower.startsWith('s:');
        if (rawLower == 'array' || looksSerialized) {
          // ignore entirely
        } else {
          try {
            final decoded = jsonDecode(raw);
            if (decoded is List) {
              for (final entry in decoded) {
                if (entry is String && entry.trim().isNotEmpty) {
                  otherNamesList.add(entry.trim());
                }
              }
            } else if (decoded is Map) {
              for (final value in decoded.values) {
                if (value is String) {
                  final s = value.trim();
                  if (s.isNotEmpty && s.toLowerCase() != 'array') {
                    otherNamesList.add(s);
                  }
                }
              }
            } else {
              // fallback: comma/newline separated
              final parts = raw.split(RegExp('[,\n]'));
              for (final p in parts) {
                final s = p.trim();
                if (s.isNotEmpty && s.toLowerCase() != 'array') {
                  otherNamesList.add(s);
                }
              }
            }
          } catch (_) {
            final parts = raw.split(RegExp('[,\n]'));
            for (final p in parts) {
              final s = p.trim();
              if (s.isNotEmpty && s.toLowerCase() != 'array') {
                otherNamesList.add(s);
              }
            }
          }
        }
      }
    }

    // tags: we reuse muscles as tags
    final List<String> tagsList = [];
    if (meta is Map) {
      if (meta['main_muscle'] != null) {
        tagsList.add(meta['main_muscle'].toString());
      }
      if (meta['secondary_muscles'] != null) {
        tagsList.add(meta['secondary_muscles'].toString());
      }
    }

    final String detailedDesc =
        (meta is Map &&
            (meta['detailed_description'] ?? '').toString().isNotEmpty)
        ? meta['detailed_description'].toString()
        : '';

    String determineDifficulty(String content) {
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('پیشرفته') ||
          lowerContent.contains('حرفه‌ای')) {
        return 'پیشرفته';
      }
      if (lowerContent.contains('مبتدی') || lowerContent.contains('ساده')) {
        return 'مبتدی';
      }
      return 'متوسط';
    }

    String determineEquipment(String content) {
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('هالتر') || lowerContent.contains('باربل')) {
        return 'هالتر';
      }
      if (lowerContent.contains('دمبل')) return 'دمبل';
      if (lowerContent.contains('کابل') || lowerContent.contains('ماشین')) {
        return 'ماشین';
      }
      if (lowerContent.contains('وزنه') || lowerContent.contains('کش')) {
        return 'وزنه/کش';
      }
      return 'بدون تجهیزات';
    }

    String determineExerciseType(String content) {
      final lowerContent = content.toLowerCase();
      if (lowerContent.contains('کاردیو') || lowerContent.contains('هوازی')) {
        return 'کاردیو';
      }
      if (lowerContent.contains('کششی') || lowerContent.contains('انعطاف')) {
        return 'کششی';
      }
      if (lowerContent.contains('تعادل') || lowerContent.contains('پایداری')) {
        return 'تعادل/پایداری';
      }
      return 'قدرتی';
    }

    int estimateDuration(String content, List<String> tips) {
      int baseTime = 60;
      if (tips.length > 2) baseTime += 30;
      if (content.length > 500) baseTime += 30;
      return baseTime;
    }

    // image url: ALWAYS prefer WP featured image (ignore meta.image_url entirely)
    String imageUrl = '';
    try {
      final embedded = json['_embedded'];
      if (embedded is Map &&
          embedded['wp:featuredmedia'] is List &&
          (embedded['wp:featuredmedia'] as List).isNotEmpty) {
        final media = (embedded['wp:featuredmedia'] as List).first;
        final src = (media is Map) ? media['source_url'] : null;
        if (src is String && src.isNotEmpty) imageUrl = src;
      }
    } catch (_) {}
    if (imageUrl.isEmpty) {
      final fi = json['featured_image'];
      if (fi is String && fi.isNotEmpty) imageUrl = fi;
    }
    final String versionTag = modified.isNotEmpty
        ? modified
        : (json['title']?['rendered'] ?? '').toString();
    imageUrl = _appendVersion(imageUrl, versionTag);

    final String contentText = readStr('learn').isNotEmpty
        ? readStr('learn')
        : ((json['content'] is Map
                      ? json['content']['rendered']
                      : json['content']) ??
                  '')
              .toString();

    final String difficulty = readStr('difficulty').isNotEmpty
        ? readStr('difficulty')
        : determineDifficulty(contentText);
    final String equipment = readStr('equipment').isNotEmpty
        ? readStr('equipment')
        : determineEquipment(contentText);
    final String exerciseType = readStr('exercise_type').isNotEmpty
        ? readStr('exercise_type')
        : determineExerciseType(contentText);
    final int estimatedDuration = metaMap['estimated_duration'] != null
        ? int.tryParse(metaMap['estimated_duration'].toString()) ??
              estimateDuration(contentText, tipsList)
        : estimateDuration(contentText, tipsList);

    // Fallbacks for custom endpoint fields (gymai/v1)
    final String nameFallback = (json['name'] ?? '').toString();
    final String mainMuscleFallback = (json['main_muscle'] ?? '').toString();
    final String secondaryMusclesFallback = (json['secondary_muscles'] ?? '')
        .toString();
    final String videoUrlFallback = (json['video_url'] ?? '').toString();
    final String contentFallback = (json['content'] ?? json['learn'] ?? '')
        .toString();
    final List<String> otherNamesFallback = () {
      final v = json['other_names'];
      if (v is List) {
        return v
            .whereType<String>()
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
      return <String>[];
    }();

    return Exercise(
      id: (json['id'] as int?) ?? 0,
      title:
          (json['title'] is Map
              ? (json['title'] as Map<String, dynamic>)['rendered'] as String?
              : json['title'] as String?) ??
          '',
      name: readStr('name_app').isNotEmpty
          ? readStr('name_app')
          : (nameFallback.isNotEmpty
                ? nameFallback
                : ((json['title'] is Map
                              ? json['title']['rendered']
                              : json['title']) ??
                          '')
                      .toString()),
      mainMuscle: readStr('main_muscle').isNotEmpty
          ? readStr('main_muscle')
          : mainMuscleFallback,
      secondaryMuscles: readStr('secondary_muscles').isNotEmpty
          ? readStr('secondary_muscles')
          : secondaryMusclesFallback,
      tips: tipsList,
      videoUrl: readStr('video_url').isNotEmpty
          ? readStr('video_url')
          : videoUrlFallback,
      imageUrl: imageUrl,
      otherNames: otherNamesList.isNotEmpty
          ? otherNamesList
          : otherNamesFallback,
      content: contentText.isNotEmpty ? contentText : contentFallback,
      difficulty: difficulty,
      equipment: equipment,
      exerciseType: exerciseType,
      estimatedDuration: estimatedDuration,
      targetArea: readStr('target_area').isNotEmpty
          ? readStr('target_area')
          : readStr('main_muscle'),
      tags: tagsList,
      detailedDescription: detailedDesc,
    );
  }
  final int id;
  final String title;
  final String name;
  final String mainMuscle;
  final String secondaryMuscles;
  final List<String> tips;
  final String videoUrl;
  final String imageUrl;
  final List<String> otherNames;
  final String content;

  // فیلدهای جدید برای فیلتر پیشرفته
  final String difficulty; // سطح دشواری
  final String equipment; // تجهیزات مورد نیاز
  final String exerciseType; // نوع تمرین
  final int estimatedDuration; // مدت زمان تخمینی (ثانیه)
  final String targetArea; // ناحیه هدف
  final List<String> tags; // تگ‌های اضافی
  final String detailedDescription; // توضیح تکمیلی

  bool isFavorite;
  int likes;
  bool isLikedByUser;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'name': name,
      'mainMuscle': mainMuscle,
      'secondaryMuscles': secondaryMuscles,
      'tips': tips,
      'videoUrl': videoUrl,
      'imageUrl': imageUrl,
      'otherNames': otherNames,
      'content': content,
      'difficulty': difficulty,
      'equipment': equipment,
      'exerciseType': exerciseType,
      'estimatedDuration': estimatedDuration,
      'targetArea': targetArea,
      'tags': tags,
      'detailedDescription': detailedDescription,
      'isFavorite': isFavorite,
      'likes': likes,
      'isLikedByUser': isLikedByUser,
    };
  }

  // Append version query parameter to force refresh when content changes
  static String _appendVersion(String url, String versionTag) {
    if (url.isEmpty) return url;
    if (versionTag.isEmpty) return url;
    final separator = url.contains('?') ? '&' : '?';
    // Sanitize version tag (remove spaces)
    final v = versionTag.replaceAll(RegExp(r'\s+'), '');
    return '$url${separator}v=$v';
  }
}
