class TrainerRanking {
  TrainerRanking({
    required this.id,
    required this.trainerId,
    required this.trainerName,
    required this.rating,
    required this.reviewCount,
    required this.studentCount,
    required this.experienceYears,
    required this.specializations,
    required this.certificates,
    required this.isOnline,
    required this.lastActiveAt,
    required this.hourlyRate,
    required this.ranking,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.bio,
    this.phoneNumber,
    this.email,
  });

  factory TrainerRanking.fromJson(Map<String, dynamic> json) {
    return TrainerRanking(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      trainerName: json['trainer_name'] as String,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      rating: (json['rating'] as num).toDouble(),
      reviewCount: (json['review_count'] as int?) ?? 0,
      studentCount: (json['student_count'] as int?) ?? 0,
      experienceYears: (json['experience_years'] as int?) ?? 0,
      specializations: List<String>.from(
        json['specializations'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      certificates: List<String>.from(
        json['certificates'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      isOnline: (json['is_online'] as bool?) ?? false,
      lastActiveAt: DateTime.parse(json['last_active_at'] as String),
      hourlyRate: (json['hourly_rate'] as num).toDouble(),
      phoneNumber: json['phone_number'] as String?,
      email: json['email'] as String?,
      ranking: (json['ranking'] as int?) ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  final String id;
  final String trainerId;
  final String trainerName;
  final String? avatarUrl;
  final String? bio;
  final double rating;
  final int reviewCount;
  final int studentCount;
  final int experienceYears;
  final List<String> specializations;
  final List<String> certificates;
  final bool isOnline;
  final DateTime lastActiveAt;
  final double hourlyRate;
  final String? phoneNumber;
  final String? email;
  final int ranking;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'trainer_name': trainerName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'rating': rating,
      'review_count': reviewCount,
      'student_count': studentCount,
      'experience_years': experienceYears,
      'specializations': specializations,
      'certificates': certificates,
      'is_online': isOnline,
      'last_active_at': lastActiveAt.toIso8601String(),
      'hourly_rate': hourlyRate,
      'phone_number': phoneNumber,
      'email': email,
      'ranking': ranking,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TrainerRanking copyWith({
    String? id,
    String? trainerId,
    String? trainerName,
    String? avatarUrl,
    String? bio,
    double? rating,
    int? reviewCount,
    int? studentCount,
    int? experienceYears,
    List<String>? specializations,
    List<String>? certificates,
    bool? isOnline,
    DateTime? lastActiveAt,
    double? hourlyRate,
    String? phoneNumber,
    String? email,
    int? ranking,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerRanking(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      trainerName: trainerName ?? this.trainerName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      studentCount: studentCount ?? this.studentCount,
      experienceYears: experienceYears ?? this.experienceYears,
      specializations: specializations ?? this.specializations,
      certificates: certificates ?? this.certificates,
      isOnline: isOnline ?? this.isOnline,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      ranking: ranking ?? this.ranking,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TrainerReview {
  TrainerReview({
    required this.id,
    required this.trainerId,
    required this.userId,
    required this.studentName,
    required this.rating,
    required this.comment,
    required this.createdAt,
    this.userAvatar,
    this.userFullName,
    this.isVerifiedStudent = false,
    this.studentSince,
  });

  factory TrainerReview.fromJson(Map<String, dynamic> json) {
    return TrainerReview(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      userId: json['user_id'] as String,
      studentName:
          json['student_name'] as String? ??
          json['user_full_name'] as String? ??
          'کاربر',
      rating: (json['rating'] as num).toDouble(),
      comment:
          (json['comment'] as String?) ?? (json['review'] as String?) ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      userAvatar: json['user_avatar'] as String?,
      userFullName: json['user_full_name'] as String?,
      isVerifiedStudent: (json['is_verified_student'] as bool?) ?? false,
      studentSince: json['student_since'] != null
          ? DateTime.parse(json['student_since'] as String)
          : null,
    );
  }
  final String id;
  final String trainerId;
  final String userId;
  final String studentName;
  final double rating;
  final String comment;
  final DateTime createdAt;
  final String? userAvatar;
  final String? userFullName;
  final bool isVerifiedStudent;
  final DateTime? studentSince;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'user_id': userId,
      'student_name': studentName,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
      'user_avatar': userAvatar,
      'user_full_name': userFullName,
      'is_verified_student': isVerifiedStudent,
      'student_since': studentSince?.toIso8601String(),
    };
  }
}
