import 'package:flutter/foundation.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/models/payout_request.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/commission_service.dart';
import 'package:gymaipro/payment/utils/card_encryption_helper.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت درخواست‌های برداشت
class PayoutService {
  factory PayoutService() => _instance;
  PayoutService._internal();
  static final PayoutService _instance = PayoutService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final CommissionService _commissionService = CommissionService();

  /// ایجاد درخواست برداشت
  Future<Map<String, dynamic>> createPayoutRequest({
    required int amount,
    required String cardNumber,
    required String cardOwnerName,
    String? bankName,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      if (amount <= 0) {
        return {'success': false, 'error': 'مبلغ باید بیشتر از صفر باشد'};
      }

      // بررسی حداقل مبلغ برداشت
      if (amount < PaymentConstants.minWithdrawalAmount) {
        return {
          'success': false,
          'error':
              'حداقل مبلغ برداشت ${PaymentConstants.formatAmount(PaymentConstants.minWithdrawalAmount)} است',
          'min_amount': PaymentConstants.minWithdrawalAmount,
        };
      }

      // بررسی حداکثر مبلغ برداشت
      if (amount > PaymentConstants.maxWithdrawalAmount) {
        return {
          'success': false,
          'error':
              'حداکثر مبلغ برداشت ${PaymentConstants.formatAmount(PaymentConstants.maxWithdrawalAmount)} است',
          'max_amount': PaymentConstants.maxWithdrawalAmount,
        };
      }

      // Rate Limiting: بررسی تعداد درخواست‌های امروز
      final todayStart = DateTime.now().copyWith(
        hour: 0,
        minute: 0,
        second: 0,
        millisecond: 0,
        microsecond: 0,
      );
      final todayRequests = await _client
          .from('payout_requests')
          .select('id, created_at')
          .eq('trainer_id', userId)
          .gte('created_at', todayStart.toIso8601String())
          .count();

      if (todayRequests.count >= PaymentConstants.maxPayoutRequestsPerDay) {
        return {
          'success': false,
          'error':
              'شما بیش از حد مجاز درخواست داده‌اید. لطفاً فردا دوباره تلاش کنید.',
          'max_per_day': PaymentConstants.maxPayoutRequestsPerDay,
        };
      }

      // Rate Limiting: بررسی فاصله زمانی بین درخواست‌ها
      final lastRequest = await _client
          .from('payout_requests')
          .select('created_at')
          .eq('trainer_id', userId)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (lastRequest != null) {
        final lastRequestDate = DateTime.parse(
          lastRequest['created_at'] as String,
        );
        final hoursSinceLastRequest = DateTime.now()
            .difference(lastRequestDate)
            .inHours;

        if (hoursSinceLastRequest <
            PaymentConstants.minHoursBetweenPayoutRequests) {
          final remainingHours =
              PaymentConstants.minHoursBetweenPayoutRequests -
              hoursSinceLastRequest;
          return {
            'success': false,
            'error': 'لطفاً $remainingHours ساعت دیگر دوباره تلاش کنید',
            'remaining_hours': remainingHours,
          };
        }
      }

      // محاسبه موجودی قابل برداشت (بعد از 3 روز)
      final withdrawable = await getTrainerWithdrawable(userId);
      if (amount > withdrawable) {
        return {
          'success': false,
          'error': 'مبلغ درخواستی بیشتر از موجودی قابل برداشت است',
          'available': withdrawable,
        };
      }

      // بررسی اینکه آیا درخواست pending یا approved دیگری وجود دارد
      final existingRequests = await _client
          .from('payout_requests')
          .select('id, amount')
          .eq('trainer_id', userId)
          .or(
            'status.eq.${PayoutRequestStatus.pending.toString().split('.').last},status.eq.${PayoutRequestStatus.approved.toString().split('.').last}',
          );

      int totalPendingAmount = 0;
      for (final req in (existingRequests as List<dynamic>)) {
        totalPendingAmount += req['amount'] as int? ?? 0;
      }

      // بررسی اینکه آیا با درخواست جدید، مجموع از withdrawable بیشتر می‌شود
      if ((totalPendingAmount + amount) > withdrawable) {
        return {
          'success': false,
          'error':
              'مجموع درخواست‌های در حال بررسی بیشتر از موجودی قابل برداشت است',
          'available': withdrawable,
          'pending': totalPendingAmount,
        };
      }

      // بررسی اعتبار شماره کارت
      if (!CardEncryptionHelper.isValidCardNumber(cardNumber)) {
        return {'success': false, 'error': 'شماره کارت نامعتبر است'};
      }

      // Hash کردن شماره کارت برای ذخیره امن
      final hashedCardNumber = CardEncryptionHelper.hashCardNumber(cardNumber);

      // ایجاد درخواست
      final response = await _client
          .from('payout_requests')
          .insert({
            'trainer_id': userId,
            'amount': amount,
            'card_number': hashedCardNumber, // ذخیره hash شده
            'card_owner_name': cardOwnerName,
            'bank_name': bankName,
            'status': PayoutRequestStatus.pending.toString().split('.').last,
          })
          .select()
          .single();

      final request = PayoutRequest.fromJson(response);

      // ارسال اعلان به ادمین‌ها
      try {
        final adminProfiles =
            await ProfileRepository.instance.fetchProfilesByRole('admin');

        for (final admin in adminProfiles) {
          final adminId = admin['id'] as String?;
          if (adminId != null) {
            await NotificationDataService.createNotification(
              userId: adminId,
              title: 'درخواست برداشت جدید',
              message:
                  'یک درخواست برداشت به مبلغ ${PaymentConstants.formatAmount(amount)} ثبت شده است',
              type: NotificationType.payment,
              priority: 3,
              data: {
                'payout_request_id': request.id,
                'trainer_id': userId,
                'amount': amount,
              },
              actionUrl: '/admin-payout-requests',
            );
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ خطا در ارسال اعلان به ادمین: $e');
        }
        // خطا در اعلان نباید جریان اصلی را متوقف کند
      }

      return {
        'success': true,
        'payout_request': request,
        'message': 'درخواست برداشت با موفقیت ثبت شد',
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد درخواست برداشت: $e');
      }
      return {'success': false, 'error': 'خطا در ایجاد درخواست: $e'};
    }
  }

  /// دریافت درخواست‌های مربی
  Future<List<PayoutRequest>> getTrainerPayoutRequests(String trainerId) async {
    try {
      final response = await _client
          .from('payout_requests')
          .select()
          .eq('trainer_id', trainerId)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map((json) => PayoutRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت درخواست‌های برداشت: $e');
      }
      return [];
    }
  }

  /// دریافت تمام درخواست‌ها (برای ادمین)
  Future<List<PayoutRequest>> getAllPayoutRequests({
    PayoutRequestStatus? status,
    int? limit,
  }) async {
    try {
      var query = _client.from('payout_requests').select();

      if (status != null) {
        query = query.eq('status', status.toString().split('.').last);
      }

      final orderedQuery = query.order('created_at', ascending: false);

      final response = limit != null
          ? await orderedQuery.limit(limit)
          : await orderedQuery;

      return (response as List<dynamic>)
          .map((json) => PayoutRequest.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت درخواست‌های برداشت: $e');
      }
      return [];
    }
  }

  /// تایید درخواست برداشت (توسط ادمین)
  Future<Map<String, dynamic>> approvePayoutRequest({
    required String requestId,
    int? penaltyAmount,
    String? penaltyReason,
    String? adminNotes,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // بررسی نقش ادمین
      final adminService = AdminService();
      final isAdmin = await adminService.isAdmin();
      if (!isAdmin) {
        return {
          'success': false,
          'error': 'فقط ادمین‌ها می‌توانند درخواست‌ها را تایید کنند',
        };
      }

      // دریافت درخواست
      final requestResponse = await _client
          .from('payout_requests')
          .select()
          .eq('id', requestId)
          .single();

      final request = PayoutRequest.fromJson(requestResponse);

      if (request.status != PayoutRequestStatus.pending) {
        return {'success': false, 'error': 'این درخواست قبلاً بررسی شده است'};
      }

      // محاسبه مبلغ نهایی
      final finalPenaltyAmount = penaltyAmount ?? 0;
      final finalAmount = request.amount - finalPenaltyAmount;
      final hasPenalty = finalPenaltyAmount > 0;

      if (finalAmount < 0) {
        return {
          'success': false,
          'error': 'مبلغ جریمه نمی‌تواند بیشتر از مبلغ درخواستی باشد',
        };
      }

      // به‌روزرسانی درخواست
      await _client
          .from('payout_requests')
          .update({
            'status': PayoutRequestStatus.approved.toString().split('.').last,
            'final_amount': finalAmount,
            'penalty_amount': finalPenaltyAmount,
            'penalty_reason': penaltyReason,
            'admin_notes': adminNotes,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // ارسال اعلان به مربی
      try {
        await NotificationDataService.createNotification(
          userId: request.trainerId,
          title: 'تایید درخواست برداشت',
          message: hasPenalty
              ? 'درخواست برداشت شما تایید شد. مبلغ نهایی: ${PaymentConstants.formatAmount(finalAmount)} (جریمه: ${PaymentConstants.formatAmount(finalPenaltyAmount)})'
              : 'درخواست برداشت شما به مبلغ ${PaymentConstants.formatAmount(finalAmount)} تایید شد',
          type: NotificationType.payment,
          priority: 2,
          data: {
            'payout_request_id': requestId,
            'amount': finalAmount,
            'has_penalty': hasPenalty,
          },
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ خطا در ارسال اعلان به مربی: $e');
        }
      }

      return {'success': true, 'message': 'درخواست با موفقیت تایید شد'};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید درخواست: $e');
      }
      return {'success': false, 'error': 'خطا در تایید درخواست: $e'};
    }
  }

  /// رد درخواست برداشت (توسط ادمین)
  Future<Map<String, dynamic>> rejectPayoutRequest({
    required String requestId,
    required String reason,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // بررسی نقش ادمین
      final adminService = AdminService();
      final isAdmin = await adminService.isAdmin();
      if (!isAdmin) {
        return {
          'success': false,
          'error': 'فقط ادمین‌ها می‌توانند درخواست‌ها را رد کنند',
        };
      }

      // دریافت درخواست برای ارسال اعلان
      final requestResponse = await _client
          .from('payout_requests')
          .select()
          .eq('id', requestId)
          .single();
      final request = PayoutRequest.fromJson(requestResponse);

      await _client
          .from('payout_requests')
          .update({
            'status': PayoutRequestStatus.rejected.toString().split('.').last,
            'admin_notes': reason,
            'reviewed_by': userId,
            'reviewed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // ارسال اعلان به مربی
      try {
        await NotificationDataService.createNotification(
          userId: request.trainerId,
          title: 'رد درخواست برداشت',
          message: 'درخواست برداشت شما رد شد. دلیل: $reason',
          type: NotificationType.payment,
          priority: 2,
          data: {'payout_request_id': requestId, 'rejection_reason': reason},
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ خطا در ارسال اعلان به مربی: $e');
        }
      }

      return {'success': true, 'message': 'درخواست رد شد'};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در رد درخواست: $e');
      }
      return {'success': false, 'error': 'خطا در رد درخواست: $e'};
    }
  }

  /// تکمیل پرداخت (توسط ادمین)
  Future<Map<String, dynamic>> completePayout({
    required String requestId,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;
      if (userId == null) {
        return {'success': false, 'error': 'کاربر احراز هویت نشده است'};
      }

      // دریافت درخواست
      final requestResponse = await _client
          .from('payout_requests')
          .select()
          .eq('id', requestId)
          .single();

      final request = PayoutRequest.fromJson(requestResponse);

      if (request.status != PayoutRequestStatus.approved) {
        return {
          'success': false,
          'error': 'فقط درخواست‌های تایید شده قابل پرداخت هستند',
        };
      }

      final finalAmount = request.effectiveAmount;

      // بررسی نقش ادمین
      final adminService = AdminService();
      final isAdmin = await adminService.isAdmin();
      if (!isAdmin) {
        return {
          'success': false,
          'error': 'فقط ادمین‌ها می‌توانند پرداخت را تکمیل کنند',
        };
      }

      // دریافت wallet مربی (نه wallet ادمین!)
      final walletResponse = await _client
          .from('wallets')
          .select()
          .eq('user_id', request.trainerId)
          .maybeSingle();

      if (walletResponse == null) {
        return {'success': false, 'error': 'کیف پول مربی یافت نشد'};
      }

      final wallet = Wallet.fromJson(walletResponse);

      if (wallet.trainerWithdrawable < finalAmount) {
        return {'success': false, 'error': 'موجودی قابل برداشت کافی نیست'};
      }

      // کسر فقط از trainer_withdrawable (trainer_earnings تغییر نمی‌کند)
      final newTrainerWithdrawable = wallet.trainerWithdrawable - finalAmount;

      await _client
          .from('wallets')
          .update({
            'trainer_withdrawable': newTrainerWithdrawable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', wallet.id);

      // به‌روزرسانی وضعیت درخواست
      await _client
          .from('payout_requests')
          .update({
            'status': PayoutRequestStatus.completed.toString().split('.').last,
            'completed_at': DateTime.now().toIso8601String(),
          })
          .eq('id', requestId);

      // ارسال اعلان به مربی
      try {
        await NotificationDataService.createNotification(
          userId: request.trainerId,
          title: 'پرداخت تکمیل شد',
          message:
              'مبلغ ${PaymentConstants.formatAmount(finalAmount)} به حساب شما واریز شد',
          type: NotificationType.payment,
          priority: 2,
          data: {'payout_request_id': requestId, 'amount': finalAmount},
        );
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ خطا در ارسال اعلان به مربی: $e');
        }
      }

      return {'success': true, 'message': 'پرداخت با موفقیت انجام شد'};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تکمیل پرداخت: $e');
      }
      return {'success': false, 'error': 'خطا در تکمیل پرداخت: $e'};
    }
  }

  /// محاسبه موجودی قابل برداشت مربی (بعد از 3 روز)
  Future<int> getTrainerWithdrawable(String trainerId) async {
    try {
      final settings = await _commissionService.getActiveSettings();
      final holdDays = settings?.holdDays ?? 3;

      // دریافت تمام اشتراک‌های مربی که برنامه ثبت شده
      final subscriptions = await _client
          .from('trainer_subscriptions')
          .select(
            'id, final_amount, program_registration_date, payment_transaction_id',
          )
          .eq('trainer_id', trainerId)
          .not('program_registration_date', 'is', null);

      // دریافت platform_revenue برای هر subscription (برای محاسبه trainer_earnings)
      final subscriptionIds = subscriptions
          .map((s) => s['id'] as String?)
          .whereType<String>()
          .toList();
      final Map<String, int> platformRevenueBySub = {};
      if (subscriptionIds.isNotEmpty) {
        try {
          final orExpr = subscriptionIds
              .map((id) => 'subscription_id.eq.$id')
              .join(',');
          final revenueRows = await _client
              .from('platform_revenue')
              .select('subscription_id, amount')
              .or(orExpr);
          for (final r in (revenueRows as List)) {
            final subId = r['subscription_id'] as String?;
            final amount = (r['amount'] as num?)?.toInt() ?? 0;
            if (subId != null) {
              platformRevenueBySub[subId] = amount;
            }
          }
        } catch (_) {}
      }

      // دریافت درخواست‌های برداشت شده (completed) و تایید شده (approved)
      // درخواست‌های approved هم باید از withdrawable کم شوند چون در حال پردازش هستند
      final processedRequests = await _client
          .from('payout_requests')
          .select('amount, final_amount')
          .eq('trainer_id', trainerId)
          .or(
            'status.eq.${PayoutRequestStatus.completed.toString().split('.').last},status.eq.${PayoutRequestStatus.approved.toString().split('.').last}',
          );

      // محاسبه کل مبلغ برداشت شده یا در حال پردازش
      int totalWithdrawn = 0;
      for (final req in (processedRequests as List<dynamic>)) {
        final finalAmount = req['final_amount'] as int?;
        final amount = req['amount'] as int?;
        // استفاده از final_amount اگر وجود داشته باشد (بعد از جریمه)، وگرنه amount
        totalWithdrawn += finalAmount ?? amount ?? 0;
      }

      // دریافت تراکنش‌ها برای normalize کردن مبالغ
      final txIds = subscriptions
          .map((r) => r['payment_transaction_id'] as String?)
          .whereType<String>()
          .toSet()
          .toList();
      final Map<String, Map<String, dynamic>> txById = {};
      if (txIds.isNotEmpty) {
        try {
          final orExpr = txIds.map((id) => 'id.eq.$id').join(',');
          final txRows = await _client
              .from('payment_transactions')
              .select('id, amount, final_amount, payment_method, gateway')
              .or(orExpr);
          for (final t in (txRows as List)) {
            final id = t['id'] as String?;
            if (id != null) {
              txById[id] = Map<String, dynamic>.from(
                t as Map<dynamic, dynamic>,
              );
            }
          }
        } catch (_) {}
      }

      int normalizeToRial(int raw, {Map<String, dynamic>? tx}) {
        if (tx != null) {
          final txFinal = tx['final_amount'] as int?;
          final txAmt = tx['amount'] as int?;
          final pm = (tx['payment_method'] as String?)?.toLowerCase();
          final gw = (tx['gateway'] as String?)?.toLowerCase();
          final v = txFinal ?? txAmt;
          if (v != null) {
            final isDirect =
                pm == 'direct' || gw == 'zibal' || gw == 'zarinpal';
            return isDirect ? v : (v * 10); // اگر wallet بود، به ریال تبدیل کن
          }
        }
        // Fallback: اگر به نظر ریال است (مضرب 10)، همان را برگردان
        return raw % 10 == 0 ? raw : (raw * 10);
      }

      int totalEarnings = 0;
      final now = DateTime.now();

      for (final sub in (subscriptions as List<dynamic>)) {
        final registrationDateStr = sub['program_registration_date'] as String?;
        if (registrationDateStr == null) continue;

        final registrationDate = DateTime.parse(registrationDateStr);
        final daysSinceRegistration = now.difference(registrationDate).inDays;

        // اگر 3 روز گذشته باشد، قابل برداشت است
        if (daysSinceRegistration >= holdDays) {
          final rawAmount = (sub['final_amount'] as num).toInt();
          final txId = sub['payment_transaction_id'] as String?;
          final tx = txId != null ? txById[txId] : null;
          final amountInRial = normalizeToRial(rawAmount, tx: tx);

          // استفاده از platform_revenue که قبلاً ثبت شده (به جای محاسبه مجدد)
          final subId = sub['id'] as String?;
          final platformRevenue = subId != null
              ? (platformRevenueBySub[subId] ?? 0)
              : 0;
          final trainerEarning = amountInRial - platformRevenue;

          totalEarnings += trainerEarning;
        }
      }

      // موجودی قابل برداشت = کل درآمد - مبالغ برداشت شده
      return (totalEarnings - totalWithdrawn).clamp(0, totalEarnings);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در محاسبه موجودی قابل برداشت: $e');
      }
      return 0;
    }
  }

  /// به‌روزرسانی trainer_withdrawable در کیف پول
  Future<bool> updateTrainerWithdrawable(String trainerId) async {
    try {
      final withdrawable = await getTrainerWithdrawable(trainerId);

      // دریافت کیف پول مربی
      final walletResponse = await _client
          .from('wallets')
          .select()
          .eq('user_id', trainerId)
          .maybeSingle();

      if (walletResponse == null) {
        // اگر کیف پول وجود نداشت، ایجاد می‌کنیم
        await _client.from('wallets').insert({
          'user_id': trainerId,
          'trainer_withdrawable': withdrawable,
        });
        return true;
      }

      // به‌روزرسانی trainer_withdrawable
      await _client
          .from('wallets')
          .update({
            'trainer_withdrawable': withdrawable,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('user_id', trainerId);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی موجودی قابل برداشت: $e');
      }
      return false;
    }
  }

  Future<Map<String, dynamic>> transferEarningsToPersonalWallet({
    required String trainerId,
    required int amount,
  }) async {
    try {
      if (amount <= 0) {
        return {'success': false, 'error': 'مبلغ باید بیشتر از صفر باشد'};
      }

      final walletResponse = await _client
          .from('wallets')
          .select('trainer_withdrawable, balance')
          .eq('user_id', trainerId)
          .maybeSingle();

      if (walletResponse == null) {
        return {'success': false, 'error': 'کیف پول یافت نشد'};
      }

      final withdrawable =
          (walletResponse['trainer_withdrawable'] as num?)?.toInt() ?? 0;
      if (withdrawable < amount) {
        return {'success': false, 'error': 'موجودی کافی نیست'};
      }

      final newWithdrawable = withdrawable - amount;
      final currentBalance =
          (walletResponse['balance'] as num?)?.toInt() ?? 0;

      await _client.from('wallets').update({
        'trainer_withdrawable': newWithdrawable,
        'balance': currentBalance + amount,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('user_id', trainerId);

      return {
        'success': true,
        'message': 'مبلغ با موفقیت به کیف پول شخصی منتقل شد',
      };
    } catch (e) {
      if (kDebugMode) {
        debugPrint('transferEarningsToPersonalWallet error: $e');
      }
      return {'success': false, 'error': 'خطا در انتقال موجودی'};
    }
  }
}
