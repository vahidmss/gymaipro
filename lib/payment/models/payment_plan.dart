// مدل طرح پرداخت

/// نوع طرح پرداخت
enum PaymentPlanType {
  aiProgram, // برنامه هوش مصنوعی
  trainerService, // خدمات مربی
  subscription, // اشتراک
  walletCharge, // شارژ کیف پول
  premiumFeature, // ویژگی پریمیم
}

/// سطح دسترسی طرح
enum PlanAccessLevel {
  basic, // پایه
  premium, // پریمیم
  vip, // VIP
  enterprise, // سازمانی
}

class PaymentPlan {
  const PaymentPlan({
    required this.id,
    required this.name,
    required this.shortDescription,
    required this.fullDescription,
    required this.type,
    required this.accessLevel,
    required this.price,
    required this.features,
    required this.createdAt,
    required this.updatedAt,
    this.originalPrice,
    this.isFree = false,
    this.isPopular = false,
    this.isSpecialOffer = false,
    this.validityDays,
    this.limitations,
    this.bonuses,
    this.imageUrl,
    this.iconUrl,
    this.color,
    this.displayOrder = 0,
    this.isActive = true,
    this.isPurchasable = true,
    this.minAge,
    this.maxAge,
    this.targetGender,
    this.targetExperienceLevel,
    this.allowedCountries,
    this.metadata,
    this.saleStartDate,
    this.saleEndDate,
  });

  factory PaymentPlan.fromJson(Map<String, dynamic> json) {
    return PaymentPlan(
      id: json['id'] as String,
      name: json['name'] as String,
      shortDescription: json['short_description'] as String,
      fullDescription: json['full_description'] as String,
      type: PaymentPlanType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => PaymentPlanType.subscription,
      ),
      accessLevel: PlanAccessLevel.values.firstWhere(
        (e) => e.toString().split('.').last == json['access_level'],
        orElse: () => PlanAccessLevel.basic,
      ),
      price: json['price'] as int,
      originalPrice: json['original_price'] as int?,
      isFree: json['is_free'] as bool? ?? false,
      isPopular: json['is_popular'] as bool? ?? false,
      isSpecialOffer: json['is_special_offer'] as bool? ?? false,
      validityDays: json['validity_days'] as int?,
      features: List<String>.from(
        json['features'] as Iterable<dynamic>? ?? <dynamic>[],
      ),
      limitations: json['limitations'] as Map<String, dynamic>?,
      bonuses: json['bonuses'] as Map<String, dynamic>?,
      imageUrl: json['image_url'] as String?,
      iconUrl: json['icon_url'] as String?,
      color: json['color'] as String?,
      displayOrder: json['display_order'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isPurchasable: json['is_purchasable'] as bool? ?? true,
      minAge: json['min_age'] as int?,
      maxAge: json['max_age'] as int?,
      targetGender: json['target_gender'] as String?,
      targetExperienceLevel: json['target_experience_level'] != null
          ? List<String>.from(
              json['target_experience_level'] as Iterable<dynamic>,
            )
          : null,
      allowedCountries: json['allowed_countries'] != null
          ? List<String>.from(json['allowed_countries'] as Iterable<dynamic>)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      saleStartDate: json['sale_start_date'] != null
          ? DateTime.parse(json['sale_start_date'] as String)
          : null,
      saleEndDate: json['sale_end_date'] != null
          ? DateTime.parse(json['sale_end_date'] as String)
          : null,
    );
  }

  /// شناسه طرح
  final String id;

  /// نام طرح
  final String name;

  /// توضیحات کوتاه
  final String shortDescription;

  /// توضیحات کامل
  final String fullDescription;

  /// نوع طرح
  final PaymentPlanType type;

  /// سطح دسترسی
  final PlanAccessLevel accessLevel;

  /// قیمت (ریال)
  final int price;

  /// قیمت اصلی قبل از تخفیف (ریال)
  final int? originalPrice;

  /// آیا رایگان است؟
  final bool isFree;

  /// آیا محبوب است؟
  final bool isPopular;

  /// آیا پیشنهاد ویژه است؟
  final bool isSpecialOffer;

  /// مدت زمان اعتبار (روز) - null = نامحدود
  final int? validityDays;

  /// ویژگی‌های طرح
  final List<String> features;

  /// محدودیت‌های طرح
  final Map<String, dynamic>? limitations;

  /// امتیازات اضافی
  final Map<String, dynamic>? bonuses;

  /// تصویر طرح
  final String? imageUrl;

  /// آیکون طرح
  final String? iconUrl;

  /// رنگ طرح
  final String? color;

  /// ترتیب نمایش
  final int displayOrder;

