import 'dart:convert';

// مدل تراکنش پرداخت

/// انواع تراکنش پرداخت
enum TransactionType {
  payment, // پرداخت
  refund, // بازپرداخت
  walletCharge, // شارژ کیف پول
  walletPayment, // پرداخت از کیف پول
  subscription, // پرداخت اشتراک
  aiProgram, // پرداخت برنامه AI
  trainerService, // پرداخت خدمات مربی
}

/// وضعیت تراکنش
enum TransactionStatus {
  pending, // در انتظار
  processing, // در حال پردازش
  completed, // تکمیل شده
  failed, // ناموفق
  cancelled, // لغو شده
  refunded, // بازپرداخت شده
}

/// روش پرداخت
enum PaymentMethod {
  direct, // پرداخت مستقیم
  wallet, // کیف پول
  mixed, // ترکیبی (کیف پول + پرداخت مستقیم)
}

/// درگاه پرداخت
enum PaymentGateway {
  zibal, // زیبال
  zarinpal, // زرین‌پال
  wallet, // کیف پول داخلی
}

class PaymentTransaction {
  const PaymentTransaction({
    required this.id,
    required this.userId,
    required this.amount,
    required this.finalAmount,
    required this.type,
    required this.status,
    required this.paymentMethod,
    required this.gateway,
    required this.description,
    required this.createdAt,
    required this.updatedAt,
    this.discountAmount = 0,
    this.discountCode,
    this.gatewayTransactionId,
    this.gatewayTrackingCode,
    this.metadata,
    this.userIp,
    this.userName,
    this.completedAt,
    this.expiresAt,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    // parse metadata which may be stored as JSON string or object
    final dynamic rawMetadata = json['metadata'];
    Map<String, dynamic>? parsedMetadata;
    if (rawMetadata is String && rawMetadata.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawMetadata);
        if (decoded is Map<String, dynamic>) {
          parsedMetadata = decoded;
        }
      } catch (_) {
        parsedMetadata = null;
      }
    } else if (rawMetadata is Map<String, dynamic>) {
      parsedMetadata = rawMetadata;
    }

    return PaymentTransaction(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      amount: (json['amount'] as num).toInt(),
      finalAmount: (json['final_amount'] as num).toInt(),
      discountAmount: (json['discount_amount'] as num?)?.toInt() ?? 0,
      discountCode: json['discount_code'] as String?,
      type: _typeFromDb(json['type'] as String),
      status: TransactionStatus.values.firstWhere(
        (e) => e.toString().split('.').last == json['status'],
        orElse: () => TransactionStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == json['payment_method'],
        orElse: () => PaymentMethod.direct,
      ),
      gateway: PaymentGateway.values.firstWhere(
        (e) => e.toString().split('.').last == json['gateway'],
        orElse: () => PaymentGateway.zibal,
      ),
      gatewayTransactionId: json['gateway_transaction_id'] as String?,
      gatewayTrackingCode: json['gateway_tracking_code'] as String?,
      description: json['description'] as String,
      metadata: parsedMetadata,
      userIp: json['user_ip'] as String?,
      userName: json['user_name'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'] as String)
          : null,
      expiresAt: json['expires_at'] != null
          ? DateTime.parse(json['expires_at'] as String)
          : null,
    );
  }

  /// شناسه تراکنش
  final String id;

  /// شناسه کاربر
  final String userId;

  /// مبلغ (ریال)
  final int amount;

  /// مبلغ نهایی بعد از تخفیف (ریال)
  final int finalAmount;

  /// مبلغ تخفیف (ریال)
  final int discountAmount;

  /// کد تخفیف استفاده شده
  final String? discountCode;

  /// نوع تراکنش
  final TransactionType type;

  /// وضعیت تراکنش
  final TransactionStatus status;

  /// روش پرداخت
  final PaymentMethod paymentMethod;

  /// درگاه پرداخت
  final PaymentGateway gateway;

  /// شناسه تراکنش در درگاه
  final String? gatewayTransactionId;

  /// شناسه پیگیری درگاه
  final String? gatewayTrackingCode;

  /// توضیحات
  final String description;

  /// اطلاعات اضافی (JSON)
  final Map<String, dynamic>? metadata;

  /// آدرس IP کاربر
  final String? userIp;

  /// نام کاربر در زمان تراکنش
  final String? userName;

  /// تاریخ ایجاد
  final DateTime createdAt;

  /// تاریخ به‌روزرسانی
  final DateTime updatedAt;

  /// تاریخ تکمیل تراکنش
  final DateTime? completedAt;

  /// تاریخ انقضا
  final DateTime? expiresAt;

