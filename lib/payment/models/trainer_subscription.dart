// مدل اشتراک مربی

/// نوع خدمات مربی
enum TrainerServiceType {
  training, // برنامه تمرینی
  diet, // برنامه رژیم غذایی
  consulting, // مشاوره و نظارت
  package, // بسته کامل
}

/// وضعیت اشتراک مربی
enum TrainerSubscriptionStatus {
  pending, // در انتظار پرداخت
  paid, // پرداخت شده
  active, // فعال
  expired, // منقضی شده
  cancelled, // لغو شده
  suspended, // تعلیق شده
}

/// وضعیت برنامه مربی
enum ProgramStatus {
  notStarted, // شروع نشده
  inProgress, // در حال انجام
  completed, // تکمیل شده
  delayed, // تاخیر داشته
}

class TrainerSubscription {
  const TrainerSubscription({
    required this.id,
    required this.userId,
    required this.trainerId,
    required this.serviceType,
    required this.status,
    required this.originalAmount,
    required this.finalAmount,
    required this.purchaseDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.discountAmount = 0,
    this.discountCode,
    this.discountPercentage = 0.0,
    this.paymentTransactionId,
    this.programRegistrationDate,
    this.firstUsageDate,
    this.programStatus = ProgramStatus.notStarted,
    this.trainerDelayDays = 0,
    this.metadata,
  });

  factory TrainerSubscription.fromJson(Map<String, dynamic> json) {
    ProgramStatus programStatusFromDb(String value) {
      switch (value) {
        case 'not_started':
          return ProgramStatus.notStarted;
        case 'in_progress':
          return ProgramStatus.inProgress;
        case 'completed':
          return ProgramStatus.completed;
        case 'delayed':
          return ProgramStatus.delayed;
        default:
          // fallback for camelCase
          return ProgramStatus.values.firstWhere(
            (e) => e.toString().split('.').last == value,
            orElse: () => ProgramStatus.notStarted,
          );
      }
    }

    return TrainerSubscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      trainerId: json['trainer_id'] as String,
      serviceType: TrainerServiceType.values.firstWhere(
        (e) => e.toString().split('.').last == json['service_type'],
        orElse: () => TrainerServiceType.training,
      ),
      status: TrainerSubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TrainerSubscriptionStatus.pending,
      ),
      originalAmount: json['original_amount'] as int,
      finalAmount: json['final_amount'] as int,
      discountAmount: json['discount_amount'] as int? ?? 0,
      discountCode: json['discount_code'] as String?,
      discountPercentage:
          (json['discount_percentage'] as num?)?.toDouble() ?? 0.0,
      paymentTransactionId: json['payment_transaction_id'] as String?,
      purchaseDate: DateTime.parse(json['purchase_date'] as String),
      programRegistrationDate: json['program_registration_date'] != null
          ? DateTime.parse(json['program_registration_date'] as String)
          : null,
      firstUsageDate: json['first_usage_date'] != null
          ? DateTime.parse(json['first_usage_date'] as String)
          : null,
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      programStatus: programStatusFromDb(json['program_status'] as String),
      trainerDelayDays: json['trainer_delay_days'] as int? ?? 0,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// شناسه اشتراک
  final String id;

  /// شناسه کاربر (خریدار)
  final String userId;

  /// شناسه مربی
  final String trainerId;

  /// نوع خدمات
  final TrainerServiceType serviceType;

  /// وضعیت اشتراک
  final TrainerSubscriptionStatus status;

  /// مبلغ اصلی (ریال)
  final int originalAmount;

  /// مبلغ نهایی بعد از تخفیف (ریال)
  final int finalAmount;

  /// مبلغ تخفیف (ریال)
  final int discountAmount;

  /// کد تخفیف استفاده شده
  final String? discountCode;

  /// درصد تخفیف
  final double discountPercentage;

  /// شناسه تراکنش پرداخت
  final String? paymentTransactionId;

