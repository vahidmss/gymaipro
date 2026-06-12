import 'dart:convert';

import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/models/exercise_rich_meta.dart';
import 'package:gymaipro/models/muscle_targets.dart';

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
    required this.otherNames, required this.content, this.additionalImageUrls = const [],
    this.additionalVideoUrls = const [],
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
    this.author,
    this.createdBy,
    this.shortDescription = '',
    this.movementPattern = '',
    this.bodyEngagement = '',
    this.typicalRpe,
    this.met,
    this.muscleTargets = const {},
    ExerciseRichMeta? richMeta,
  }) : richMeta = richMeta ?? const ExerciseRichMeta();

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
    // NOTE: cached exercises use `toJson()` which stores `title` as a String.
    // WP payload uses `title` as a Map with `rendered`.
    // We must handle both to avoid: "type 'String' is not a subtype of type 'int' of 'index'".
    final titleObj = json['title'];
    final titleRenderedOrValue =
        (titleObj is Map) ? titleObj['rendered'] : titleObj;
    final String versionTag =
        modified.isNotEmpty ? modified : (titleRenderedOrValue ?? '').toString();
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

    List<String> readCachedUrlList(String key) {
      final v = json[key];
      if (v is List) {
        return v
            .map((e) => e.toString().trim())
            .where((s) => s.isNotEmpty)
            .toList();
      }
      return const [];
    }

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
      additionalImageUrls: readCachedUrlList('additionalImageUrls'),
      additionalVideoUrls: readCachedUrlList('additionalVideoUrls'),
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
      author: json['author'] as String?,
      createdBy: json['createdBy'] as String?,
      shortDescription: (json['shortDescription'] as String?)?.trim() ?? '',
      movementPattern: readStr('movement_pattern').isNotEmpty
          ? readStr('movement_pattern')
          : (json['movement_pattern'] ?? '').toString(),
      bodyEngagement: readStr('body_engagement').isNotEmpty
          ? readStr('body_engagement')
          : (json['body_engagement'] ?? '').toString(),
      typicalRpe: () {
        final v = metaMap['typical_rpe'] ?? json['typical_rpe'];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }(),
      met: () {
        final v = metaMap['met'] ?? json['met'];
        if (v == null) return null;
        if (v is num) return v.toDouble();
        return double.tryParse(v.toString());
      }(),
      muscleTargets: MuscleTargets.parse(
        metaMap['muscle_targets'] ?? json['muscle_targets'],
      ),
      richMeta: ExerciseRichMeta.fromJson(
        metaMap['exercise_extended_json'] ??
            metaMap['rich_meta'] ??
            json['exercise_extended_json'],
      ),
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
  /// تصاویر اضافه بعد از [imageUrl] (مثلاً تمرین اختصاصی چندعکسه)
  final List<String> additionalImageUrls;
  /// ویدیوهای اضافه بعد از [videoUrl]
  final List<String> additionalVideoUrls;
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
  final String? author; // نویسنده تمرین
  final String? createdBy; // شناسه کاربری که تمرین را ایجاد کرده (برای تمرین‌های اختصاصی)
  final String shortDescription;
  final String movementPattern;
  final String bodyEngagement;
  final double? typicalRpe;
  final double? met;
  final Map<String, int> muscleTargets;
  final ExerciseRichMeta richMeta;

  bool isFavorite;
  int likes;
  bool isLikedByUser;

  /// همه آدرس تصاویر بدون تکرار (اولویت با [imageUrl])
  List<String> get allImageUrls => _mergeUrlLists(imageUrl, additionalImageUrls);

  /// اولین تصویر برای کارت لیست، کاور کشف، مورد علاقه‌ها
  String get coverImageUrl {
    final urls = allImageUrls;
    return urls.isNotEmpty ? urls.first : '';
  }

  /// همه آدرس ویدیوها بدون تکرار
  List<String> get allVideoUrls => _mergeUrlLists(videoUrl, additionalVideoUrls);

  String get appShortDescription =>
      shortDescription.trim().isNotEmpty ? shortDescription : name;

  String get websiteArticleUrl {
    final slug = richMeta.webSlug.trim();
    if (slug.isNotEmpty) {
      return AppConfig.wordpressPath(slug);
    }
    if (id > 0) {
      return AppConfig.wordpressPath('?p=$id');
    }
    return '';
  }

  String get bodyEngagementDisplay {
    final direct = bodyEngagement.trim();
    if (direct.isNotEmpty) return direct;
    return richMeta.bodyEngagementLabel.trim();
  }

  static List<String> _mergeUrlLists(String primary, List<String> extras) {
    final seen = <String>{};
    final out = <String>[];
    void add(String u) {
      final t = u.trim();
      if (t.isEmpty) return;
      if (seen.add(t)) out.add(t);
    }

    add(primary);
    for (final u in extras) {
      add(u);
    }
    return out;
  }

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
      'additionalImageUrls': additionalImageUrls,
      'additionalVideoUrls': additionalVideoUrls,
      'otherNames': otherNames,
      'content': content,
      'difficulty': difficulty,
      'equipment': equipment,
      'exerciseType': exerciseType,
      'estimatedDuration': estimatedDuration,
      'targetArea': targetArea,
      'tags': tags,
      'detailedDescription': detailedDescription,
      'author': author,
      'createdBy': createdBy,
      'shortDescription': shortDescription,
      'movementPattern': movementPattern,
      'bodyEngagement': bodyEngagement,
      'typicalRpe': typicalRpe,
      'met': met,
      'muscleTargets': muscleTargets,
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