  static TransactionType _typeFromDb(String value) {
    switch (value) {
      case 'payment':
        return TransactionType.payment;
      case 'refund':
        return TransactionType.refund;
      case 'wallet_charge':
        return TransactionType.walletCharge;
      case 'wallet_payment':
        return TransactionType.walletPayment;
      case 'subscription':
        return TransactionType.subscription;
      case 'ai_program':
        return TransactionType.aiProgram;
      case 'trainer_service':
        return TransactionType.trainerService;
      default:
        // fallback to direct enum match if stored as camelCase
        return TransactionType.values.firstWhere(
          (e) => e.toString().split('.').last == value,
          orElse: () => TransactionType.payment,
        );
    }
  }

  static String _typeToDb(TransactionType type) {
    switch (type) {
      case TransactionType.payment:
        return 'payment';
      case TransactionType.refund:
        return 'refund';
      case TransactionType.walletCharge:
        return 'wallet_charge';
      case TransactionType.walletPayment:
        return 'wallet_payment';
      case TransactionType.subscription:
        return 'subscription';
      case TransactionType.aiProgram:
        return 'ai_program';
      case TransactionType.trainerService:
        return 'trainer_service';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'amount': amount,
      'final_amount': finalAmount,
      'discount_amount': discountAmount,
      'discount_code': discountCode,
      'type': _typeToDb(type),
      'status': status.toString().split('.').last,
      'payment_method': paymentMethod.toString().split('.').last,
      'gateway': gateway.toString().split('.').last,
      'gateway_transaction_id': gatewayTransactionId,
      'gateway_tracking_code': gatewayTrackingCode,
      'description': description,
      'metadata': metadata,
      'user_ip': userIp,
      'user_name': userName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  PaymentTransaction copyWith({
    String? id,
    String? userId,
    int? amount,
    int? finalAmount,
    int? discountAmount,
    String? discountCode,
    TransactionType? type,
    TransactionStatus? status,
    PaymentMethod? paymentMethod,
    PaymentGateway? gateway,
    String? gatewayTransactionId,
    String? gatewayTrackingCode,
    String? description,
    Map<String, dynamic>? metadata,
    String? userIp,
    String? userName,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    DateTime? expiresAt,
  }) {
    return PaymentTransaction(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      finalAmount: finalAmount ?? this.finalAmount,
      discountAmount: discountAmount ?? this.discountAmount,
      discountCode: discountCode ?? this.discountCode,
      type: type ?? this.type,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      gateway: gateway ?? this.gateway,
      gatewayTransactionId: gatewayTransactionId ?? this.gatewayTransactionId,
      gatewayTrackingCode: gatewayTrackingCode ?? this.gatewayTrackingCode,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      userIp: userIp ?? this.userIp,
      userName: userName ?? this.userName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  /// آیا تراکنش موفق بوده؟
  bool get isSuccessful => status == TransactionStatus.completed;

  /// آیا تراکنش در انتظار است؟
  bool get isPending => status == TransactionStatus.pending;

  /// آیا تراکنش ناموفق بوده؟
  bool get isFailed =>
      status == TransactionStatus.failed ||
      status == TransactionStatus.cancelled;

  /// آیا تراکنش منقضی شده؟
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  /// درصد تخفیف
  double get discountPercentage =>
      amount > 0 ? (discountAmount / amount) * 100 : 0;

  /// فرمت مبلغ به تومان
  String get formattedAmount => '${(amount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ نهایی به تومان
  String get formattedFinalAmount =>
      '${(finalAmount / 10).toStringAsFixed(0)} تومان';

  /// فرمت مبلغ تخفیف به تومان
  String get formattedDiscountAmount =>
      '${(discountAmount / 10).toStringAsFixed(0)} تومان';

  /// متن وضعیت به فارسی
  String get statusText {
    switch (status) {
      case TransactionStatus.pending:
        return 'در انتظار پرداخت';
      case TransactionStatus.processing:
        return 'در حال پردازش';
      case TransactionStatus.completed:
        return 'پرداخت موفق';
      case TransactionStatus.failed:
        return 'پرداخت ناموفق';
      case TransactionStatus.cancelled:
        return 'لغو شده';
      case TransactionStatus.refunded:
        return 'بازپرداخت شده';
    }
  }

  /// متن نوع تراکنش به فارسی
  String get typeText {
    switch (type) {
      case TransactionType.payment:
        return 'پرداخت';
      case TransactionType.refund:
        return 'بازپرداخت';
      case TransactionType.walletCharge:
        return 'شارژ کیف پول';
      case TransactionType.walletPayment:
        return 'پرداخت از کیف پول';
      case TransactionType.subscription:
        return 'پرداخت اشتراک';
      case TransactionType.aiProgram:
        return 'برنامه هوش مصنوعی';
      case TransactionType.trainerService:
        return 'خدمات مربی';
    }
  }

  /// متن درگاه پرداخت به فارسی
  String get gatewayText {
    switch (gateway) {
      case PaymentGateway.zibal:
        return 'زیبال';
      case PaymentGateway.zarinpal:
        return 'زرین‌پال';
      case PaymentGateway.wallet:
        return 'کیف پول';
    }
  }

  @override
  String toString() {
    return 'PaymentTransaction{id: $id, amount: $formattedAmount, status: $statusText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PaymentTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
