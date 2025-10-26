// مدل اشتراک

/// نوع اشتراک
enum SubscriptionType {
  monthly, // ماهانه (31 روز)
  aiPremium, // هوش مصنوعی پریمیم
  trainerAccess, // دسترسی به مربی‌ها
  fullAccess, // دسترسی کامل
}

/// وضعیت اشتراک
enum SubscriptionStatus {
  active, // فعال
  expired, // منقضی شده
  cancelled, // لغو شده
  suspended, // تعلیق شده
  pendingPayment, // در انتظار پرداخت
}

class Subscription {
  const Subscription({
    required this.id,
    required this.userId,
    required this.type,
    required this.status,
    required this.price,
    required this.startDate,
    required this.expiryDate,
    required this.createdAt,
    required this.updatedAt,
    this.lastPaymentDate,
    this.lastTransactionId,
    this.autoRenewal = true,
    this.renewalCount = 0,
    this.cancelledAt,
    this.cancellationReason,
    this.metadata,
  });

  factory Subscription.fromJson(Map<String, dynamic> json) {
    return Subscription(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      type: SubscriptionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => SubscriptionType.monthly,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => SubscriptionStatus.pendingPayment,
      ),
      price: json['price'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      expiryDate: DateTime.parse(json['expiry_date'] as String),
      lastPaymentDate: json['last_payment_date'] != null
          ? DateTime.parse(json['last_payment_date'] as String)
          : null,
      lastTransactionId: json['last_transaction_id'] as String?,
      autoRenewal: json['auto_renewal'] as bool? ?? true,
      renewalCount: json['renewal_count'] as int? ?? 0,
      cancelledAt: json['cancelled_at'] != null
          ? DateTime.parse(json['cancelled_at'] as String)
          : null,
      cancellationReason: json['cancellation_reason'] as String?,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// شناسه اشتراک
  final String id;

  /// شناسه کاربر
  final String userId;

  /// نوع اشتراک
  final SubscriptionType type;

  /// وضعیت اشتراک
  final SubscriptionStatus status;

  /// قیمت اشتراک (ریال)
  final int price;

  /// تاریخ شروع
  final DateTime startDate;

  /// تاریخ انقضا
  final DateTime expiryDate;

  /// تاریخ آخرین پرداخت
  final DateTime? lastPaymentDate;

  /// شناسه آخرین تراکنش پرداخت
  final String? lastTransactionId;

  /// آیا تمدید خودکار فعال است؟
  final bool autoRenewal;

  /// تعداد دفعات تمدید
  final int renewalCount;

  /// تاریخ لغو (در صورت لغو)
  final DateTime? cancelledAt;

  /// دلیل لغو
  final String? cancellationReason;

  /// اطلاعات اضافی
  final Map<String, dynamic>? metadata;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      'price': price,
      'start_date': startDate.toIso8601String(),
      'expiry_date': expiryDate.toIso8601String(),
      'last_payment_date': lastPaymentDate?.toIso8601String(),
      'last_transaction_id': lastTransactionId,
      'auto_renewal': autoRenewal,
      'renewal_count': renewalCount,
      'cancelled_at': cancelledAt?.toIso8601String(),
      'cancellation_reason': cancellationReason,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  Subscription copyWith({
    String? id,
    String? userId,
    SubscriptionType? type,
    SubscriptionStatus? status,
    int? price,
    DateTime? startDate,
    DateTime? expiryDate,
    DateTime? lastPaymentDate,
    String? lastTransactionId,
    bool? autoRenewal,
    int? renewalCount,
    DateTime? cancelledAt,
    String? cancellationReason,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Subscription(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      status: status ?? this.status,
      price: price ?? this.price,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      lastTransactionId: lastTransactionId ?? this.lastTransactionId,
      autoRenewal: autoRenewal ?? this.autoRenewal,
      renewalCount: renewalCount ?? this.renewalCount,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// آیا اشتراک فعال است؟
  bool get isActive => status == SubscriptionStatus.active && !isExpired;

  /// آیا اشتراک منقضی شده؟
  bool get isExpired => DateTime.now().isAfter(expiryDate);

  /// آیا اشتراک لغو شده؟
  bool get isCancelled => status == SubscriptionStatus.cancelled;

  /// آیا در انتظار پرداخت است؟
  bool get isPendingPayment => status == SubscriptionStatus.pendingPayment;

  /// تعداد روزهای باقی‌مانده
  int get remainingDays {
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inDays;
  }

  /// تعداد ساعات باقی‌مانده
  int get remainingHours {
    if (isExpired) return 0;
    return expiryDate.difference(DateTime.now()).inHours;
  }

  /// درصد زمان باقی‌مانده
  double get remainingPercentage {
    final totalDuration = expiryDate.difference(startDate).inHours;
    final remainingDuration = expiryDate.difference(DateTime.now()).inHours;

    if (totalDuration <= 0 || remainingDuration <= 0) return 0;
    return (remainingDuration / totalDuration) * 100;
  }

  /// فرمت قیمت به تومان
  String get formattedPrice => '${(price / 10).toStringAsFixed(0)} تومان';

  /// متن نوع اشتراک به فارسی
  String get typeText {
    switch (type) {
      case SubscriptionType.monthly:
        return 'اشتراک ماهانه';
      case SubscriptionType.aiPremium:
        return 'هوش مصنوعی پریمیم';
      case SubscriptionType.trainerAccess:
        return 'دسترسی به مربی‌ها';
      case SubscriptionType.fullAccess:
        return 'دسترسی کامل';
    }
  }

  /// متن وضعیت اشتراک به فارسی
  String get statusText {
    switch (status) {
      case SubscriptionStatus.active:
        return isExpired ? 'منقضی شده' : 'فعال';
      case SubscriptionStatus.expired:
        return 'منقضی شده';
      case SubscriptionStatus.cancelled:
        return 'لغو شده';
      case SubscriptionStatus.suspended:
        return 'تعلیق شده';
      case SubscriptionStatus.pendingPayment:
        return 'در انتظار پرداخت';
    }
  }

  /// توضیحات اشتراک
  String get description {
    switch (type) {
      case SubscriptionType.monthly:
        return 'دسترسی کامل به تمام امکانات برای 31 روز';
      case SubscriptionType.aiPremium:
        return 'دسترسی نامحدود به برنامه‌های هوش مصنوعی';
      case SubscriptionType.trainerAccess:
        return 'دسترسی به خدمات مربی‌های حرفه‌ای';
      case SubscriptionType.fullAccess:
        return 'دسترسی کامل به تمام امکانات و خدمات';
    }
  }

  /// ویژگی‌های اشتراک
  List<String> get features {
    switch (type) {
      case SubscriptionType.monthly:
        return [
          'برنامه‌های تمرینی نامحدود',
          'برنامه‌های تغذیه شخصی',
          'دسترسی به هوش مصنوعی',
          'چت با مربی‌ها',
          'پیگیری پیشرفت',
        ];
      case SubscriptionType.aiPremium:
        return [
          'تولید برنامه با هوش مصنوعی',
          'تحلیل پیشرفته',
          'پیشنهادات شخصی‌سازی شده',
        ];
      case SubscriptionType.trainerAccess:
        return ['چت مستقیم با مربی‌ها', 'برنامه‌های اختصاصی', 'مشاوره تخصصی'];
      case SubscriptionType.fullAccess:
        return [
          'تمام ویژگی‌های پایه',
          'دسترسی VIP',
          'پشتیبانی اولویت‌دار',
          'محتوای اختصاصی',
        ];
    }
  }

  /// تاریخ تمدید بعدی
  DateTime get nextRenewalDate {
    if (!autoRenewal) return expiryDate;
    return DateTime(expiryDate.year, expiryDate.month + 1, expiryDate.day);
  }

  /// آیا نیاز به تمدید دارد؟
  bool get needsRenewal {
    if (!autoRenewal) return false;
    final daysToExpiry = remainingDays;
    return daysToExpiry <= 3; // 3 روز قبل از انقضا
  }

  /// متن زمان باقی‌مانده
  String get remainingTimeText {
    if (isExpired) return 'منقضی شده';

    final days = remainingDays;
    final hours = remainingHours % 24;

    if (days > 0) {
      return '$days روز باقی‌مانده';
    } else if (hours > 0) {
      return '$hours ساعت باقی‌مانده';
    } else {
      return 'کمتر از یک ساعت';
    }
  }

  @override
  String toString() {
    return 'Subscription{id: $id, type: $typeText, status: $statusText, remaining: $remainingTimeText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Subscription &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// کلاس کمکی برای ایجاد اشتراک جدید
class SubscriptionBuilder {
  String? _userId;
  SubscriptionType? _type;
  int? _price;
  DateTime? _startDate;
  bool _autoRenewal = true;
  Map<String, dynamic>? _metadata;

  SubscriptionBuilder setUserId(String userId) {
    _userId = userId;
    return this;
  }

  SubscriptionBuilder setType(SubscriptionType type) {
    _type = type;
    return this;
  }

  SubscriptionBuilder setPrice(int price) {
    _price = price;
    return this;
  }

  SubscriptionBuilder setStartDate(DateTime startDate) {
    _startDate = startDate;
    return this;
  }

  SubscriptionBuilder setAutoRenewal(bool autoRenewal) {
    _autoRenewal = autoRenewal;
    return this;
  }

  SubscriptionBuilder setMetadata(Map<String, dynamic> metadata) {
    _metadata = metadata;
    return this;
  }

  Subscription build() {
    if (_userId == null || _type == null || _price == null) {
      throw ArgumentError('userId, type, and price are required');
    }

    final startDate = _startDate ?? DateTime.now();
    final expiryDate = startDate.add(const Duration(days: 31)); // 31 روز

    return Subscription(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: _userId!,
      type: _type!,
      status: SubscriptionStatus.pendingPayment,
      price: _price!,
      startDate: startDate,
      expiryDate: expiryDate,
      autoRenewal: _autoRenewal,
      metadata: _metadata,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
