import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت کیف پول
class WalletService {
  factory WalletService() => _instance;
  WalletService._internal();
  static final WalletService _instance = WalletService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  Wallet? _cachedWallet;
  String? _cachedWalletUserId;
  DateTime? _cachedWalletAt;
  Future<Wallet?>? _inFlightWallet;
  static const Duration _walletCacheTtl = Duration(seconds: 20);

  void _invalidateWalletCache() {
    _cachedWallet = null;
    _cachedWalletUserId = null;
    _cachedWalletAt = null;
    _inFlightWallet = null;
  }

  /// پاک کردن کش و دریافت مجدد موجودی (بعد از شارژ آنلاین)
  Future<Wallet?> refreshUserWallet() async {
    _invalidateWalletCache();
    return getUserWallet();
  }

  /// در این پروژه، برای بسیاری از جدول‌ها `user_id` به `profiles.id` وصل است (نه `auth.users.id`).
  /// پس برای جلوگیری از خطای FK باید profileId را استفاده کنیم.
  /// اگر پروفایل پیدا نشد، retry می‌کنیم (ممکن است مشکل connection باشد)
  Future<String?> _getEffectiveUserId() async {
    int retryCount = 0;
    const maxRetries = 3;

    while (retryCount < maxRetries) {
      try {
        final profile = await SimpleProfileService.getCurrentProfile();
        final id = profile?['id'] as String?;
        if (id != null && id.isNotEmpty) return id;

        // اگر پروفایل پیدا نشد و retry باقی مانده، دوباره تلاش می‌کنیم
        if (retryCount < maxRetries - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (retryCount + 1)),
          );
          retryCount++;
        } else {
          break;
        }
      } catch (e) {
        if (kDebugMode) {
          debugPrint(
            'WALLET_SERVICE: Error getting profile (attempt ${retryCount + 1}/$maxRetries): $e',
          );
        }

        // اگر retry باقی مانده، دوباره تلاش می‌کنیم
        if (retryCount < maxRetries - 1) {
          await Future<void>.delayed(
            Duration(milliseconds: 500 * (retryCount + 1)),
          );
          retryCount++;
        } else {
          break;
        }
      }
    }

    // اگر بعد از retry هم پروفایل پیدا نشد، null برمی‌گردانیم
    // (نه authUserId چون constraint به profiles reference می‌کند)
    if (kDebugMode) {
      debugPrint(
        'WALLET_SERVICE: Profile not found after $maxRetries attempts, returning null',
      );
    }
    return null;
  }

  /// دریافت کیف پول کاربر (ایجاد خودکار در صورت عدم وجود)
  Future<Wallet?> getUserWallet() async {
    try {
      final userId = await _getEffectiveUserId();
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('کاربر وارد نشده است');
        }
        return null;
      }

      if (_cachedWallet != null &&
          _cachedWalletUserId == userId &&
          _cachedWalletAt != null &&
          DateTime.now().difference(_cachedWalletAt!) < _walletCacheTtl) {
        return _cachedWallet;
      }

      if (_inFlightWallet != null) {
        return await _inFlightWallet;
      }

      _inFlightWallet = () async {
        if (kDebugMode) {
          debugPrint('دریافت کیف پول برای کاربر: $userId');
        }

        final response = await _client
            .from('wallets')
            .select()
            .eq('user_id', userId)
            .maybeSingle();

        final wallet = response != null
            ? Wallet.fromJson(response)
            : await _createWallet(userId);

        if (kDebugMode && response != null) {
          debugPrint('کیف پول موجود پیدا شد');
        }
        if (kDebugMode && response == null) {
          debugPrint('کیف پول وجود ندارد، در حال ایجاد کیف پول جدید...');
        }

        _cachedWallet = wallet;
        _cachedWalletUserId = userId;
        _cachedWalletAt = DateTime.now();
        return wallet;
      }();

      return await _inFlightWallet;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در دریافت کیف پول: $e');
      }
      return null;
    } finally {
      _inFlightWallet = null;
    }
  }

  /// ایجاد کیف پول برای کاربر (متد عمومی)
  Future<Wallet?> createUserWallet() async {
    try {
      final userId = await _getEffectiveUserId();
      if (userId == null) {
        if (kDebugMode) {
          debugPrint('کاربر وارد نشده است');
        }
        return null;
      }

      // بررسی وجود کیف پول
      if (await _walletExists(userId)) {
        if (kDebugMode) {
          debugPrint('کیف پول از قبل وجود دارد');
        }
        return await getUserWallet();
      }

      // ایجاد کیف پول جدید
      return await _createWallet(userId);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در ایجاد کیف پول: $e');
      }
      return null;
    }
  }

  /// شارژ کیف پول
  Future<bool> chargeWallet({
    required int amount,
    required String transactionId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return false;

      // بررسی اعتبار مبلغ
      if (!PaymentConstants.isValidWalletChargeAmount(amount)) {
        throw Exception(PaymentConstants.invalidAmount);
      }

      // بررسی حداکثر موجودی
      if (!wallet.canCharge(amount)) {
        throw Exception('مبلغ شارژ بیش از حد مجاز است');
      }

      final newBalance = wallet.balance + amount;
      final newAvailableBalance = wallet.availableBalance + amount;
      final newTotalCharged = wallet.totalCharged + amount;

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'total_charged': newTotalCharged,
            'last_transaction_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      // اضافه کردن تراکنش کیف پول
      await _addWalletTransaction(
        walletId: wallet.id,
        userId: wallet.userId,
        type: WalletTransactionType.charge,
        amount: amount,
        balanceBefore: wallet.balance,
        balanceAfter: newBalance,
        description: description ?? 'شارژ کیف پول',
        referenceId: transactionId,
        metadata: metadata,
      );

      if (kDebugMode) {
        debugPrint('کیف پول شارژ شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در شارژ کیف پول: $e');
      }
      return false;
    }
  }

  /// پرداخت از کیف پول
  /// منطق پرداخت:
  /// - مبلغ فقط از [available_balance] (موجودی قابل برداشت) کسر می‌شود.
  /// - همزمان [balance] (کل موجودی) هم به‌همان مقدار کم می‌شود؛
  ///   رابطه: balance = available_balance + blocked_balance
  /// - اگر بعد از کسر، هر کدام از available_balance یا balance منفی شود،
  ///   خطا پرتاب می‌شود (موجودی کافی نیست یا ناسازگاری در دیتا).
  Future<bool> payFromWallet({
    required int amount,
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) {
        throw Exception(PaymentConstants.walletNotFound);
      }

      // بررسی موجودی کافی - فقط available_balance بررسی می‌شود
      if (wallet.availableBalance < amount) {
        throw Exception(PaymentConstants.insufficientBalance);
      }

      // کسر: معیار «موجودی کافی» فقط available_balance است
      final newAvailableBalance = wallet.availableBalance - amount;
      final newBalance = wallet.balance - amount;
      final newTotalSpent = wallet.totalSpent + amount;

      if (newAvailableBalance < 0) {
        throw Exception(PaymentConstants.insufficientBalance);
      }
      // جلوگیری از نقض CHECK (balance >= 0) در دیتابیس؛ در صورت منفی بودن همان خطای موجودی
      if (newBalance < 0) {
        throw Exception(PaymentConstants.insufficientBalance);
      }

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'total_spent': newTotalSpent,
            'last_transaction_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      try {
        // اضافه کردن تراکنش کیف پول (از available_balance استفاده می‌کنیم)
        await _addWalletTransaction(
          walletId: wallet.id,
          userId: wallet.userId,
          type: WalletTransactionType.payment,
          amount: amount,
          balanceBefore: wallet.availableBalance,
          balanceAfter: newAvailableBalance,
          description: description,
          referenceId: referenceId,
          metadata: metadata,
        );
      } catch (e) {
        if (kDebugMode) {
          debugPrint('خطا در ثبت تراکنش کیف پول، در حال بازگرداندن موجودی: $e');
        }
        // بازگرداندن موجودی در صورت شکست ثبت تراکنش (RLS یا شبکه)
        await _client
            .from('wallets')
            .update({
              'balance': wallet.balance,
              'available_balance': wallet.availableBalance,
              'total_spent': wallet.totalSpent,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', wallet.id);
        _invalidateWalletCache();
        rethrow;
      }

      if (kDebugMode) {
        debugPrint('پرداخت از کیف پول: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در پرداخت از کیف پول: $e');
      }
      rethrow;
    }
  }

  /// بازگشت وجه به کیف پول
  Future<bool> refundToWallet({
    required int amount,
    required String transactionId,
    String? description,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return false;

      final newBalance = wallet.balance + amount;
      final newAvailableBalance = wallet.availableBalance + amount;

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'last_transaction_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      // اضافه کردن تراکنش کیف پول
      await _addWalletTransaction(
        walletId: wallet.id,
        userId: wallet.userId,
        type: WalletTransactionType.refund,
        amount: amount,
        balanceBefore: wallet.balance,
        balanceAfter: newBalance,
        description: description ?? 'بازگشت وجه',
        referenceId: transactionId,
        metadata: metadata,
      );

      if (kDebugMode) {
        debugPrint(
          'بازگشت وجه به کیف پول: ${PaymentConstants.formatAmount(amount)}',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در بازگشت وجه: $e');
      }
      return false;
    }
  }

  /// اضافه کردن پاداش به کیف پول
  Future<bool> addBonus({
    required int amount,
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return false;

      final newBalance = wallet.balance + amount;
      final newAvailableBalance = wallet.availableBalance + amount;

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'last_transaction_date': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      // اضافه کردن تراکنش کیف پول
      await _addWalletTransaction(
        walletId: wallet.id,
        userId: wallet.userId,
        type: WalletTransactionType.bonus,
        amount: amount,
        balanceBefore: wallet.balance,
        balanceAfter: newBalance,
        description: description,
        referenceId: referenceId,
        metadata: metadata,
      );

      if (kDebugMode) {
        debugPrint('پاداش اضافه شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در اضافه کردن پاداش: $e');
      }
      return false;
    }
  }

  /// مسدود کردن مبلغی از کیف پول
  Future<bool> blockAmount({
    required int amount,
    required String description,
    String? referenceId,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return false;

      if (!wallet.hasEnoughBalance(amount)) {
        throw Exception(PaymentConstants.insufficientBalance);
      }

      final newAvailableBalance = wallet.availableBalance - amount;
      final newBlockedBalance = wallet.blockedBalance + amount;
      // balance = available_balance + blocked_balance (همیشه باید برقرار باشد)
      final newBalance = newAvailableBalance + newBlockedBalance;

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'blocked_balance': newBlockedBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      if (kDebugMode) {
        debugPrint('مبلغ مسدود شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در مسدود کردن مبلغ: $e');
      }
      return false;
    }
  }

  /// آزاد کردن مبلغ مسدود شده
  Future<bool> unblockAmount({
    required int amount,
    required String description,
    String? referenceId,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return false;

      if (wallet.blockedBalance < amount) {
        throw Exception('مبلغ مسدود شده کافی نیست');
      }

      final newAvailableBalance = wallet.availableBalance + amount;
      final newBlockedBalance = wallet.blockedBalance - amount;
      // balance = available_balance + blocked_balance (همیشه باید برقرار باشد)
      final newBalance = newAvailableBalance + newBlockedBalance;

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'balance': newBalance,
            'available_balance': newAvailableBalance,
            'blocked_balance': newBlockedBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);
      _invalidateWalletCache();

      if (kDebugMode) {
        debugPrint('مبلغ آزاد شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در آزاد کردن مبلغ: $e');
      }
      return false;
    }
  }

  /// دریافت تاریخچه تراکنش‌های کیف پول
  /// از wallet جاری کاربر (profile-based) استفاده می‌کند تا با RLS و user_id یکسان باشد.
  Future<List<WalletTransaction>> getWalletTransactions({
    int limit = 50,
    int offset = 0,
    WalletTransactionType? type,
  }) async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) {
        if (kDebugMode) {
          debugPrint('WALLET_TX: کیف پول یافت نشد (getUserWallet null)');
        }
        return [];
      }

      var query = _client
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', wallet.id);

      if (type != null) {
        query = query.eq('type', type.toString().split('.').last);
      }

      final raw = await query
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      final list = raw as List<dynamic>;
      final transactions = list
          .map<WalletTransaction>(
            (e) => WalletTransaction.fromJson(e as Map<String, dynamic>),
          )
          .toList();

      if (kDebugMode) {
        debugPrint(
          'WALLET_TX: wallet_id=${wallet.id}, تعداد تراکنش‌ها=${transactions.length}',
        );
      }

      return transactions;
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('خطا در دریافت تاریخچه کیف پول: $e');
        debugPrint('WALLET_TX stack: $st');
      }
      return [];
    }
  }

  /// دریافت آمار کیف پول
  Future<Map<String, dynamic>> getWalletStats() async {
    try {
      final wallet = await getUserWallet();
      if (wallet == null) return {};

      final transactions = await getWalletTransactions(limit: 1000);

      final chargeTransactions = transactions.where(
        (t) => t.type == WalletTransactionType.charge,
      );
      final paymentTransactions = transactions.where(
        (t) => t.type == WalletTransactionType.payment,
      );
      final bonusTransactions = transactions.where(
        (t) => t.type == WalletTransactionType.bonus,
      );

      return {
        'current_balance':
            wallet.availableBalance, // استفاده از available_balance
        'available_balance': wallet.availableBalance,
        'blocked_balance': wallet.blockedBalance,
        'total_balance': wallet.balance, // کل موجودی (available + blocked)
        'total_charged': wallet.totalCharged,
        'total_spent': wallet.totalSpent,
        'total_transactions': transactions.length,
        'charge_count': chargeTransactions.length,
        'payment_count': paymentTransactions.length,
        'bonus_count': bonusTransactions.length,
        'last_transaction_date': wallet.lastTransactionDate?.toIso8601String(),
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در دریافت آمار کیف پول: $e');
      }
      return {};
    }
  }

  /// متدهای کمکی خصوصی

  /// بررسی وجود کیف پول برای کاربر
  Future<bool> _walletExists(String userId) async {
    try {
      final response = await _client
          .from('wallets')
          .select('id')
          .eq('user_id', userId)
          .maybeSingle();

      return response != null;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در بررسی وجود کیف پول: $e');
      }
      return false;
    }
  }

  /// ایجاد کیف پول جدید برای کاربر
  Future<Wallet> _createWallet(String userId) async {
    try {
      if (kDebugMode) {
        debugPrint('شروع ایجاد کیف پول جدید برای کاربر: $userId');
      }

      final walletData = {
        'user_id': userId,
        'balance': 0,
        'available_balance': 0,
        'blocked_balance': 0,
        'total_charged': 0,
        'total_spent': 0,
        'is_active': true,
        'is_verified': false,
        'minimum_balance': 10000,
        'maximum_balance': 100000000,
      };

      final response = await _client
          .from('wallets')
          .insert(walletData)
          .select()
          .single();

      if (kDebugMode) {
        debugPrint('✅ کیف پول جدید با موفقیت ایجاد شد برای کاربر: $userId');
        debugPrint('کیف پول ID: ${response['id']}');
      }

      return Wallet.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ خطا در ایجاد کیف پول: $e');
      }
      rethrow;
    }
  }

  Future<void> _addWalletTransaction({
    required String walletId,
    required String userId,
    required WalletTransactionType type,
    required int amount,
    required int balanceBefore,
    required int balanceAfter,
    required String description,
    String? referenceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final transactionData = {
        'id': PaymentConstants.generateTransactionId(),
        'wallet_id': walletId,
        'user_id': userId,
        'type': type.toString().split('.').last,
        'amount': amount,
        'balance_before': balanceBefore,
        'balance_after': balanceAfter,
        'description': description,
        'reference_id': referenceId,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _client.from('wallet_transactions').insert(transactionData);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('خطا در اضافه کردن تراکنش کیف پول: $e');
      }
      rethrow;
    }
  }
}
