import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت کیف پول
class WalletService {
  factory WalletService() => _instance;
  WalletService._internal();
  static final WalletService _instance = WalletService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// دریافت کیف پول کاربر (ایجاد خودکار در صورت عدم وجود)
  Future<Wallet?> getUserWallet() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) {
          print('کاربر وارد نشده است');
        }
        return null;
      }

      if (kDebugMode) {
        print('دریافت کیف پول برای کاربر: $userId');
      }

      // تلاش برای دریافت کیف پول موجود
      final response = await _client
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        if (kDebugMode) {
          print('کیف پول موجود پیدا شد');
        }
        return Wallet.fromJson(response);
      } else {
        // کیف پول وجود ندارد، ایجاد کیف پول جدید
        if (kDebugMode) {
          print('کیف پول وجود ندارد، در حال ایجاد کیف پول جدید...');
        }
        return await _createWallet(userId);
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت کیف پول: $e');
      }
      return null;
    }
  }

  /// ایجاد کیف پول برای کاربر (متد عمومی)
  Future<Wallet?> createUserWallet() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        if (kDebugMode) {
          print('کاربر وارد نشده است');
        }
        return null;
      }

      // بررسی وجود کیف پول
      if (await _walletExists(userId)) {
        if (kDebugMode) {
          print('کیف پول از قبل وجود دارد');
        }
        return await getUserWallet();
      }

      // ایجاد کیف پول جدید
      return await _createWallet(userId);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد کیف پول: $e');
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
        print('کیف پول شارژ شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در شارژ کیف پول: $e');
      }
      return false;
    }
  }

  /// پرداخت از کیف پول
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

      // بررسی موجودی کافی
      if (!wallet.hasEnoughBalance(amount)) {
        throw Exception(PaymentConstants.insufficientBalance);
      }

      final newBalance = wallet.balance - amount;
      final newAvailableBalance = wallet.availableBalance - amount;
      final newTotalSpent = wallet.totalSpent + amount;

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

      // اضافه کردن تراکنش کیف پول
      await _addWalletTransaction(
        walletId: wallet.id,
        userId: wallet.userId,
        type: WalletTransactionType.payment,
        amount: amount,
        balanceBefore: wallet.balance,
        balanceAfter: newBalance,
        description: description,
        referenceId: referenceId,
        metadata: metadata,
      );

      if (kDebugMode) {
        print('پرداخت از کیف پول: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پرداخت از کیف پول: $e');
      }
      return false;
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
        print(
          'بازگشت وجه به کیف پول: ${PaymentConstants.formatAmount(amount)}',
        );
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در بازگشت وجه: $e');
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
        print('پاداش اضافه شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در اضافه کردن پاداش: $e');
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

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'available_balance': newAvailableBalance,
            'blocked_balance': newBlockedBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      if (kDebugMode) {
        print('مبلغ مسدود شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در مسدود کردن مبلغ: $e');
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

      // به‌روزرسانی کیف پول
      await _client
          .from('wallets')
          .update({
            'available_balance': newAvailableBalance,
            'blocked_balance': newBlockedBalance,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      if (kDebugMode) {
        print('مبلغ آزاد شد: ${PaymentConstants.formatAmount(amount)}');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در آزاد کردن مبلغ: $e');
      }
      return false;
    }
  }

  /// دریافت تاریخچه تراکنش‌های کیف پول
  Future<List<WalletTransaction>> getWalletTransactions({
    int limit = 50,
    int offset = 0,
    WalletTransactionType? type,
  }) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return [];

      final baseQuery = _client
          .from('wallet_transactions')
          .select()
          .eq('user_id', userId);

      final filteredQuery = type != null
          ? baseQuery.eq('type', type.toString().split('.').last)
          : baseQuery;

      final orderedQuery = filteredQuery.order('created_at', ascending: false);

      final response = await orderedQuery.range(offset, offset + limit - 1);

      return response
          .map<WalletTransaction>(WalletTransaction.fromJson)
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تاریخچه کیف پول: $e');
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
        'current_balance': wallet.balance,
        'available_balance': wallet.availableBalance,
        'blocked_balance': wallet.blockedBalance,
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
        print('خطا در دریافت آمار کیف پول: $e');
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
        print('خطا در بررسی وجود کیف پول: $e');
      }
      return false;
    }
  }

  /// ایجاد کیف پول جدید برای کاربر
  Future<Wallet> _createWallet(String userId) async {
    try {
      if (kDebugMode) {
        print('شروع ایجاد کیف پول جدید برای کاربر: $userId');
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
        print('✅ کیف پول جدید با موفقیت ایجاد شد برای کاربر: $userId');
        print('کیف پول ID: ${response['id']}');
      }

      return Wallet.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('❌ خطا در ایجاد کیف پول: $e');
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
        print('خطا در اضافه کردن تراکنش کیف پول: $e');
      }
    }
  }
}
