import 'dart:convert';

class TrainerDetail {
  final String id;
  final List<String>? specialties;
  final int? experienceYears;
  final List<String>? certifications;
  final String? education;
  final double? hourlyRate;
  final Map<String, dynamic>? availability;
  final String? bioExtended;
  final DateTime createdAt;
  final DateTime updatedAt;

  TrainerDetail({
    required this.id,
    this.specialties,
    this.experienceYears,
    this.certifications,
    this.education,
    this.hourlyRate,
    this.availability,
    this.bioExtended,
    required this.createdAt,
    required this.updatedAt,
  });

  factory TrainerDetail.fromJson(Map<String, dynamic> json) {
    return TrainerDetail(
      id: json['id'],
      specialties: json['specialties'] != null
          ? List<String>.from(json['specialties'])
          : null,
      experienceYears: json['experience_years'],
      certifications: json['certifications'] != null
          ? List<String>.from(json['certifications'])
          : null,
      education: json['education'],
      hourlyRate: json['hourly_rate'] != null
          ? double.tryParse(json['hourly_rate'].toString())
          : null,
      availability: json['availability'] != null
          ? (json['availability'] is String
              ? jsonDecode(json['availability'])
              : json['availability'])
          : null,
      bioExtended: json['bio_extended'],
      createdAt: DateTime.parse(json['created_at']),
      updatedAt: DateTime.parse(json['updated_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'specialties': specialties,
      'experience_years': experienceYears,
      'certifications': certifications,
      'education': education,
      'hourly_rate': hourlyRate,
      'availability': availability,
      'bio_extended': bioExtended,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  TrainerDetail copyWith({
    String? id,
    List<String>? specialties,
    int? experienceYears,
    List<String>? certifications,
    String? education,
    double? hourlyRate,
    Map<String, dynamic>? availability,
    String? bioExtended,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerDetail(
      id: id ?? this.id,
      specialties: specialties ?? this.specialties,
      experienceYears: experienceYears ?? this.experienceYears,
      certifications: certifications ?? this.certifications,
      education: education ?? this.education,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      availability: availability ?? this.availability,
      bioExtended: bioExtended ?? this.bioExtended,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
