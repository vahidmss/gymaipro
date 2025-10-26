import 'dart:convert';

// مدل کیف پول

/// نوع تراکنش کیف پول
enum WalletTransactionType {
  charge, // شارژ کیف پول
  payment, // پرداخت از کیف پول
  refund, // بازگشت وجه به کیف پول
  bonus, // پاداش
  cashback, // کش‌بک
  transferIn, // انتقال وجه به کیف پول
  transferOut, // انتقال وجه از کیف پول
}

class Wallet {
  const Wallet({
    required this.id,
    required this.userId,
    required this.createdAt,
    required this.updatedAt,
    this.balance = 0,
    this.availableBalance = 0,
    this.blockedBalance = 0,
    this.totalCharged = 0,
    this.totalSpent = 0,
    this.isActive = true,
    this.isVerified = false,
    this.minimumBalance = 0,
    this.maximumBalance = 100000000, // 10 میلیون تومان
    this.lastTransactionDate,
    this.metadata,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      balance: json['balance'] as int? ?? 0,
      availableBalance: json['available_balance'] as int? ?? 0,
      blockedBalance: json['blocked_balance'] as int? ?? 0,
      totalCharged: json['total_charged'] as int? ?? 0,
      totalSpent: json['total_spent'] as int? ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      isVerified: json['is_verified'] as bool? ?? false,
      minimumBalance: json['minimum_balance'] as int? ?? 0,
      maximumBalance: json['maximum_balance'] as int? ?? 100000000,
      lastTransactionDate: json['last_transaction_date'] != null
          ? DateTime.parse(json['last_transaction_date'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  /// شناسه کیف پول
  final String id;

  /// شناسه کاربر
  final String userId;

  /// موجودی کیف پول (ریال)
  final int balance;

  /// موجودی قابل برداشت (ریال)
  final int availableBalance;

  /// موجودی مسدود شده (ریال)
  final int blockedBalance;

  /// کل مبلغ شارژ شده (ریال)
  final int totalCharged;

  /// کل مبلغ خرج شده (ریال)
  final int totalSpent;

  /// آیا کیف پول فعال است؟
  final bool isActive;

  /// آیا کیف پول تأیید شده؟
  final bool isVerified;

  /// حد اقل موجودی (ریال)
  final int minimumBalance;

  /// حد اکثر موجودی (ریال)
  final int maximumBalance;

  /// تاریخ آخرین تراکنش
  final DateTime? lastTransactionDate;

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
      'balance': balance,
      'available_balance': availableBalance,
      'blocked_balance': blockedBalance,
      'total_charged': totalCharged,
      'total_spent': totalSpent,
      'is_active': isActive,
      'is_verified': isVerified,
      'minimum_balance': minimumBalance,
      'maximum_balance': maximumBalance,
      'last_transaction_date': lastTransactionDate?.toIso8601String(),
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  Wallet copyWith({
    String? id,
    String? userId,
    int? balance,
    int? availableBalance,
    int? blockedBalance,
    int? totalCharged,
    int? totalSpent,
    bool? isActive,
    bool? isVerified,
    int? minimumBalance,
    int? maximumBalance,
    DateTime? lastTransactionDate,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wallet(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      balance: balance ?? this.balance,
      availableBalance: availableBalance ?? this.availableBalance,
      blockedBalance: blockedBalance ?? this.blockedBalance,
      totalCharged: totalCharged ?? this.totalCharged,
      totalSpent: totalSpent ?? this.totalSpent,
      isActive: isActive ?? this.isActive,
      isVerified: isVerified ?? this.isVerified,
      minimumBalance: minimumBalance ?? this.minimumBalance,
      maximumBalance: maximumBalance ?? this.maximumBalance,
      lastTransactionDate: lastTransactionDate ?? this.lastTransactionDate,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// آیا موجودی کافی دارد؟
  bool hasEnoughBalance(int amount) => availableBalance >= amount;

  /// آیا می‌توان مبلغی را شارژ کرد؟
  bool canCharge(int amount) =>
      isActive && (balance + amount) <= maximumBalance;

  /// آیا کیف پول خالی است؟
  bool get isEmpty => balance <= 0;

  /// آیا نیاز به شارژ دارد؟
  bool get needsCharge => availableBalance <= minimumBalance;

  /// فرمت موجودی به تومان
  String get formattedBalance => '${(balance / 10).toStringAsFixed(0)} تومان';

  /// فرمت موجودی قابل برداشت به تومان
  String get formattedAvailableBalance =>
      '${(availableBalance / 10).toStringAsFixed(0)} تومان';

  /// فرمت موجودی مسدود شده به تومان
  String get formattedBlockedBalance =>
      '${(blockedBalance / 10).toStringAsFixed(0)} تومان';

  /// فرمت کل شارژ شده به تومان
  String get formattedTotalCharged =>
      '${(totalCharged / 10).toStringAsFixed(0)} تومان';

  /// فرمت کل خرج شده به تومان
  String get formattedTotalSpent =>
      '${(totalSpent / 10).toStringAsFixed(0)} تومان';

  /// وضعیت کیف پول
  String get statusText {
    if (!isActive) return 'غیرفعال';
    if (!isVerified) return 'تأیید نشده';
    if (needsCharge) return 'نیاز به شارژ';
    return 'فعال';
  }

  /// رنگ وضعیت
  String get statusColor {
    if (!isActive) return '#F44336'; // قرمز
    if (!isVerified) return '#FF9800'; // نارنجی
    if (needsCharge) return '#FFC107'; // زرد
    return '#4CAF50'; // سبز
  }

  @override
  String toString() {
    return 'Wallet{id: $id, balance: $formattedBalance, status: $statusText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Wallet && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class WalletTransaction {
  const WalletTransaction({
    required this.id,
    required this.walletId,
    required this.userId,
    required this.type,
    required this.amount,
    required this.balanceBefore,
    required this.balanceAfter,
    required this.description,
    required this.createdAt,
    this.referenceId,
    this.metadata,
  });

  factory WalletTransaction.fromJson(Map<String, dynamic> json) {
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

    return WalletTransaction(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      userId: json['user_id'] as String,
      type: WalletTransactionType.values.firstWhere(
        (e) => e.toString().split('.').last == json['type'],
        orElse: () => WalletTransactionType.payment,
      ),
      amount: (json['amount'] as num).toInt(),
      balanceBefore: (json['balance_before'] as num).toInt(),
      balanceAfter: (json['balance_after'] as num).toInt(),
      description: json['description'] as String,
      referenceId: json['reference_id'] as String?,
      metadata: parsedMetadata,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  /// شناسه تراکنش
  final String id;

  /// شناسه کیف پول
  final String walletId;

  /// شناسه کاربر
  final String userId;

  /// نوع تراکنش
  final WalletTransactionType type;

  /// مبلغ (ریال)
  final int amount;

  /// موجودی قبل از تراکنش (ریال)
  final int balanceBefore;

  /// موجودی بعد از تراکنش (ریال)
  final int balanceAfter;

  /// توضیحات
  final String description;

  /// شناسه مرجع (مثل شناسه تراکنش پرداخت)
  final String? referenceId;

  /// اطلاعات اضافی
  final Map<String, dynamic>? metadata;

  /// تاریخ ایجاد
  final DateTime createdAt;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'wallet_id': walletId,
      'user_id': userId,
      'type': type.toString().split('.').last,
      'amount': amount,
      'balance_before': balanceBefore,
      'balance_after': balanceAfter,
      'description': description,
      'reference_id': referenceId,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// کپی با تغییرات
  WalletTransaction copyWith({
    String? id,
    String? walletId,
    String? userId,
    WalletTransactionType? type,
    int? amount,
    int? balanceBefore,
    int? balanceAfter,
    String? description,
    String? referenceId,
    Map<String, dynamic>? metadata,
    DateTime? createdAt,
  }) {
    return WalletTransaction(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      balanceBefore: balanceBefore ?? this.balanceBefore,
      balanceAfter: balanceAfter ?? this.balanceAfter,
      description: description ?? this.description,
      referenceId: referenceId ?? this.referenceId,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// آیا تراکنش مثبت است؟ (افزایش موجودی)
  bool get isPositive =>
      type == WalletTransactionType.charge ||
      type == WalletTransactionType.refund ||
      type == WalletTransactionType.bonus ||
      type == WalletTransactionType.cashback ||
      type == WalletTransactionType.transferIn;

  /// آیا تراکنش منفی است؟ (کاهش موجودی)
  bool get isNegative => !isPositive;

  /// فرمت مبلغ به تومان
  String get formattedAmount => '${(amount / 10).toStringAsFixed(0)} تومان';

  /// فرمت موجودی قبل به تومان
  String get formattedBalanceBefore =>
      '${(balanceBefore / 10).toStringAsFixed(0)} تومان';

  /// فرمت موجودی بعد به تومان
  String get formattedBalanceAfter =>
      '${(balanceAfter / 10).toStringAsFixed(0)} تومان';

  /// متن نوع تراکنش به فارسی
  String get typeText {
    switch (type) {
      case WalletTransactionType.charge:
        return 'شارژ کیف پول';
      case WalletTransactionType.payment:
        return 'پرداخت';
      case WalletTransactionType.refund:
        return 'بازگشت وجه';
      case WalletTransactionType.bonus:
        return 'پاداش';
      case WalletTransactionType.cashback:
        return 'کش‌بک';
      case WalletTransactionType.transferIn:
        return 'واریز';
      case WalletTransactionType.transferOut:
        return 'برداشت';
    }
  }

  /// آیکون تراکنش
  String get icon {
    switch (type) {
      case WalletTransactionType.charge:
        return '💰';
      case WalletTransactionType.payment:
        return '💸';
      case WalletTransactionType.refund:
        return '↩️';
      case WalletTransactionType.bonus:
        return '🎁';
      case WalletTransactionType.cashback:
        return '💎';
      case WalletTransactionType.transferIn:
        return '⬇️';
      case WalletTransactionType.transferOut:
        return '⬆️';
    }
  }

  /// رنگ تراکنش
  String get color {
    return isPositive ? '#4CAF50' : '#F44336'; // سبز یا قرمز
  }

  /// متن تغییر موجودی
  String get changeText {
    final sign = isPositive ? '+' : '-';
    return '$sign$formattedAmount';
  }

  @override
  String toString() {
    return 'WalletTransaction{id: $id, type: $typeText, amount: $changeText}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WalletTransaction &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