  /// آیا فعال است؟
  final bool isActive;

  /// آیا قابل خرید است؟
  final bool isPurchasable;

  /// حداقل سن کاربر
  final int? minAge;

  /// حداکثر سن کاربر
  final int? maxAge;

  /// جنسیت مورد نظر (male, female, both)
  final String? targetGender;

  /// سطح تجربه مورد نظر
  final List<String>? targetExperienceLevel;

  /// کشورهای مجاز
  final List<String>? allowedCountries;

  /// اطلاعات اضافی
  final Map<String, dynamic>? metadata;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  /// تاریخ شروع فروش
  final DateTime? saleStartDate;

  /// تاریخ پایان فروش
  final DateTime? saleEndDate;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'short_description': shortDescription,
      'full_description': fullDescription,
      'type': type.toString().split('.').last,
      'access_level': accessLevel.toString().split('.').last,
      'price': price,
      'original_price': originalPrice,
      'is_free': isFree,
      'is_popular': isPopular,
      'is_special_offer': isSpecialOffer,
      'validity_days': validityDays,
      'features': features,
      'limitations': limitations,
      'bonuses': bonuses,
      'image_url': imageUrl,
      'icon_url': iconUrl,
      'color': color,
      'display_order': displayOrder,
      'is_active': isActive,
      'is_purchasable': isPurchasable,
      'min_age': minAge,
      'max_age': maxAge,
      'target_gender': targetGender,
      'target_experience_level': targetExperienceLevel,
      'allowed_countries': allowedCountries,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'sale_start_date': saleStartDate?.toIso8601String(),
      'sale_end_date': saleEndDate?.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  PaymentPlan copyWith({
    String? id,
    String? name,
    String? shortDescription,
    String? fullDescription,
    PaymentPlanType? type,
    PlanAccessLevel? accessLevel,
    int? price,
    int? originalPrice,
    bool? isFree,
    bool? isPopular,
    bool? isSpecialOffer,
    int? validityDays,
    List<String>? features,
    Map<String, dynamic>? limitations,
    Map<String, dynamic>? bonuses,
    String? imageUrl,
    String? iconUrl,
    String? color,
    int? displayOrder,
    bool? isActive,
    bool? isPurchasable,
    int? minAge,
    int? maxAge,
    String? targetGender,
    List<String>? targetExperienceLevel,
    List<String>? allowedCountries,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? saleStartDate,
    DateTime? saleEndDate,
  }) {
    return PaymentPlan(
      id: id ?? this.id,
      name: name ?? this.name,
      shortDescription: shortDescription ?? this.shortDescription,
      fullDescription: fullDescription ?? this.fullDescription,
      type: type ?? this.type,
      accessLevel: accessLevel ?? this.accessLevel,
      price: price ?? this.price,
      originalPrice: originalPrice ?? this.originalPrice,
      isFree: isFree ?? this.isFree,
      isPopular: isPopular ?? this.isPopular,
      isSpecialOffer: isSpecialOffer ?? this.isSpecialOffer,
      validityDays: validityDays ?? this.validityDays,
      features: features ?? this.features,
      limitations: limitations ?? this.limitations,
      bonuses: bonuses ?? this.bonuses,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      color: color ?? this.color,
      displayOrder: displayOrder ?? this.displayOrder,
      isActive: isActive ?? this.isActive,
      isPurchasable: isPurchasable ?? this.isPurchasable,
      minAge: minAge ?? this.minAge,
      maxAge: maxAge ?? this.maxAge,
      targetGender: targetGender ?? this.targetGender,
      targetExperienceLevel:
          targetExperienceLevel ?? this.targetExperienceLevel,
      allowedCountries: allowedCountries ?? this.allowedCountries,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      saleStartDate: saleStartDate ?? this.saleStartDate,
      saleEndDate: saleEndDate ?? this.saleEndDate,
    );
  }

  /// آیا در حال فروش است؟
  bool get isOnSale {
    final now = DateTime.now();
    if (saleStartDate != null && now.isBefore(saleStartDate!)) return false;
    if (saleEndDate != null && now.isAfter(saleEndDate!)) return false;
    return isActive && isPurchasable;
  }

  /// آیا تخفیف دارد؟
  bool get hasDiscount => originalPrice != null && originalPrice! > price;

  /// درصد تخفیف
  double get discountPercentage {
    if (!hasDiscount) return 0;
    return ((originalPrice! - price) / originalPrice!) * 100;
  }

  /// مبلغ تخفیف
  int get discountAmount {
    if (!hasDiscount) return 0;
    return originalPrice! - price;
  }

  /// آیا محدودیت زمانی دارد؟
  bool get hasTimeLimit => validityDays != null;