  /// تاریخ خرید
  final DateTime purchaseDate;

  /// تاریخ ثبت برنامه توسط مربی
  final DateTime? programRegistrationDate;

  /// تاریخ اولین استفاده (لاگ کردن برنامه)
  final DateTime? firstUsageDate;

  /// تاریخ انقضا
  final DateTime expiryDate;

  /// وضعیت برنامه
  final ProgramStatus programStatus;

  /// تاخیر مربی (روز)
  final int trainerDelayDays;

  /// اطلاعات اضافی
  final Map<String, dynamic>? metadata;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    String programStatusToDb(ProgramStatus status) {
      switch (status) {
        case ProgramStatus.notStarted:
          return 'not_started';
        case ProgramStatus.inProgress:
          return 'in_progress';
        case ProgramStatus.completed:
          return 'completed';
        case ProgramStatus.delayed:
          return 'delayed';
      }
    }

    return {
      'id': id,
      'user_id': userId,
      'trainer_id': trainerId,
      'service_type': serviceType.toString().split('.').last,
      'status': status.toString().split('.').last,
      'original_amount': originalAmount,
      'final_amount': finalAmount,
      'discount_amount': discountAmount,
      'discount_code': discountCode,
      'discount_percentage': discountPercentage,
      'payment_transaction_id': paymentTransactionId,
      'purchase_date': purchaseDate.toIso8601String(),
      'program_registration_date': programRegistrationDate?.toIso8601String(),
      'first_usage_date': firstUsageDate?.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'program_status': programStatusToDb(programStatus),
      'trainer_delay_days': trainerDelayDays,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  TrainerSubscription copyWith({
    String? id,
    String? userId,
    String? trainerId,
    TrainerServiceType? serviceType,
    TrainerSubscriptionStatus? status,
    int? originalAmount,
    int? finalAmount,
    int? discountAmount,
    String? discountCode,
    double? discountPercentage,
    String? paymentTransactionId,
    DateTime? purchaseDate,
    DateTime? programRegistrationDate,
    DateTime? firstUsageDate,
    DateTime? expiryDate,
    ProgramStatus? programStatus,
    int? trainerDelayDays,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TrainerSubscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      trainerId: trainerId ?? this.trainerId,
      serviceType: serviceType ?? this.serviceType,
      status: status ?? this.status,
      originalAmount: originalAmount ?? this.originalAmount,
      finalAmount: finalAmount ?? this.finalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCode: discountCode ?? this.discountCode,
      discountPercentage: discountPercentage ?? this.discountPercentage,
      paymentTransactionId: paymentTransactionId ?? this.paymentTransactionId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      programRegistrationDate:
          programRegistrationDate ?? this.programRegistrationDate,
      firstUsageDate: firstUsageDate ?? this.firstUsageDate,
      expiryDate: expiryDate ?? this.expiryDate,
      programStatus: programStatus ?? this.programStatus,
      trainerDelayDays: trainerDelayDays ?? this.trainerDelayDays,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// آیا اشتراک فعال است؟
  bool get isActive => status == TrainerSubscriptionStatus.active && !isExpired;

  /// آیا اشتراک منقضی شده؟
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// آیا پرداخت شده؟
  bool get isPaid =>
      status == TrainerSubscriptionStatus.paid ||
      status == TrainerSubscriptionStatus.active;

  /// آیا در انتظار پرداخت است؟
  bool get isPending => status == TrainerSubscriptionStatus.pending;

  /// آیا لغو شده؟
  bool get isCancelled => status == TrainerSubscriptionStatus.cancelled;

  /// تعداد روزهای باقی‌مانده
  int get remainingDays {
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// آیا برنامه شروع شده؟
  bool get isProgramStarted => programStatus != ProgramStatus.notStarted;

  /// آیا برنامه تکمیل شده؟
  bool get isProgramCompleted => programStatus == ProgramStatus.completed;

  /// آیا تاخیر داشته؟
  bool get hasDelay => trainerDelayDays > 0;

  /// فرمت مبلغ اصلی به تومان
  String get formattedOriginalAmount =>
      '${(originalAmount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ نهایی به تومان
  String get formattedFinalAmount =>
      '${(finalAmount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ تخفیف به تومان
  String get formattedDiscountAmount =>
      '${(discountAmount / 10).toStringAsFixed(0)} تومان';

  /// متن نوع خدمات به فارسی
  String get serviceTypeText {
    switch (serviceType) {
      case TrainerServiceType.training:
        return 'برنامه تمرینی';
      case TrainerServiceType.diet:
        return 'برنامه رژیم غذایی';
      case TrainerServiceType.consulting:
        return 'مشاوره و نظارت';
      case TrainerServiceType.package:
        return 'بسته کامل';
    }
  }

  /// متن وضعیت اشتراک به فارسی
  String get statusText {
    switch (status) {
      case TrainerSubscriptionStatus.pending:
        return 'در انتظار پرداخت';
      case TrainerSubscriptionStatus.paid:
        return 'پرداخت شده';
      case TrainerSubscriptionStatus.active:
        return isExpired ? 'منقضی شده' : 'فعال';
      case TrainerSubscriptionStatus.expired:
        return 'منقضی شده';
      case TrainerSubscriptionStatus.cancelled:
        return 'لغو شده';
      case TrainerSubscriptionStatus.suspended:
        return 'تعلیق شده';
    }
  }

  /// متن وضعیت برنامه به فارسی
  String get programStatusText {
    switch (programStatus) {
      case ProgramStatus.notStarted:
        return 'شروع نشده';
      case ProgramStatus.inProgress:
        return 'در حال انجام';
      case ProgramStatus.completed:
        return 'تکمیل شده';
      case ProgramStatus.delayed:
        return 'تاخیر داشته';
    }
  }

  /// توضیحات اشتراک
  String get description {
    switch (serviceType) {
      case TrainerServiceType.training:
        return 'برنامه تمرینی شخصی‌سازی شده';
      case TrainerServiceType.diet:
        return 'برنامه رژیم غذایی متعادل';
      case TrainerServiceType.consulting:
        return 'مشاوره و نظارت مداوم';
      case TrainerServiceType.package:
        return 'بسته کامل شامل تمام خدمات';
    }
  }

  /// ویژگی‌های اشتراک
  List<String> get features {
    switch (serviceType) {
      case TrainerServiceType.training:
        return [
          'برنامه تمرینی روزانه',
          'شامل 4 هفته تمرین',
          'راهنمایی تکنیک‌ها',
          'پشتیبانی آنلاین',
          'بررسی پیشرفت',
        ];
      case TrainerServiceType.diet:
        return [
          'برنامه غذایی روزانه',
          'شامل 4 هفته رژیم',
          'محاسبه کالری',
          'پشتیبانی آنلاین',
          'بررسی پیشرفت',
        ];
      case TrainerServiceType.consulting:
        return [
          'چت نامحدود با مربی',
          'بررسی روزانه پیشرفت',
          'مشاوره تخصصی',
          'تنظیم برنامه',
          'پشتیبانی 24/7',
        ];
      case TrainerServiceType.package:
        return [
          'برنامه تمرینی',
          'برنامه رژیم غذایی',
          'مشاوره و نظارت',
          'پشتیبانی کامل',
          'دسترسی VIP',
        ];
    }
  }

  /// تاریخ تاخیر مربی
  DateTime? get trainerDelayDate {
    if (programRegistrationDate == null) return null;
    final expectedDate = purchaseDate.add(
      const Duration(days: 1),
    ); // فرض: 1 روز بعد از خرید
    if (programRegistrationDate!.isAfter(expectedDate)) {
      return programRegistrationDate;
    }
    return null;
  }

  /// محاسبه تاخیر مربی
  int calculateTrainerDelay() {
    if (programRegistrationDate == null) return 0;
    final expectedDate = purchaseDate.add(const Duration(days: 1));
    if (programRegistrationDate!.isAfter(expectedDate)) {
      return programRegistrationDate!.difference(expectedDate).inDays;
    }
    return 0;
  }

  /// متن زمان باقی‌مانده
  String get remainingTimeText {
    if (isExpired) return 'منقضی شده';

    final days = remainingDays;
    if (days > 0) {
      return '$days روز باقی‌مانده';
    } else {
      return 'کمتر از یک روز';
    }
  }

  @override
  String toString() {
    return 'TrainerSubscription{id: $id, service: $serviceTypeText, status: $statusText, amount: $formattedFinalAmount}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainerSubscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// کلاس کمکی برای ایجاد اشتراک مربی جدید
class TrainerSubscriptionBuilder {
  String? _userId;
  String? _trainerId;
  TrainerServiceType? _serviceType;
  int? _originalAmount;
  int? _finalAmount;
  String? _discountCode;
  double? _discountPercentage;
  String? _paymentTransactionId;
  DateTime? _purchaseDate;
  DateTime? _expiryDate;
  Map<String, dynamic>? _metadata;

  TrainerSubscriptionBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  TrainerSubscriptionBuilder setTrainerId(String trainerId) {
    _trainerId = trainerId;
    return this;
  }

  TrainerSubscriptionBuilder setServiceType(TrainerServiceType serviceType) {
    _serviceType = serviceType;
    return this;
  }

  TrainerSubscriptionBuilder setOriginalAmount(int originalAmount) {
    _originalAmount = originalAmount;
    return this;
  }

  TrainerSubscriptionBuilder setFinalAmount(int finalAmount) {
    _finalAmount = finalAmount;
    return this;
  }

  TrainerSubscriptionBuilder setDiscountCode(String discountCode) {
    _discountCode = discountCode;
    return this;
  }

  TrainerSubscriptionBuilder setDiscountPercentage(double discountPercentage) {
    _discountPercentage = discountPercentage;
    return this;
  }

  TrainerSubscriptionBuilder setPaymentTransactionId(
    String paymentTransactionId,
  ) {
    _paymentTransactionId = paymentTransactionId;
    return this;
  }

  TrainerSubscriptionBuilder setPurchaseDate(DateTime purchaseDate) {
    _purchaseDate = purchaseDate;
    return this;
  }

  TrainerSubscriptionBuilder setExpiryDate(DateTime expiryDate) {
    _expiryDate = expiryDate;
    return this;
  }

  TrainerSubscriptionBuilder setMetadata(Map<String, dynamic> metadata) {
    _metadata = metadata;
    return this;
  }

  TrainerSubscription build() {
    if (_userId == null ||
        _trainerId == null ||
        _serviceType == null ||
        _originalAmount == null ||
        _finalAmount == null) {
      throw ArgumentError(
        'userId, trainerId, serviceType, originalAmount, and finalAmount are required',
      );
    }

    final purchaseDate = _purchaseDate ?? DateTime.now();
    final expiryDate =
        _expiryDate ?? purchaseDate.add(const Duration(days: 30)); // 30 روز
    final discountAmount = _originalAmount! - _finalAmount!;
    final discountPercentage =
        _discountPercentage ??
        (_originalAmount! > 0
            ? (discountAmount / _originalAmount!) * 100
            : 0.0);

    return TrainerSubscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId!,
      trainerId: _trainerId!,
      serviceType: _serviceType!,
      status: TrainerSubscriptionStatus.pending,
      originalAmount: _originalAmount!,
      finalAmount: _finalAmount!,
      discountAmount: discountAmount,
      discountCode: _discountCode,
      discountPercentage: discountPercentage,
      paymentTransactionId: _paymentTransactionId,
      purchaseDate: purchaseDate,
      expiryDate: expiryDate,
      metadata: _metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
