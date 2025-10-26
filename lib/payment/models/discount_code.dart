// مدل کد تخفیف

/// نوع تخفیف
enum DiscountType {
  percentage, // درصدی
  fixed, // مبلغ ثابت
}

/// وضعیت کد تخفیف
enum DiscountStatus {
  active, // فعال
  inactive, // غیرفعال
  expired, // منقضی شده
  usedUp, // تمام شده
}

/// محدودیت استفاده
enum UsageLimit {
  unlimited, // نامحدود
  perUser, // محدودیت بر اساس کاربر
  total, // محدودیت کل
}

class DiscountCode {
  const DiscountCode({
    required this.id,
    required this.code,
    required this.title,
    required this.type,
    required this.value,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
    this.description = '',
    this.maxDiscountAmount,
    this.minPurchaseAmount = 0,
    this.status = DiscountStatus.active,
    this.usageLimit = UsageLimit.unlimited,
    this.maxTotalUsage,
    this.maxUsagePerUser,
    this.usedCount = 0,
    this.startDate,
    this.expiryDate,
    this.allowedUsers,
    this.blockedUsers,
    this.applicableCategories,
    this.referenceCode,
    this.newUsersOnly = false,
    this.combinable = false,
    this.metadata,
  });

  factory DiscountCode.fromJson(Map<String, dynamic> json) {
    return DiscountCode(
      id: json['id'] as String,
      code: json['code'] as String,
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      type: DiscountType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => DiscountType.fixed,
      ),
      value: (json['value'] as num).toDouble(),
      maxDiscountAmount: json['max_discount_amount'] as int?,
      minPurchaseAmount: json['min_purchase_amount'] as int? ?? 0,
      status: DiscountStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => DiscountStatus.active,
      ),
      usageLimit: UsageLimit.values.firstWhere(
        (e) => e.toString().split('.').last == json['usage_limit'],
        orElse: () => UsageLimit.unlimited,
      ),
      maxTotalUsage: json['max_total_usage'] as int?,
      maxUsagePerUser: json['max_usage_per_user'] as int?,
      usedCount: json['used_count'] as int? ?? 0,
      startDate: json['start_date'] != null
          ? DateTime.parse(json['start_date'] as String)
          : null,
      expiryDate: json['expiry_date'] != null
          ? DateTime.parse(json['expiry_date'] as String)
          : null,
      allowedUsers: json['allowed_users'] != null
          ? List<String>.from(json['allowed_users'] as Iterable<dynamic>)
          : null,
      blockedUsers: json['blocked_users'] != null
          ? List<String>.from(json['blocked_users'] as Iterable<dynamic>)
          : null,
      applicableCategories: json['applicable_categories'] != null
          ? List<String>.from(
              json['applicable_categories'] as Iterable<dynamic>,
            )
          : null,
      referenceCode: json['reference_code'] as String?,
      newUsersOnly: json['new_users_only'] as bool? ?? false,
      combinable: json['combinable'] as bool? ?? false,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdBy: json['created_by'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// شناسه کد تخفیف
  final String id;

  /// کد تخفیف
  final String code;

  /// عنوان کد تخفیف
  final String title;

  /// توضیحات
  final String description;

  /// نوع تخفیف
  final DiscountType type;

  /// مقدار تخفیف (درصد یا ریال)
  final double value;

  /// حداکثر مبلغ تخفیف (ریال) - برای تخفیف درصدی
  final int? maxDiscountAmount;

  /// حداقل مبلغ خرید (ریال)
  final int minPurchaseAmount;

  /// وضعیت کد تخفیف
  final DiscountStatus status;

  /// محدودیت استفاده
  final UsageLimit usageLimit;

  /// حداکثر تعداد استفاده کل
  final int? maxTotalUsage;

  /// حداکثر تعداد استفاده هر کاربر
  final int? maxUsagePerUser;

  /// تعداد استفاده شده
  final int usedCount;

  /// تاریخ شروع اعتبار
  final DateTime? startDate;

  /// تاریخ انقضا
  final DateTime? expiryDate;

  /// کاربران مجاز (خالی = همه کاربران)
  final List<String>? allowedUsers;

  /// کاربران غیرمجاز
  final List<String>? blockedUsers;

  /// دسته‌بندی‌های قابل استفاده
  final List<String>? applicableCategories;

  /// کد تخفیف مرجع (برای کدهای زنجیره‌ای)
  final String? referenceCode;

  /// آیا فقط برای کاربران جدید است؟
  final bool newUsersOnly;

  /// آیا با سایر تخفیف‌ها قابل ترکیب است؟
  final bool combinable;

  /// اطلاعات اضافی
  final Map<String, dynamic>? metadata;

  /// شناسه ایجادکننده
  final String createdBy;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'code': code,
      'title': title,
      'description': description,
      'type': type.toString().split('.').last,
      'value': value,
      'max_discount_amount': maxDiscountAmount,
      'min_purchase_amount': minPurchaseAmount,
      'status': status.toString().split('.').last,
      'usage_limit': usageLimit.toString().split('.').last,
      'max_total_usage': maxTotalUsage,
      'max_usage_per_user': maxUsagePerUser,
      'used_count': usedCount,
      'start_date': startDate?.toIso8601String(),
      'expiry_date': expiryDate?.toIso8601String(),
      'allowed_users': allowedUsers,
      'blocked_users': blockedUsers,
      'applicable_categories': applicableCategories,
      'reference_code': referenceCode,
      'new_users_only': newUsersOnly,
      'combinable': combinable,
      'metadata': metadata,
      'created_by': createdBy,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  DiscountCode copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    DiscountType? type,
    double? value,
    int? maxDiscountAmount,
    int? minPurchaseAmount,
    DiscountStatus? status,
    UsageLimit? usageLimit,
    int? maxTotalUsage,
    int? maxUsagePerUser,
    int? usedCount,
    DateTime? startDate,
    DateTime? expiryDate,
    List<String>? allowedUsers,
    List<String>? blockedUsers,
    List<String>? applicableCategories,
    String? referenceCode,
    bool? newUsersOnly,
    bool? combinable,
    Map<String, dynamic>? metadata,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return DiscountCode(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      maxDiscountAmount: maxDiscountAmount ?? this.maxDiscountAmount,
      minPurchaseAmount: minPurchaseAmount ?? this.minPurchaseAmount,
      status: status ?? this.status,
      usageLimit: usageLimit ?? this.usageLimit,
      maxTotalUsage: maxTotalUsage ?? this.maxTotalUsage,
      maxUsagePerUser: maxUsagePerUser ?? this.maxUsagePerUser,
      usedCount: usedCount ?? this.usedCount,
      startDate: startDate ?? this.startDate,
      expiryDate: expiryDate ?? this.expiryDate,
      allowedUsers: allowedUsers ?? this.allowedUsers,
      blockedUsers: blockedUsers ?? this.blockedUsers,
      applicableCategories: applicableCategories ?? this.applicableCategories,
      referenceCode: referenceCode ?? this.referenceCode,
      newUsersOnly: newUsersOnly ?? this.newUsersOnly,
      combinable: combinable ?? this.combinable,
      metadata: metadata ?? this.metadata,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// آیا کد تخفیف فعال است؟
  bool get isActive => status == DiscountStatus.active && !isExpired;

  /// آیا کد تخفیف منقضی شده؟
  bool get isExpired {
    if (expiryDate == null) return false;
    return DateTime.now().isAfter(expiryDate!);
  }

  /// آیا کد تخفیف شروع شده؟
  bool get isStarted {
    if (startDate == null) return true;
    return DateTime.now().isAfter(startDate!) ||
        DateTime.now().isAtSameMomentAs(startDate!);
  }

  /// آیا کد تخفیف قابل استفاده است؟
  bool get isUsable => isActive && isStarted && !isUsedUp;

  /// آیا تمام شده؟
  bool get isUsedUp {
    if (usageLimit == UsageLimit.unlimited) return false;
    if (usageLimit == UsageLimit.total && maxTotalUsage != null) {
      return usedCount >= maxTotalUsage!;
    }
    return false;
  }

  /// محاسبه مبلغ تخفیف
  int calculateDiscount(int originalAmount) {
    if (!isUsable || originalAmount < minPurchaseAmount) return 0;

    int discountAmount = 0;

    if (type == DiscountType.percentage) {
      discountAmount = ((originalAmount * value) / 100).round();

      // اعمال حداکثر مبلغ تخفیف
      if (maxDiscountAmount != null && discountAmount > maxDiscountAmount!) {
        discountAmount = maxDiscountAmount!;
      }
    } else {
      discountAmount = value.round();

      // تخفیف نمی‌تواند بیشتر از مبلغ اصلی باشد
      if (discountAmount > originalAmount) {
        discountAmount = originalAmount;
      }
    }

    return discountAmount;
  }

  /// بررسی قابلیت استفاده برای کاربر خاص
  bool canUseForUser(
    String userId, {
    int userUsageCount = 0,
    bool isNewUser = false,
  }) {
    if (!isUsable) return false;

    // بررسی کاربران مجاز
    if (allowedUsers != null && !allowedUsers!.contains(userId)) {
      return false;
    }

    // بررسی کاربران غیرمجاز
    if (blockedUsers != null && blockedUsers!.contains(userId)) {
      return false;
    }

    // بررسی کاربران جدید
    if (newUsersOnly && !isNewUser) {
      return false;
    }

    // بررسی محدودیت استفاده هر کاربر
    if (usageLimit == UsageLimit.perUser && maxUsagePerUser != null) {
      if (userUsageCount >= maxUsagePerUser!) {
        return false;
      }
    }

    return true;
  }

  /// فرمت مقدار تخفیف
  String get formattedValue {
    if (type == DiscountType.percentage) {
      return '${value.toStringAsFixed(0)}%';
    } else {
      return '${(value / 10).toStringAsFixed(0)} تومان';
    }
  }

  /// فرمت حداقل مبلغ خرید
  String get formattedMinPurchase =>
      '${(minPurchaseAmount / 10).toStringAsFixed(0)} تومان';

  /// فرمت حداکثر تخفیف
  String get formattedMaxDiscount {
    if (maxDiscountAmount == null) return 'نامحدود';
    return '${(maxDiscountAmount! / 10).toStringAsFixed(0)} تومان';
  }

  /// متن وضعیت به فارسی
  String get statusText {
    if (isExpired) return 'منقضی شده';
    if (isUsedUp) return 'تمام شده';
    if (!isStarted) return 'هنوز شروع نشده';

    switch (status) {
      case DiscountStatus.active:
        return 'فعال';
      case DiscountStatus.inactive:
        return 'غیرفعال';
      case DiscountStatus.expired:
        return 'منقضی شده';
      case DiscountStatus.usedUp:
        return 'تمام شده';
    }
  }

  /// متن نوع تخفیف به فارسی
  String get typeText {
    switch (type) {
      case DiscountType.percentage:
        return 'درصدی';
      case DiscountType.fixed:
        return 'مبلغ ثابت';
    }
  }

  /// تعداد روزهای باقی‌مانده
  int get remainingDays {
    if (expiryDate == null) return -1;
    if (isExpired) return 0;
    return expiryDate!.difference(DateTime.now()).inDays;
  }

  /// متن زمان باقی‌مانده
  String get remainingTimeText {
    if (expiryDate == null) return 'بدون انقضا';
    if (isExpired) return 'منقضی شده';

    final days = remainingDays;
    if (days > 0) {
      return '$days روز باقی‌مانده';
    } else {
      final hours = expiryDate!.difference(DateTime.now()).inHours;
      if (hours > 0) {
        return '$hours ساعت باقی‌مانده';
      } else {
        return 'کمتر از یک ساعت';
      }
    }
  }

  /// درصد استفاده شده
  double get usagePercentage {
    if (usageLimit == UsageLimit.unlimited) return 0;
    if (maxTotalUsage == null) return 0;
    return (usedCount / maxTotalUsage!) * 100;
  }

  @override
  String toString() {
    return 'DiscountCode{code: $code, value: $formattedValue, status: $statusText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscountCode &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// کلاس کمکی برای ایجاد کد تخفیف
class DiscountCodeBuilder {
  String? _code;
  String? _title;
  String _description = '';
  DiscountType? _type;
  double? _value;
  int? _maxDiscountAmount;
  int _minPurchaseAmount = 0;
  DateTime? _expiryDate;
  String? _createdBy;

  DiscountCodeBuilder setCode(String code) {
    _code = code.toUpperCase();
    return this;
  }

  DiscountCodeBuilder setTitle(String title) {
    _title = title;
    return this;
  }

  DiscountCodeBuilder setDescription(String description) {
    _description = description;
    return this;
  }

  DiscountCodeBuilder setPercentageDiscount(
    double percentage, {
    int? maxAmount,
  }) {
    _type = DiscountType.percentage;
    _value = percentage;
    _maxDiscountAmount = maxAmount;
    return this;
  }

  DiscountCodeBuilder setFixedDiscount(int amount) {
    _type = DiscountType.fixed;
    _value = amount.toDouble();
    return this;
  }

  DiscountCodeBuilder setMinPurchaseAmount(int amount) {
    _minPurchaseAmount = amount;
    return this;
  }

  DiscountCodeBuilder setExpiryDate(DateTime date) {
    _expiryDate = date;
    return this;
  }

  DiscountCodeBuilder setCreatedBy(String userId) {
    _createdBy = userId;
    return this;
  }

  DiscountCode build() {
    if (_code == null ||
        _title == null ||
        _type == null ||
        _value == null ||
        _createdBy == null) {
      throw ArgumentError(
        'code, title, type, value, and createdBy are required',
      );
    }

    return DiscountCode(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      code: _code!,
      title: _title!,
      description: _description,
      type: _type!,
      value: _value!,
      maxDiscountAmount: _maxDiscountAmount,
      minPurchaseAmount: _minPurchaseAmount,
      expiryDate: _expiryDate,
      createdBy: _createdBy!,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