  /// متن مدت اعتبار
  String get validityText {
    if (validityDays == null) return 'نامحدود';
    if (validityDays == 1) return '1 روز';
    if (validityDays! <= 31) return '$validityDays روز';
    final months = (validityDays! / 31).round();
    return '$months ماه';
  }

  /// فرمت قیمت به تومان
  String get formattedPrice {
    if (isFree) return 'رایگان';
    return '${(price / 10).toStringAsFixed(0)} تومان';
  }

  /// فرمت قیمت اصلی به تومان
  String get formattedOriginalPrice {
    if (originalPrice == null) return formattedPrice;
    return '${(originalPrice! / 10).toStringAsFixed(0)} تومان';
  }

  /// فرمت مبلغ تخفیف به تومان
  String get formattedDiscountAmount {
    if (!hasDiscount) return '0 تومان';
    return '${(discountAmount / 10).toStringAsFixed(0)} تومان';
  }

  /// متن نوع طرح به فارسی
  String get typeText {
    switch (type) {
      case PaymentPlanType.aiProgram:
        return 'برنامه هوش مصنوعی';
      case PaymentPlanType.trainerService:
        return 'خدمات مربی';
      case PaymentPlanType.subscription:
        return 'اشتراک';
      case PaymentPlanType.walletCharge:
        return 'شارژ کیف پول';
      case PaymentPlanType.premiumFeature:
        return 'ویژگی پریمیم';
    }
  }

  /// متن سطح دسترسی به فارسی
  String get accessLevelText {
    switch (accessLevel) {
      case PlanAccessLevel.basic:
        return 'پایه';
      case PlanAccessLevel.premium:
        return 'پریمیم';
      case PlanAccessLevel.vip:
        return 'VIP';
      case PlanAccessLevel.enterprise:
        return 'سازمانی';
    }
  }

  /// رنگ سطح دسترسی
  String get accessLevelColor {
    switch (accessLevel) {
      case PlanAccessLevel.basic:
        return '#9E9E9E'; // خاکستری
      case PlanAccessLevel.premium:
        return '#FF9800'; // نارنجی
      case PlanAccessLevel.vip:
        return '#9C27B0'; // بنفش
      case PlanAccessLevel.enterprise:
        return '#3F51B5'; // آبی
    }
  }

  /// بررسی سازگاری با کاربر
  bool isCompatibleWithUser({
    int? userAge,
    String? userGender,
    String? userCountry,
    String? userExperienceLevel,
  }) {
    // بررسی سن
    if (minAge != null && userAge != null && userAge < minAge!) return false;
    if (maxAge != null && userAge != null && userAge > maxAge!) return false;

    // بررسی جنسیت
    if (targetGender != null &&
        targetGender != 'both' &&
        userGender != null &&
        userGender != targetGender) {
      return false;
    }

    // بررسی کشور
    if (allowedCountries != null &&
        userCountry != null &&
        !allowedCountries!.contains(userCountry)) {
      return false;
    }

    // بررسی سطح تجربه
    if (targetExperienceLevel != null &&
        userExperienceLevel != null &&
        !targetExperienceLevel!.contains(userExperienceLevel)) {
      return false;
    }

    return true;
  }

  /// محدودیت‌های طرح به صورت متنی
  List<String> get limitationTexts {
    if (limitations == null) return [];

    final List<String> texts = [];
    limitations!.forEach((key, value) {
      switch (key) {
        case 'max_programs':
          texts.add('حداکثر $value برنامه');
        case 'max_trainers':
          texts.add('حداکثر $value مربی');
        case 'max_ai_requests':
          texts.add('حداکثر $value درخواست هوش مصنوعی');
        case 'max_storage':
          texts.add('حداکثر $value مگابایت فضای ذخیره‌سازی');
        default:
          texts.add('$key: $value');
      }
    });

    return texts;
  }

  /// امتیازات اضافی به صورت متنی
  List<String> get bonusTexts {
    if (bonuses == null) return [];

    final List<String> texts = [];
    bonuses!.forEach((key, value) {
      switch (key) {
        case 'free_consultation':
          if (value == true) texts.add('مشاوره رایگان');
        case 'priority_support':
          if (value == true) texts.add('پشتیبانی اولویت‌دار');
        case 'exclusive_content':
          if (value == true) texts.add('محتوای اختصاصی');
        case 'bonus_credits':
          texts.add('$value امتیاز هدیه');
        default:
          if (value == true) texts.add(key);
      }
    });

    return texts;
  }

