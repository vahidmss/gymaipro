import 'dart:convert';

/// وضعیت درخواست برداشت
enum PayoutRequestStatus {
  pending, // در انتظار بررسی
  approved, // تایید شده
  rejected, // رد شده
  completed, // پرداخت شده
}

/// مدل درخواست برداشت
class PayoutRequest {
  const PayoutRequest({
    required this.id,
    required this.trainerId,
    required this.amount,
    required this.status,
    required this.cardNumber,
    required this.cardOwnerName,
    required this.createdAt,
    this.finalAmount,
    this.bankName,
    this.penaltyAmount = 0,
    this.penaltyReason,
    this.adminNotes,
    this.reviewedBy,
    this.reviewedAt,
    this.completedAt,
    this.updatedAt,
  });

  factory PayoutRequest.fromJson(Map<String, dynamic> json) {
    return PayoutRequest(
      id: json['id'] as String,
      trainerId: json['trainer_id'] as String,
      amount: json['amount'] as int,
      finalAmount: json['final_amount'] as int?,
      cardNumber: json['card_number'] as String,
      cardOwnerName: json['card_owner_name'] as String,
      bankName: json['bank_name'] as String?,
      status: PayoutRequestStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => PayoutRequestStatus.pending,
      ),
      penaltyAmount: json['penalty_amount'] as int? ?? 0,
      penaltyReason: json['penalty_reason'] as String?,
      adminNotes: json['admin_notes'] as String?,
      reviewedBy: json['reviewed_by'] as String?,
      reviewedAt: json['reviewed_at'] != null
          ? DateTime.parse(json['reviewed_at'] as String)
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// شناسه درخواست
  final String id;

  /// شناسه مربی
  final String trainerId;

  /// مبلغ درخواستی (ریال)
  final int amount;

  /// مبلغ نهایی بعد از جریمه (ریال)
  final int? finalAmount;

  /// شماره کارت
  final String cardNumber;

  /// نام صاحب کارت
  final String cardOwnerName;

  /// نام بانک
  final String? bankName;

  /// وضعیت درخواست
  final PayoutRequestStatus status;

  /// مبلغ جریمه (ریال)
  final int penaltyAmount;

  /// دلیل جریمه
  final String? penaltyReason;

  /// یادداشت ادمین
  final String? adminNotes;

  /// شناسه کاربر بررسی‌کننده
  final String? reviewedBy;

  /// تاریخ بررسی
  final DateTime? reviewedAt;

  /// تاریخ تکمیل
  final DateTime? completedAt;

  /// تاریخ به‌روزرسانی
  final DateTime? updatedAt;

  /// تاریخ ایجاد
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'trainer_id': trainerId,
      'amount': amount,
      'final_amount': finalAmount,
      'card_number': cardNumber,
      'card_owner_name': cardOwnerName,
      'bank_name': bankName,
      'status': status.toString().split('.').last,
      'penalty_amount': penaltyAmount,
      'penalty_reason': penaltyReason,
      'admin_notes': adminNotes,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  PayoutRequest copyWith({
    String? id,
    String? trainerId,
    int? amount,
    int? finalAmount,
    String? cardNumber,
    String? cardOwnerName,
    String? bankName,
    PayoutRequestStatus? status,
    int? penaltyAmount,
    String? penaltyReason,
    String? adminNotes,
    String? reviewedBy,
    DateTime? reviewedAt,
    DateTime? completedAt,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return PayoutRequest(
      id: id ?? this.id,
      trainerId: trainerId ?? this.trainerId,
      amount: amount ?? this.amount,
      finalAmount: finalAmount ?? this.finalAmount,
      cardNumber: cardNumber ?? this.cardNumber,
      cardOwnerName: cardOwnerName ?? this.cardOwnerName,
      bankName: bankName ?? this.bankName,
      status: status ?? this.status,
      penaltyAmount: penaltyAmount ?? this.penaltyAmount,
      penaltyReason: penaltyReason ?? this.penaltyReason,
      adminNotes: adminNotes ?? this.adminNotes,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      completedAt: completedAt ?? this.completedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// مبلغ نهایی (بعد از جریمه) یا مبلغ اصلی
  int get effectiveAmount => finalAmount ?? amount;

  /// فرمت مبلغ درخواستی به تومان
  String get formattedAmount => '${(amount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ نهایی به تومان
  String get formattedFinalAmount =>
      '${(effectiveAmount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ جریمه به تومان
  String get formattedPenaltyAmount =>
      penaltyAmount > 0 ? '${(penaltyAmount / 10).toStringAsFixed(0)} تومان' : 'بدون جریمه';

  /// متن وضعیت به فارسی
  String get statusText {
    switch (status) {
      case PayoutRequestStatus.pending:
        return 'در انتظار بررسی';
      case PayoutRequestStatus.approved:
        return 'تایید شده';
      case PayoutRequestStatus.rejected:
        return 'رد شده';
      case PayoutRequestStatus.completed:
        return 'پرداخت شده';
    }
  }

  /// رنگ وضعیت
  String get statusColor {
    switch (status) {
      case PayoutRequestStatus.pending:
        return '#FF9800'; // نارنجی
      case PayoutRequestStatus.approved:
        return '#2196F3'; // آبی
      case PayoutRequestStatus.rejected:
        return '#F44336'; // قرمز
      case PayoutRequestStatus.completed:
        return '#4CAF50'; // سبز
    }
  }

  /// آیا درخواست قابل ویرایش است؟
  bool get isEditable => status == PayoutRequestStatus.pending;

  /// آیا درخواست تایید شده است؟
  bool get isApproved => status == PayoutRequestStatus.approved;

  /// آیا درخواست رد شده است؟
  bool get isRejected => status == PayoutRequestStatus.rejected;

  /// آیا درخواست پرداخت شده است؟
  bool get isCompleted => status == PayoutRequestStatus.completed;

  /// آیا جریمه دارد؟
  bool get hasPenalty => penaltyAmount > 0;

  /// نمایش شماره کارت (فقط 4 رقم آخر)
  /// اگر cardNumber hash شده باشد، 4 رقم آخر رو برمیگردونه
  String get maskedCardNumber {
    if (cardNumber.length <= 4) return cardNumber;
    // اگر hash شده (16 کاراکتر hash + 4 رقم)، فقط 4 رقم آخر رو نمایش بده
    if (cardNumber.length == 20) {
      return '****${cardNumber.substring(16)}';
    }
    // اگر hash نشده، mask کن
    return '****${cardNumber.substring(cardNumber.length - 4)}';
  }

  @override
  String toString() {
    return 'PayoutRequest{id: $id, amount: $formattedAmount, status: $statusText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PayoutRequest &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

