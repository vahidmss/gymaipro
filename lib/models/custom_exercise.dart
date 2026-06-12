import 'dart:convert';

import 'package:gymaipro/models/exercise.dart';
import 'package:gymaipro/models/muscle_targets.dart';

/// یک ستون TEXT که یا یک URL است یا JSON آرایهٔ URLها (چند رسانه بدون ستون جدا)
List<String> _parseCustomExerciseUrlList(dynamic raw) {
  if (raw == null) return [];
  if (raw is List) {
    return raw
        .map((e) => e.toString().trim())
        .where((s) => s.isNotEmpty)
        .toList();
  }
  if (raw is String) {
    final t = raw.trim();
    if (t.isEmpty) return [];
    if (t.startsWith('[')) {
      try {
        final decoded = jsonDecode(t);
        if (decoded is List) {
          return decoded
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
        }
      } catch (_) {}
      return [];
    }
    return [t];
  }
  return [];
}

List<String> _dedupeCustomExerciseUrls(List<String> urls) {
  final seen = <String>{};
  return urls.where((u) => u.isNotEmpty).where(seen.add).toList();
}

String? _encodeCustomExerciseUrlColumn(List<String> urls) {
  if (urls.isEmpty) return null;
  if (urls.length == 1) return urls.first;
  return jsonEncode(urls);
}

/// مدل تمرین اختصاصی مربی
class CustomExercise {

