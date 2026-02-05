import 'package:uuid/uuid.dart';

/// مدل تحلیل پیشرفت
class ProgressAnalysis {
  ProgressAnalysis({
    required this.userId,
    required this.analysisResult,
    required this.periodDays,
    required this.analysisDate,
    String? id,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? DateTime.now();

  factory ProgressAnalysis.fromJson(Map<String, dynamic> json) {
    return ProgressAnalysis(
      id: json['id'] as String?,
      userId: json['user_id'] as String,
      analysisResult: json['analysis_result'] as String,
      periodDays: json['period_days'] as int,
      analysisDate: DateTime.parse(json['analysis_date'] as String),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  factory ProgressAnalysis.fromLocalMap(Map<String, dynamic> map) {
    return ProgressAnalysis(
      id: map['id'] as String?,
      userId: map['user_id'] as String,
      analysisResult: map['analysis_result'] as String,
      periodDays: map['period_days'] as int,
      analysisDate: DateTime.parse(map['analysis_date'] as String),
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : null,
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : null,
    );
  }

  final String id;
  final String userId;
  final String analysisResult;
  final int periodDays;
  final DateTime analysisDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'analysis_result': analysisResult,
      'period_days': periodDays,
      'analysis_date': analysisDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'id': id,
      'user_id': userId,
      'analysis_result': analysisResult,
      'period_days': periodDays,
      'analysis_date': analysisDate.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  ProgressAnalysis copyWith({
    String? id,
    String? userId,
    String? analysisResult,
    int? periodDays,
    DateTime? analysisDate,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ProgressAnalysis(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      analysisResult: analysisResult ?? this.analysisResult,
      periodDays: periodDays ?? this.periodDays,
      analysisDate: analysisDate ?? this.analysisDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

