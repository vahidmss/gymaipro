import 'dart:convert';

/// مدل تنظیمات کمیسیون
class CommissionSettings {
  const CommissionSettings({
    required this.id,
    required this.commissionPercentage,
    required this.holdDays,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.createdBy,
  });

  factory CommissionSettings.fromJson(Map<String, dynamic> json) {
    return CommissionSettings(
      id: json['id'] as String,
      commissionPercentage: (json['commission_percentage'] as num).toDouble(),
      holdDays: json['hold_days'] as int,
      isActive: json['is_active'] as bool? ?? true,
      createdBy: json['created_by'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// شناسه تنظیمات
  final String id;

  /// درصد کمیسیون (0-100)
  final double commissionPercentage;

  /// تعداد روزهای انتظار قبل از قابل برداشت شدن
  final int holdDays;

  /// آیا تنظیمات فعال است؟
  final bool isActive;

  /// شناسه کاربر ایجادکننده
  final String? createdBy;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'commission_percentage': commissionPercentage,
      'hold_days': holdDays,
      'is_active': isActive,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  CommissionSettings copyWith({
    String? id,
    double? commissionPercentage,
    int? holdDays,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return CommissionSettings(
      id: id ?? this.id,
      commissionPercentage: commissionPercentage ?? this.commissionPercentage,
      holdDays: holdDays ?? this.holdDays,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// فرمت درصد کمیسیون
  String get formattedPercentage => '${commissionPercentage.toStringAsFixed(1)}%';

  @override
  String toString() {
    return 'CommissionSettings{percentage: $formattedPercentage, holdDays: $holdDays}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CommissionSettings &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