  CustomExercise({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.name,
    required this.mainMuscle, required this.createdAt, required this.updatedAt, this.description,
    this.detailedDescription,
    this.secondaryMuscles = '',
    this.difficulty = 'متوسط',
    this.equipment = 'بدون تجهیزات',
    this.exerciseType = 'قدرتی',
    this.targetArea,
    this.imageUrls = const [],
    this.videoUrls = const [],
    this.tips = const [],
    this.visibility = 'private',
    this.sharedWithClients = true,
    this.approved = false,
    this.tags = const [],
    this.otherNames = const [],
    this.estimatedDuration = 0,
    this.viewsCount = 0,
    this.likesCount = 0,
    this.muscleTargets = const {},
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
    final imageUrls = _dedupeCustomExerciseUrls([
      ..._parseCustomExerciseUrlList(json['image_url']),
      ..._parseCustomExerciseUrlList(json['image_urls']),
    ]);
    final videoUrls = _dedupeCustomExerciseUrls([
      ..._parseCustomExerciseUrlList(json['video_url']),
      ..._parseCustomExerciseUrlList(json['video_urls']),
    ]);

    return CustomExercise(
      id: json['id'] as String,
      createdBy: json['created_by'] as String,
      title: json['title'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      detailedDescription: json['detailed_description'] as String?,
      mainMuscle: json['main_muscle'] as String? ?? '',
      secondaryMuscles: json['secondary_muscles'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'متوسط',
      equipment: json['equipment'] as String? ?? 'بدون تجهیزات',
      exerciseType: json['exercise_type'] as String? ?? 'قدرتی',
      targetArea: json['target_area'] as String?,
      imageUrls: imageUrls,
      videoUrls: videoUrls,
      tips: json['tips'] != null
          ? List<String>.from(json['tips'] as List)
          : [],
      visibility: json['visibility'] as String? ?? 'private',
      sharedWithClients: json['shared_with_clients'] as bool? ?? true,
      approved: json['approved'] as bool? ?? false,
      tags: json['tags'] != null
          ? List<String>.from(json['tags'] as List)
          : [],
      otherNames: json['other_names'] != null
          ? List<String>.from(json['other_names'] as List)
          : [],
      estimatedDuration: json['estimated_duration'] as int? ?? 0,
      viewsCount: json['views_count'] as int? ?? 0,
      likesCount: json['likes_count'] as int? ?? 0,
      muscleTargets: MuscleTargets.parse(
        json['muscle_targets_json'] ?? json['muscle_targets'],
      ),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String createdBy;
  final String title;
  final String name;
  final String? description;
  final String? detailedDescription;
  final String mainMuscle;
  final String secondaryMuscles;
  final String difficulty;
  final String equipment;
  final String exerciseType;
  final String? targetArea;
  /// آدرس تصاویر (به ترتیب نمایش)
  final List<String> imageUrls;
  /// آدرس ویدیوها (به ترتیب نمایش)
  final List<String> videoUrls;
  final List<String> tips;
  final String visibility; // 'private' or 'public'
  final bool sharedWithClients;
  final bool approved;
  final List<String> tags;
  final List<String> otherNames;
  final int estimatedDuration;
  final int viewsCount;
  final int likesCount;
  final Map<String, int> muscleTargets;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_by': createdBy,
      'title': title,
      'name': name,
      'description': description,
      'detailed_description': detailedDescription,
      'main_muscle': mainMuscle,
      'secondary_muscles': secondaryMuscles,
      'difficulty': difficulty,
      'equipment': equipment,
      'exercise_type': exerciseType,
      'target_area': targetArea,
      'video_url': _encodeCustomExerciseUrlColumn(videoUrls),
      'image_url': _encodeCustomExerciseUrlColumn(imageUrls),
      'tips': tips,
      'visibility': visibility,
      'shared_with_clients': sharedWithClients,
      'approved': approved,
      'tags': tags,
      'other_names': otherNames,
      'estimated_duration': estimatedDuration,
      'views_count': viewsCount,
      'likes_count': likesCount,
      if (MuscleTargets.hasData(muscleTargets))
        'muscle_targets_json': jsonEncode(muscleTargets),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// تبدیل به Exercise برای استفاده در سیستم موجود
  /// ID منحصر به فرد از UUID ساخته می‌شه تا با تمرین‌های اصلی تداخل نداشته باشه
  Exercise toExercise({String? authorName}) {
    // ساخت ID منحصر به فرد از UUID (اولین 8 کاراکتر hex رو به int تبدیل می‌کنیم)
    // این باعث می‌شه ID منحصر به فرد باشه و با تمرین‌های WordPress تداخل نداشته باشه
    // استفاده از عدد بزرگ برای تشخیص تمرین‌های اختصاصی
    final uniqueId = int.tryParse(
      id.replaceAll('-', '').substring(0, 8),
      radix: 16,
    ) ?? 999999999; // اگر تبدیل نشد، یک عدد بزرگ استفاده می‌کنیم
    
    // اضافه کردن برچسب "اختصاصی" به عنوان other name برای تشخیص
    final otherNamesWithTag = [
      ...otherNames,
      if (!otherNames.contains('اختصاصی')) 'اختصاصی',
    ];
    
    final firstVid = videoUrls.isNotEmpty ? videoUrls.first : '';
    final firstImg = imageUrls.isNotEmpty ? imageUrls.first : '';
    final restVid =
        videoUrls.length > 1 ? videoUrls.sublist(1) : const <String>[];
    final restImg =
        imageUrls.length > 1 ? imageUrls.sublist(1) : const <String>[];

    return Exercise(
      id: uniqueId,
      title: title,
      name: name,
      mainMuscle: mainMuscle,
      secondaryMuscles: secondaryMuscles,
      tips: tips,
      videoUrl: firstVid,
      imageUrl: firstImg,
      additionalVideoUrls: restVid,
      additionalImageUrls: restImg,
      otherNames: otherNamesWithTag,
      content: description ?? detailedDescription ?? '',
      difficulty: difficulty,
      equipment: equipment,
      exerciseType: exerciseType,
      estimatedDuration: estimatedDuration,
      targetArea: targetArea ?? mainMuscle,
      tags: [
        ...tags,
        'اختصاصی',
        if (visibility == 'public') 'عمومی',
      ],
      detailedDescription: detailedDescription ?? '',
      author: authorName,
      createdBy: createdBy,
    );
  }

  CustomExercise copyWith({
    String? id,
    String? createdBy,
    String? title,
    String? name,
    String? description,
    String? detailedDescription,
    String? mainMuscle,
    String? secondaryMuscles,
    String? difficulty,
    String? equipment,
    String? exerciseType,
    String? targetArea,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<String>? tips,
    String? visibility,
    bool? sharedWithClients,
    bool? approved,
    List<String>? tags,
    List<String>? otherNames,
    int? estimatedDuration,
    int? viewsCount,
    int? likesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CustomExercise(
      id: id ?? this.id,
      createdBy: createdBy ?? this.createdBy,
      title: title ?? this.title,
      name: name ?? this.name,
      description: description ?? this.description,
      detailedDescription: detailedDescription ?? this.detailedDescription,
      mainMuscle: mainMuscle ?? this.mainMuscle,
      secondaryMuscles: secondaryMuscles ?? this.secondaryMuscles,
      difficulty: difficulty ?? this.difficulty,
      equipment: equipment ?? this.equipment,
      exerciseType: exerciseType ?? this.exerciseType,
      targetArea: targetArea ?? this.targetArea,
      imageUrls: imageUrls ?? this.imageUrls,
      videoUrls: videoUrls ?? this.videoUrls,
      tips: tips ?? this.tips,
      visibility: visibility ?? this.visibility,
      sharedWithClients: sharedWithClients ?? this.sharedWithClients,
      approved: approved ?? this.approved,
      tags: tags ?? this.tags,
      otherNames: otherNames ?? this.otherNames,
      estimatedDuration: estimatedDuration ?? this.estimatedDuration,
      viewsCount: viewsCount ?? this.viewsCount,
      likesCount: likesCount ?? this.likesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
