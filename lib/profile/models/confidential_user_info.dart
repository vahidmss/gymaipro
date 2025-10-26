// import 'package:cloud_firestore/cloud_firestore.dart'; // Not needed for Supabase

class ConfidentialUserInfo {
  const ConfidentialUserInfo({
    required this.id,
    required this.profileId,
    required this.hasConsented,
    required this.createdAt,
    required this.updatedAt,
    this.consentedAt,
    this.usernameSnapshot,
    this.bodyMeasurements,
    this.healthInfo,
    this.fitnessGoals,
    this.photoAlbum,
    this.trainerVisibility,
  });

  factory ConfidentialUserInfo.fromJson(Map<String, dynamic> json) {
    return ConfidentialUserInfo(
      id: json['id'] as String,
      profileId: json['profile_id'] as String,
      hasConsented: json['has_consented'] as bool,
      consentedAt: json['consented_at'] != null
          ? DateTime.parse(json['consented_at'] as String)
          : null,
      usernameSnapshot: json['username_snapshot'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      bodyMeasurements: json['body_measurements'] != null
          ? BodyMeasurements.fromJson(
              json['body_measurements'] as Map<String, dynamic>,
            )
          : null,
      healthInfo: json['health_info'] != null
          ? HealthInfo.fromJson(json['health_info'] as Map<String, dynamic>)
          : null,
      fitnessGoals: json['fitness_goals'] != null
          ? FitnessGoals.fromJson(json['fitness_goals'] as Map<String, dynamic>)
          : null,
      photoAlbum: json['photo_album'] != null
          ? PhotoAlbum.fromJson(json['photo_album'] as Map<String, dynamic>)
          : null,
      trainerVisibility: json['trainer_visibility'] != null
          ? TrainerVisibilitySettings.fromJson(
              json['trainer_visibility'] as Map<String, dynamic>,
            )
          : null,
    );
  }
  final String id;
  final String profileId;
  final bool hasConsented;
  final DateTime? consentedAt;
  final String? usernameSnapshot;
  final DateTime createdAt;
  final DateTime updatedAt;

  // بخش‌های مختلف اطلاعات محرمانه
  final BodyMeasurements? bodyMeasurements;
  final HealthInfo? healthInfo;
  final FitnessGoals? fitnessGoals;
  final PhotoAlbum? photoAlbum;
  final TrainerVisibilitySettings? trainerVisibility;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'profile_id': profileId,
      'has_consented': hasConsented,
      'consented_at': consentedAt?.toIso8601String(),
      'username_snapshot': usernameSnapshot,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'body_measurements': bodyMeasurements?.toJson(),
      'health_info': healthInfo?.toJson(),
      'fitness_goals': fitnessGoals?.toJson(),
      'photo_album': photoAlbum?.toJson(),
      'trainer_visibility': trainerVisibility?.toJson(),
    };
  }
}

// اندازه‌گیری‌های بدن
class BodyMeasurements {
  const BodyMeasurements({
    this.height,
    this.weight,
    this.bodyFatPercentage,
    this.muscleMass,
    this.chestCircumference,
    this.waistCircumference,
    this.hipCircumference,
    this.armCircumference,
    this.thighCircumference,
    this.neckCircumference,
    this.lastUpdated,
  });

