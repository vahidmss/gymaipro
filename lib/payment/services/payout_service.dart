import 'package:flutter/foundation.dart';
import 'package:gymaipro/admin/services/admin_service.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/models/payout_request.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
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
  final TrainerEscrowService _escrowService = TrainerEscrowService();

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

      // بررسی مسدودیت برداشت توسط ادمین
      final payoutCheck = await _escrowService.checkPayoutAllowed(userId);
      if (payoutCheck['allowed'] != true) {
        return {
          'success': false,
          'error': payoutCheck['reason'] as String? ?? 'برداشت مسدود است',
          'code': 'PAYOUT_BLOCKED',
        };
      }

      // محاسبه موجودی قابل برداشت
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

  /// محاسبه موجودی قابل برداشت مربی (Escrow)
  Future<int> getTrainerWithdrawable(String trainerId) async {
    return _escrowService.getWithdrawableAmount(trainerId);
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
