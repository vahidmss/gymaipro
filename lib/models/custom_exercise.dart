import 'package:gymaipro/models/exercise.dart';

/// مدل تمرین اختصاصی مربی
class CustomExercise {
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
  final String? videoUrl;
  final String? imageUrl;
  final List<String> tips;
  final String visibility; // 'private' or 'public'
  final bool sharedWithClients;
  final bool approved;
  final List<String> tags;
  final List<String> otherNames;
  final int estimatedDuration;
  final int viewsCount;
  final int likesCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomExercise({
    required this.id,
    required this.createdBy,
    required this.title,
    required this.name,
    this.description,
    this.detailedDescription,
    required this.mainMuscle,
    this.secondaryMuscles = '',
    this.difficulty = 'متوسط',
    this.equipment = 'بدون تجهیزات',
    this.exerciseType = 'قدرتی',
    this.targetArea,
    this.videoUrl,
    this.imageUrl,
    this.tips = const [],
    this.visibility = 'private',
    this.sharedWithClients = true,
    this.approved = false,
    this.tags = const [],
    this.otherNames = const [],
    this.estimatedDuration = 0,
    this.viewsCount = 0,
    this.likesCount = 0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomExercise.fromJson(Map<String, dynamic> json) {
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
      videoUrl: json['video_url'] as String?,
      imageUrl: json['image_url'] as String?,
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
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

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
      'video_url': videoUrl,
      'image_url': imageUrl,
      'tips': tips,
      'visibility': visibility,
      'shared_with_clients': sharedWithClients,
      'approved': approved,
      'tags': tags,
      'other_names': otherNames,
      'estimated_duration': estimatedDuration,
      'views_count': viewsCount,
      'likes_count': likesCount,
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
    
    return Exercise(
      id: uniqueId,
      title: title,
      name: name,
      mainMuscle: mainMuscle,
      secondaryMuscles: secondaryMuscles,
      tips: tips,
      videoUrl: videoUrl ?? '',
      imageUrl: imageUrl ?? '',
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
    String? videoUrl,
    String? imageUrl,
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
      videoUrl: videoUrl ?? this.videoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
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