  factory BodyMeasurements.fromJson(Map<String, dynamic> json) {
    return BodyMeasurements(
      height: (json['height'] as num?)?.toDouble(),
      weight: (json['weight'] as num?)?.toDouble(),
      bodyFatPercentage: (json['body_fat_percentage'] as num?)?.toDouble(),
      muscleMass: (json['muscle_mass'] as num?)?.toDouble(),
      chestCircumference: (json['chest_circumference'] as num?)?.toDouble(),
      waistCircumference: (json['waist_circumference'] as num?)?.toDouble(),
      hipCircumference: (json['hip_circumference'] as num?)?.toDouble(),
      armCircumference: (json['arm_circumference'] as num?)?.toDouble(),
      thighCircumference: (json['thigh_circumference'] as num?)?.toDouble(),
      neckCircumference: (json['neck_circumference'] as num?)?.toDouble(),
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }
  final double? height; // قد (سانتی‌متر)
  final double? weight; // وزن (کیلوگرم)
  final double? bodyFatPercentage; // درصد چربی بدن
  final double? muscleMass; // توده عضلانی
  final double? chestCircumference; // دور سینه
  final double? waistCircumference; // دور کمر
  final double? hipCircumference; // دور باسن
  final double? armCircumference; // دور بازو
  final double? thighCircumference; // دور ران
  final double? neckCircumference; // دور گردن
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'height': height,
      'weight': weight,
      'body_fat_percentage': bodyFatPercentage,
      'muscle_mass': muscleMass,
      'chest_circumference': chestCircumference,
      'waist_circumference': waistCircumference,
      'hip_circumference': hipCircumference,
      'arm_circumference': armCircumference,
      'thigh_circumference': thighCircumference,
      'neck_circumference': neckCircumference,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

// اطلاعات سلامت
class HealthInfo {
  const HealthInfo({
    this.medicalConditions = const [],
    this.medications = const [],
    this.allergies = const [],
    this.bloodType,
    this.emergencyContact,
    this.doctorName,
    this.doctorPhone,
    this.notes,
    this.lastUpdated,
  });

  factory HealthInfo.fromJson(Map<String, dynamic> json) {
    return HealthInfo(
      medicalConditions: List<String>.from(
        json['medical_conditions'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      medications: List<String>.from(
        json['medications'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      allergies: List<String>.from(
        json['allergies'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      bloodType: json['blood_type'] as String?,
      emergencyContact: json['emergency_contact'] as String?,
      doctorName: json['doctor_name'] as String?,
      doctorPhone: json['doctor_phone'] as String?,
      notes: json['notes'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }
  final List<String> medicalConditions; // شرایط پزشکی
  final List<String> medications; // داروها
  final List<String> allergies; // آلرژی‌ها
  final String? bloodType; // گروه خونی
  final String? emergencyContact; // تماس اضطراری
  final String? doctorName; // نام پزشک
  final String? doctorPhone; // تلفن پزشک
  final String? notes; // یادداشت‌های اضافی
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'medical_conditions': medicalConditions,
      'medications': medications,
      'allergies': allergies,
      'blood_type': bloodType,
      'emergency_contact': emergencyContact,
      'doctor_name': doctorName,
      'doctor_phone': doctorPhone,
      'notes': notes,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

// اهداف تناسب اندام
class FitnessGoals {
  const FitnessGoals({
    this.primaryGoals = const [],
    this.secondaryGoals = const [],
    this.targetWeight,
    this.targetBodyFat,
    this.targetMuscleMass,
    this.timeline,
    this.motivation,
    this.challenges,
    this.lastUpdated,
  });

  factory FitnessGoals.fromJson(Map<String, dynamic> json) {
    return FitnessGoals(
      primaryGoals: List<String>.from(
        json['primary_goals'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      secondaryGoals: List<String>.from(
        json['secondary_goals'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      targetWeight: json['target_weight'] as String?,
      targetBodyFat: json['target_body_fat'] as String?,
      targetMuscleMass: json['target_muscle_mass'] as String?,
      timeline: json['timeline'] as String?,
      motivation: json['motivation'] as String?,
      challenges: json['challenges'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }
  final List<String> primaryGoals; // اهداف اصلی
  final List<String> secondaryGoals; // اهداف فرعی
  final String? targetWeight; // وزن هدف
  final String? targetBodyFat; // درصد چربی هدف
  final String? targetMuscleMass; // توده عضلانی هدف
  final String? timeline; // زمان‌بندی
  final String? motivation; // انگیزه
  final String? challenges; // چالش‌ها
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'primary_goals': primaryGoals,
      'secondary_goals': secondaryGoals,
      'target_weight': targetWeight,
      'target_body_fat': targetBodyFat,
      'target_muscle_mass': targetMuscleMass,
      'timeline': timeline,
      'motivation': motivation,
      'challenges': challenges,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}

// آلبوم عکس‌ها
class PhotoAlbum {
  // روزهای بین عکس‌ها

  const PhotoAlbum({
    this.photos = const [],
    this.lastPhotoAdded,
    this.maxPhotosPerMonth = 4,
    this.daysBetweenPhotos = 20,
  });

  factory PhotoAlbum.fromJson(Map<String, dynamic> json) {
    return PhotoAlbum(
      photos:
          (json['photos'] as List<dynamic>?)
              ?.map((e) => BodyPhoto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      lastPhotoAdded: json['last_photo_added'] != null
          ? DateTime.parse(json['last_photo_added'] as String)
          : null,
      maxPhotosPerMonth: json['max_photos_per_month'] as int? ?? 4,
      daysBetweenPhotos: json['days_between_photos'] as int? ?? 20,
    );
  }
  final List<BodyPhoto> photos;
  final DateTime? lastPhotoAdded;
  final int maxPhotosPerMonth; // حداکثر عکس در ماه
  final int daysBetweenPhotos;

  // بررسی امکان اضافه کردن عکس جدید
  bool canAddNewPhoto() {
    if (photos.isEmpty) return true;

    final now = DateTime.now();
    final lastPhoto = lastPhotoAdded ?? photos.last.takenAt;
    final daysSinceLastPhoto = now.difference(lastPhoto).inDays;

    return daysSinceLastPhoto >= daysBetweenPhotos;
  }

  // تعداد روزهای باقی‌مانده تا عکس بعدی
  int daysUntilNextPhoto() {
    if (photos.isEmpty) return 0;

    final now = DateTime.now();
    final lastPhoto = lastPhotoAdded ?? photos.last.takenAt;
    final daysSinceLastPhoto = now.difference(lastPhoto).inDays;

    return (daysBetweenPhotos - daysSinceLastPhoto).clamp(0, daysBetweenPhotos);
  }

  Map<String, dynamic> toJson() {
    return {
      'photos': photos.map((e) => e.toJson()).toList(),
      'last_photo_added': lastPhotoAdded?.toIso8601String(),
      'max_photos_per_month': maxPhotosPerMonth,
      'days_between_photos': daysBetweenPhotos,
    };
  }
}

// عکس بدن
class BodyPhoto {
  // سطح مات‌سازی

  const BodyPhoto({
    required this.id,
    required this.url,
    required this.type,
    required this.takenAt,
    this.notes,
    this.isVisibleToTrainer = true,
    this.blurLevel,
  });

  factory BodyPhoto.fromJson(Map<String, dynamic> json) {
    return BodyPhoto(
      id: json['id'] as String,
      url: json['url'] as String,
      type: BodyPhotoType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => BodyPhotoType.front,
      ),
      takenAt: DateTime.parse(json['taken_at'] as String),
      notes: json['notes'] as String?,
      isVisibleToTrainer: json['is_visible_to_trainer'] as bool? ?? true,
      blurLevel: json['blur_level'] as String?,
    );
  }
  final String id;
  final String url;
  final BodyPhotoType type;
  final DateTime takenAt;
  final String? notes;
  final bool isVisibleToTrainer; // قابل نمایش برای مربی
  final String? blurLevel;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'type': type.name,
      'taken_at': takenAt.toIso8601String(),
      'notes': notes,
      'is_visible_to_trainer': isVisibleToTrainer,
      'blur_level': blurLevel,
    };
  }
}

// انواع عکس بدن
enum BodyPhotoType {
  front, // جلو
  side, // کنار
  back, // پشت
  progress, // پیشرفت
  specific, // خاص (مشخص شده توسط کاربر)
}

// تنظیمات نمایش برای مربی
class TrainerVisibilitySettings {
  const TrainerVisibilitySettings({
    this.showBodyMeasurements = true,
    this.showHealthInfo = true,
    this.showFitnessGoals = true,
    this.showPhotos = true,
    this.showProgress = true,
    this.trainerNotes,
    this.lastUpdated,
  });

  factory TrainerVisibilitySettings.fromJson(Map<String, dynamic> json) {
    return TrainerVisibilitySettings(
      showBodyMeasurements: json['show_body_measurements'] as bool? ?? true,
      showHealthInfo: json['show_health_info'] as bool? ?? true,
      showFitnessGoals: json['show_fitness_goals'] as bool? ?? true,
      showPhotos: json['show_photos'] as bool? ?? true,
      showProgress: json['show_progress'] as bool? ?? true,
      trainerNotes: json['trainer_notes'] as String?,
      lastUpdated: json['last_updated'] != null
          ? DateTime.parse(json['last_updated'] as String)
          : null,
    );
  }
  final bool showBodyMeasurements;
  final bool showHealthInfo;
  final bool showFitnessGoals;
  final bool showPhotos;
  final bool showProgress;
  final String? trainerNotes; // یادداشت‌های مربی
  final DateTime? lastUpdated;

  Map<String, dynamic> toJson() {
    return {
      'show_body_measurements': showBodyMeasurements,
      'show_health_info': showHealthInfo,
      'show_fitness_goals': showFitnessGoals,
      'show_photos': showPhotos,
      'show_progress': showProgress,
      'trainer_notes': trainerNotes,
      'last_updated': lastUpdated?.toIso8601String(),
    };
  }
}