  @override
  String toString() {
    return 'PaymentPlan{id: $id, name: $name, price: $formattedPrice, type: $typeText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentPlan &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// طرح‌های پیش‌تعریف شده
class PredefinedPlans {
  /// طرح‌های برنامه هوش مصنوعی
  static List<PaymentPlan> get aiPrograms => [
    PaymentPlan(
      id: 'ai_basic',
      name: 'برنامه هوش مصنوعی پایه',
      shortDescription: 'برنامه تمرینی شخصی‌سازی شده',
      fullDescription:
          'برنامه تمرینی کامل طراحی شده توسط هوش مصنوعی بر اساس اطلاعات شما',
      type: PaymentPlanType.aiProgram,
      accessLevel: PlanAccessLevel.basic,
      price: 500000, // 50 هزار تومان
      features: [
        'برنامه تمرینی 4 هفته‌ای',
        'تنظیمات بر اساس سطح تجربه',
        'حرکات متنوع',
        'راهنمای تصویری',
      ],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PaymentPlan(
      id: 'ai_premium',
      name: 'برنامه هوش مصنوعی پریمیم',
      shortDescription: 'برنامه پیشرفته با تحلیل دقیق',
      fullDescription:
          'برنامه تمرینی پیشرفته با تحلیل دقیق بدن و نیازهای خاص شما',
      type: PaymentPlanType.aiProgram,
      accessLevel: PlanAccessLevel.premium,
      price: 1000000, // 100 هزار تومان
      originalPrice: 1200000, // 120 هزار تومان
      isPopular: true,
      features: [
        'برنامه تمرینی 8 هفته‌ای',
        'تحلیل ترکیب بدن',
        'برنامه تغذیه همراه',
        'پیگیری هفتگی',
        'تنظیم خودکار بار تمرین',
      ],
      bonuses: {'free_consultation': true, 'bonus_credits': 100},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// طرح‌های اشتراک
  static List<PaymentPlan> get subscriptions => [
    PaymentPlan(
      id: 'monthly_basic',
      name: 'اشتراک ماهانه پایه',
      shortDescription: 'دسترسی به امکانات پایه',
      fullDescription: 'دسترسی کامل به امکانات پایه اپلیکیشن برای یک ماه',
      type: PaymentPlanType.subscription,
      accessLevel: PlanAccessLevel.basic,
      price: 2000000, // 200 هزار تومان
      validityDays: 31,
      features: [
        'برنامه‌های تمرینی نامحدود',
        'برنامه‌های تغذیه',
        'پیگیری پیشرفت',
        'چت با مربی‌ها',
      ],
      limitations: {'max_ai_requests': 5, 'max_programs': 10},
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PaymentPlan(
      id: 'monthly_premium',
      name: 'اشتراک ماهانه پریمیم',
      shortDescription: 'دسترسی کامل + ویژگی‌های پریمیم',
      fullDescription:
          'دسترسی کامل به تمام امکانات + ویژگی‌های پریمیم و پشتیبانی اولویت‌دار',
      type: PaymentPlanType.subscription,
      accessLevel: PlanAccessLevel.premium,
      price: 3500000, // 350 هزار تومان
      originalPrice: 4000000, // 400 هزار تومان
      validityDays: 31,
      isPopular: true,
      features: [
        'تمام ویژگی‌های پایه',
        'هوش مصنوعی نامحدود',
        'مشاوره اختصاصی',
        'محتوای پریمیم',
        'پشتیبانی اولویت‌دار',
      ],
      bonuses: {
        'free_consultation': true,
        'priority_support': true,
        'exclusive_content': true,
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];

  /// طرح‌های شارژ کیف پول
  static List<PaymentPlan> get walletCharges => [
    PaymentPlan(
      id: 'wallet_50k',
      name: 'شارژ 50 هزار تومانی',
      shortDescription: 'شارژ کیف پول',
      fullDescription: 'شارژ کیف پول به مبلغ 50 هزار تومان',
      type: PaymentPlanType.walletCharge,
      accessLevel: PlanAccessLevel.basic,
      price: 500000,
      features: ['شارژ فوری', 'بدون کارمزد'],
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
    PaymentPlan(
      id: 'wallet_100k',
      name: 'شارژ 100 هزار تومانی',
      shortDescription: 'شارژ کیف پول + 5% پاداش',
      fullDescription: 'شارژ کیف پول به مبلغ 100 هزار تومان + 5% پاداش اضافی',
      type: PaymentPlanType.walletCharge,
      accessLevel: PlanAccessLevel.basic,
      price: 1000000,
      features: ['شارژ فوری', '5% پاداش اضافی', 'بدون کارمزد'],
      bonuses: {
        'bonus_credits': 50000, // 5 هزار تومان پاداش
      },
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    ),
  ];
}
