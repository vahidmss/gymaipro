class UserProfile {
  UserProfile({
    required this.username,
    this.id,
    this.phoneNumber,
    this.firstName,
    this.lastName,
    this.avatarUrl,
    this.bio,
    this.birthDate,
    this.height,
    this.weight,
    this.armCircumference,
    this.chestCircumference,
    this.waistCircumference,
    this.hipCircumference,
    this.experienceLevel,
    this.preferredTrainingDays,
    this.preferredTrainingTime,
    this.fitnessGoals,
    this.medicalConditions,
    this.dietaryPreferences,
    this.gender,
    this.role = 'athlete',
    this.weightHistory,
    this.createdAt,
    this.updatedAt,
    this.lastSeenAt,
    this.isOnline,
    // فیلدهای trainer
    this.specializations,
    this.certificates,
    this.hourlyRate,
    this.rating,
    this.reviewCount,
    this.studentCount,
    this.activeStudentCount,
    this.experienceYears,
    this.ranking,
    this.lastActiveAt,
    this.phoneNumberPublic,
    this.emailPublic,
    this.isGymOwner,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as String? ?? '',
      username: (json['username'] as String?) ?? '', // Added username mapping
      phoneNumber: json['phone_number'] as String?,
      firstName: json['first_name'] as String?,
      lastName: json['last_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      bio: json['bio'] as String?,
      birthDate:
          (json['birth_date'] != null &&
              (json['birth_date'] as String).isNotEmpty)
          ? DateTime.tryParse(json['birth_date'] as String)
          : null,
      height: (json['height'] != null && json['height'].toString().isNotEmpty)
          ? double.tryParse(json['height'].toString())
          : null,
      weight: (json['weight'] != null && json['weight'].toString().isNotEmpty)
          ? double.tryParse(json['weight'].toString())
          : null,
      armCircumference:
          (json['arm_circumference'] != null &&
              json['arm_circumference'].toString().isNotEmpty)
          ? double.tryParse(json['arm_circumference'].toString())
          : null,
      chestCircumference:
          (json['chest_circumference'] != null &&
              json['chest_circumference'].toString().isNotEmpty)
          ? double.tryParse(json['chest_circumference'].toString())
          : null,
      waistCircumference:
          (json['waist_circumference'] != null &&
              json['waist_circumference'].toString().isNotEmpty)
          ? double.tryParse(json['waist_circumference'].toString())
          : null,
      hipCircumference:
          (json['hip_circumference'] != null &&
              json['hip_circumference'].toString().isNotEmpty)
          ? double.tryParse(json['hip_circumference'].toString())
          : null,
      experienceLevel: json['experience_level'] as String?, // Fixed field name
      preferredTrainingDays: json['preferred_training_days'] != null
          ? List<String>.from(
              json['preferred_training_days'] as Iterable<dynamic>,
            )
          : null,
      preferredTrainingTime: json['preferred_training_time'] as String?,
      fitnessGoals: json['fitness_goals'] != null
          ? List<String>.from(json['fitness_goals'] as Iterable<dynamic>)
          : null,
      medicalConditions: json['medical_conditions'] != null
          ? List<String>.from(json['medical_conditions'] as Iterable<dynamic>)
          : null,
      dietaryPreferences: json['dietary_preferences'] != null
          ? List<String>.from(json['dietary_preferences'] as Iterable<dynamic>)
          : null,
      gender: json['gender'] as String?,
      role: (json['role'] as String?) ?? 'athlete',
      weightHistory: json['weight_history'] != null
          ? List<Map<String, dynamic>>.from(
              json['weight_history'] as Iterable<dynamic>,
            )
          : null,
      createdAt:
          json['created_at'] != null && json['created_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      updatedAt:
          json['updated_at'] != null && json['updated_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['updated_at'] as String)
          : null,
      lastSeenAt:
          json['last_seen_at'] != null &&
              json['last_seen_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['last_seen_at'] as String)
          : null,
      isOnline: json['is_online'] as bool?,
      // فیلدهای trainer
      specializations: json['specializations'] != null
          ? List<String>.from(json['specializations'] as Iterable<dynamic>)
          : null,
      certificates: json['certificates'] != null
          ? List<String>.from(json['certificates'] as Iterable<dynamic>)
          : null,
      hourlyRate:
          (json['hourly_rate'] != null &&
              json['hourly_rate'].toString().isNotEmpty)
          ? double.tryParse(json['hourly_rate'].toString())
          : null,
      rating: (json['rating'] != null && json['rating'].toString().isNotEmpty)
          ? double.tryParse(json['rating'].toString())
          : null,
      reviewCount: json['review_count'] as int?,
      studentCount: json['student_count'] as int?,
      experienceYears: json['experience_years'] as int?,
      ranking: json['ranking'] as int?,
      lastActiveAt:
          json['last_active_at'] != null &&
              json['last_active_at'].toString().isNotEmpty
          ? DateTime.tryParse(json['last_active_at'] as String)
          : null,
      phoneNumberPublic: json['phone_number_public'] as String?,
      emailPublic: json['email_public'] as String?,
      isGymOwner: json['is_gym_owner'] as bool?,
    );
  }
  final String? id;
  final String username; // Added username field
  final String? phoneNumber;
  final String? firstName;
  final String? lastName;
  final String? avatarUrl;
  final String? bio;
  final DateTime? birthDate;
  final double? height;
  final double? weight;
  final double? armCircumference;
  final double? chestCircumference;
  final double? waistCircumference;
  final double? hipCircumference;
  final String? experienceLevel;
  final List<String>? preferredTrainingDays;
  final String? preferredTrainingTime;
  final List<String>? fitnessGoals;
  final List<String>? medicalConditions;
  final List<String>? dietaryPreferences;
  final String? gender;
  final String role;
  final List<Map<String, dynamic>>? weightHistory;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? lastSeenAt;
  final bool? isOnline;

  // فیلدهای مربوط به trainer
  final List<String>? specializations;
  final List<String>? certificates;
  final double? hourlyRate;
  final double? rating;
  final int? reviewCount;
  final int? studentCount;
  final int? activeStudentCount;
  final int? experienceYears;
  final int? ranking;
  final DateTime? lastActiveAt;
  final String? phoneNumberPublic;
  final String? emailPublic;
  final bool? isGymOwner;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username, // Added username to JSON
      'phone_number': phoneNumber,
      'first_name': firstName,
      'last_name': lastName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'birth_date': birthDate?.toIso8601String(),
      'height': height,
      'weight': weight,
      'arm_circumference': armCircumference,
      'chest_circumference': chestCircumference,
      'waist_circumference': waistCircumference,
      'hip_circumference': hipCircumference,
      'experience_level': experienceLevel, // Fixed field name
      'preferred_training_days': preferredTrainingDays,
      'preferred_training_time': preferredTrainingTime,
      'fitness_goals': fitnessGoals,
      'medical_conditions': medicalConditions,
      'dietary_preferences': dietaryPreferences,
      'gender': gender,
      'role': role,
      'weight_history': weightHistory, // Added weight_history
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'last_seen_at': lastSeenAt?.toIso8601String(),
      'is_online': isOnline,
      // فیلدهای trainer
      'specializations': specializations,
      'certificates': certificates,
      'hourly_rate': hourlyRate,
      'rating': rating,
      'review_count': reviewCount,
      'student_count': studentCount,
      'experience_years': experienceYears,
      'ranking': ranking,
      'last_active_at': lastActiveAt?.toIso8601String(),
      'phone_number_public': phoneNumberPublic,
      'email_public': emailPublic,
      'is_gym_owner': isGymOwner,
    };
  }

  UserProfile copyWith({
    String? id,
    String? username, // Added username
    String? phoneNumber,
    String? firstName,
    String? lastName,
    String? avatarUrl,
    String? bio,
    DateTime? birthDate,
    double? height,
    double? weight,
    double? armCircumference,
    double? chestCircumference,
    double? waistCircumference,
    double? hipCircumference,
    String? experienceLevel,
    List<String>? preferredTrainingDays,
    String? preferredTrainingTime,
    List<String>? fitnessGoals,
    List<String>? medicalConditions,
    List<String>? dietaryPreferences,
    String? gender,
    String? role,
    List<Map<String, dynamic>>? weightHistory,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastSeenAt,
    bool? isOnline,
    // فیلدهای trainer
    List<String>? specializations,
    List<String>? certificates,
    double? hourlyRate,
    double? rating,
    int? reviewCount,
    int? studentCount,
    int? activeStudentCount,
    int? experienceYears,
    int? ranking,
    DateTime? lastActiveAt,
    String? phoneNumberPublic,
    String? emailPublic,
    bool? isGymOwner,
  }) {
    return UserProfile(
      id: id ?? this.id,
      username: username ?? this.username, // Added username
      phoneNumber: phoneNumber ?? this.phoneNumber,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      birthDate: birthDate ?? this.birthDate,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      armCircumference: armCircumference ?? this.armCircumference,
      chestCircumference: chestCircumference ?? this.chestCircumference,
      waistCircumference: waistCircumference ?? this.waistCircumference,
      hipCircumference: hipCircumference ?? this.hipCircumference,
      experienceLevel: experienceLevel ?? this.experienceLevel,
      preferredTrainingDays:
          preferredTrainingDays ?? this.preferredTrainingDays,
      preferredTrainingTime:
          preferredTrainingTime ?? this.preferredTrainingTime,
      fitnessGoals: fitnessGoals ?? this.fitnessGoals,
      medicalConditions: medicalConditions ?? this.medicalConditions,
      dietaryPreferences: dietaryPreferences ?? this.dietaryPreferences,
      gender: gender ?? this.gender,
      role: role ?? this.role,
      weightHistory: weightHistory ?? this.weightHistory,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
      isOnline: isOnline ?? this.isOnline,
      // فیلدهای trainer
      specializations: specializations ?? this.specializations,
      certificates: certificates ?? this.certificates,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      studentCount: studentCount ?? this.studentCount,
      activeStudentCount: activeStudentCount ?? this.activeStudentCount,
      experienceYears: experienceYears ?? this.experienceYears,
      ranking: ranking ?? this.ranking,
      lastActiveAt: lastActiveAt ?? this.lastActiveAt,
      phoneNumberPublic: phoneNumberPublic ?? this.phoneNumberPublic,
      emailPublic: emailPublic ?? this.emailPublic,
      isGymOwner: isGymOwner ?? this.isGymOwner,
    );
  }

  String get fullName => [
    firstName,
    lastName,
  ].where((element) => element != null && element.isNotEmpty).join(' ');

  bool get isProfileComplete {
    final requiredFields = [
      firstName,
      lastName,
      height,
      weight,
      birthDate,
      experienceLevel,
    ];

    return requiredFields.every((field) => field != null);
  }

  bool get isTrainer => role == 'trainer';

  bool get isAdmin => role == 'admin';

  bool get isAthlete => role == 'athlete';
}
