import 'package:flutter/material.dart';

enum CertificateType {
  coaching, // مربیگری
  championship, // قهرمانی
  education, // تحصیلات
  specialization, // تخصص
  achievement, // دستاورد
  other, // سایر
}

enum CertificateStatus {
  pending, // در انتظار تایید
  approved, // تایید شده
  rejected, // رد شده
}

class Certificate {
  const Certificate({
    required this.id,
    required this.trainerId,
    required this.title,
    required this.description,
    required this.type,
    required this.createdAt,
    required this.updatedAt,
    this.issuingOrganization,
    this.issueDate,
    this.expiryDate,
    this.certificateUrl,
    this.status = CertificateStatus.pending,
    this.rejectionReason,
    this.approvedBy,
    this.approvedAt,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    return Certificate(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: CertificateType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => CertificateType.other,
      ),
      issuingOrganization: json['issuing_organization'] as String?,
      issueDate: json['issue_date'] != null
          ? DateTime.parse(json['issue_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      certificateUrl: json['certificate_url'] as String?,
      status: CertificateStatus.values.firstWhere(
        (e) => e.name == json['status'],
        orElse: () => CertificateStatus.pending,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      approvedBy: json['approved_by'] as String?,
      approvedAt: json['approved_at'] != null
          ? DateTime.parse(json['approved_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.parse(json['created_at'] as String),
    );
  }
  final String id;
  final String trainerId;
  final String title;
  final String description;
  final CertificateType type;
  final String? issuingOrganization;
  final DateTime? issueDate;
  final DateTime? expiryDate;
  final String? certificateUrl;
  final CertificateStatus status;
  final String? rejectionReason;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'title': title,
      'description': description,
      'type': type.name,
      'issuing_organization': issuingOrganization,
      'issue_date': issueDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'certificate_url': certificateUrl,
      'status': status.name,
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
    };
  }

  String get typeDisplayName {
    switch (type) {
      case CertificateType.coaching:
        return 'مربیگری';
      case CertificateType.championship:
        return 'قهرمانی';
      case CertificateType.education:
        return 'تحصیلات';
      case CertificateType.specialization:
        return 'تخصص';
      case CertificateType.achievement:
        return 'دستاورد';
      case CertificateType.other:
        return 'سایر';
    }
  }

  IconData get typeIcon {
    switch (type) {
      case CertificateType.coaching:
        return Icons.sports_martial_arts;
      case CertificateType.championship:
        return Icons.emoji_events;
      case CertificateType.education:
        return Icons.school;
      case CertificateType.specialization:
        return Icons.psychology;
      case CertificateType.achievement:
        return Icons.star;
      case CertificateType.other:
        return Icons.card_membership;
    }
  }

  Color get typeColor {
    switch (type) {
      case CertificateType.coaching:
        return Colors.blue;
      case CertificateType.championship:
        return Colors.amber;
      case CertificateType.education:
        return Colors.green;
      case CertificateType.specialization:
        return Colors.purple;
      case CertificateType.achievement:
        return Colors.orange;
      case CertificateType.other:
        return Colors.grey;
    }
  }

  String get statusDisplayName {
    switch (status) {
      case CertificateStatus.pending:
        return 'در انتظار تایید';
      case CertificateStatus.approved:
        return 'تایید شده';
      case CertificateStatus.rejected:
        return 'رد شده';
    }
  }

  Color get statusColor {
    switch (status) {
      case CertificateStatus.pending:
        return Colors.orange;
      case CertificateStatus.approved:
        return Colors.green;
      case CertificateStatus.rejected:
        return Colors.red;
    }
  }

  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  bool get isExpiringSoon {
    if (expiryDate == null) return false;
    final daysUntilExpiry = expiryDate!.difference(DateTime.now()).inDays;
    return daysUntilExpiry <= 30 && daysUntilExpiry > 0;
  }
}
