import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/discount_service.dart';
// removed unused import
import 'package:gymaipro/payment/services/payment_gateway_service.dart';
import 'package:gymaipro/payment/services/trainer_subscription_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/trainer_dashboard/services/trainer_client_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس پرداخت اشتراک‌های مربی
class TrainerPaymentService {
  factory TrainerPaymentService() => _instance;
  TrainerPaymentService._internal();
  static final TrainerPaymentService _instance =
      TrainerPaymentService._internal();

  final PaymentGatewayService _paymentGateway = PaymentGatewayService();
  final WalletService _walletService = WalletService();
  final DiscountService _discountService = DiscountService();
  final TrainerSubscriptionService _subscriptionService =
      TrainerSubscriptionService();
  final SupabaseClient _client = Supabase.instance.client;
  final TrainerClientService _trainerClientService = TrainerClientService();

  /// پردازش خرید اشتراک مربی
  Future<Map<String, dynamic>> processTrainerSubscriptionPurchase({
    required String userId,
    required String trainerId,
    required TrainerServiceType serviceType,
    required int originalAmount,
    required String paymentMethod, // 'wallet' or 'direct'
    String? discountCode,
    String? userPhone,
    String? userEmail,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      if (kDebugMode) {
        print(
          'شروع پردازش خرید اشتراک مربی - کاربر: $userId, مربی: $trainerId, نوع: $serviceType',
        );
      }

      // بررسی وجود اشتراک فعال
      final hasActive = await _subscriptionService.hasActiveSubscription(
        userId,
        trainerId,
        serviceType,
      );

      if (hasActive) {
        return {
          'success': false,
          'error': 'شما قبلاً این نوع اشتراک را خریداری کرده‌اید',
          'code': 'ALREADY_PURCHASED',
        };
      }

      // محاسبه نام خریدار برای اعلان‌ها
      String buyerName = '';
      try {
        final p = await _client
            .from('profiles')
            .select('first_name, last_name, username, phone_number')
            .eq('id', userId)
            .maybeSingle();
        if (kDebugMode) {
          print('TRAINER_PAY: buyer profile for $userId => $p');
        }
        if (p != null) {
          final firstName = (p['first_name'] as String?)?.trim() ?? '';
          final lastName = (p['last_name'] as String?)?.trim() ?? '';
          final combined = '$firstName $lastName'.trim();
          final username = (p['username'] as String?)?.trim() ?? '';
          final phone = (p['phone_number'] as String?)?.trim() ?? '';
          if (combined.isNotEmpty) {
            buyerName = combined;
          } else if (username.isNotEmpty) {
            buyerName = username;
          } else if (phone.isNotEmpty) {
            buyerName = phone;
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('TRAINER_PAY: error loading buyer profile: $e');
        }
      }
      if (kDebugMode) {
        print('TRAINER_PAY: resolved buyerName => "$buyerName"');
      }
      if (buyerName.isEmpty) buyerName = 'یک کاربر';

      // محاسبه تخفیف
      int finalAmount = originalAmount;
      int discountAmount = 0;
      // double discountPercentage =
      //     0.0; // kept for metadata/analytics if needed later

      if (discountCode != null && discountCode.isNotEmpty) {
        final validate = await _discountService.validateDiscountCode(
          code: discountCode,
          originalAmount: originalAmount,
          userId: userId,
        );

        if (validate['valid'] == true) {
          finalAmount = validate['final_amount'] as int;
          discountAmount = validate['discount_amount'] as int;
          // final dp = validate['discount_percentage'];
          // if (dp != null) {
          //   discountPercentage = (dp as num).toDouble();
          // }
        }
      }

      // ایجاد تراکنش پرداخت
      final transaction = PaymentTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: userId,
        amount: originalAmount,
        finalAmount: finalAmount,
        discountAmount: discountAmount,
        discountCode: discountCode,
        type: TransactionType.trainerService,
        status: TransactionStatus.pending,
        paymentMethod: paymentMethod == 'wallet'
            ? PaymentMethod.wallet
            : PaymentMethod.direct,
        gateway: paymentMethod == 'wallet'
            ? PaymentGateway.wallet
            : PaymentGateway.zibal,
        description: 'خرید اشتراک ${_getServiceTypeText(serviceType)}',
        metadata: {
          'trainer_id': trainerId,
          'service_type': serviceType.toString().split('.').last,
          'user_phone': userPhone,
          'user_email': userEmail,
          'buyer_name': buyerName,
          // ذخیره یوزرنیم برای اعلان‌های دقیق‌تر
          'buyer_username': (() {
            // سعی می‌کنیم همان کوئری قبلی پروفایل را دوباره استفاده نکنیم؛
            // اگر نام از first/last ساخته شده، احتمالاً username هم وجود دارد.
            // برای اطمینان، یک کوئری سبک انجام می‌دهیم.
            try {
              // توجه: این کد sync نیست؛ فقط به‌عنوان مقدار اولیه خالی می‌گذاریم.
              // یوزرنیم را در مرحله اعلان دوباره از پروفایل می‌خوانیم.
              return null;
            } catch (_) {
              return null;
            }
          })(),
          ...?metadata,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: DateTime.now().add(const Duration(hours: 24)), // 24 ساعت
      );

      // ذخیره تراکنش
      await _client.from('payment_transactions').insert(transaction.toJson());

      // پردازش بر اساس روش پرداخت
      if (paymentMethod == 'wallet') {
        return await _processWalletPayment(
          transaction,
          userId,
          trainerId,
          serviceType,
          buyerNameOverride: buyerName,
        );
      } else {
        return await _processDirectPayment(
          transaction,
          userId,
          trainerId,
          serviceType,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش خرید اشتراک: $e');
      }
      return {
        'success': false,
        'error': 'خطا در پردازش خرید: $e',
        'code': 'PROCESSING_ERROR',
      };
    }
  }

  /// پردازش پرداخت از کیف پول
  Future<Map<String, dynamic>> _processWalletPayment(
    PaymentTransaction transaction,
    String userId,
    String trainerId,
    TrainerServiceType serviceType, {
    String? buyerNameOverride,
  }) async {
    try {
      // بررسی موجودی کیف پول
      final wallet = await _walletService.getUserWallet();
      final walletBalance = wallet?.availableBalance ?? 0;
      if (walletBalance < transaction.finalAmount) {
        return {
          'success': false,
          'error': 'موجودی کیف پول کافی نیست',
          'code': 'INSUFFICIENT_BALANCE',
          'required_amount': transaction.finalAmount,
          'available_balance': walletBalance,
        };
      }

      // کسر از کیف پول
      final paid = await _walletService.payFromWallet(
        amount: transaction.finalAmount,
        description: 'خرید اشتراک مربی',
        referenceId: transaction.id,
        metadata: transaction.metadata,
      );

      if (!paid) {
        return {
          'success': false,
          'error': 'خطا در کسر از کیف پول',
          'code': 'WALLET_DEDUCTION_FAILED',
        };
      }

      // به‌روزرسانی وضعیت تراکنش
      await _client
          .from('payment_transactions')
          .update({
            'status': TransactionStatus.completed.toString().split('.').last,
            'gateway_transaction_id': transaction.id,
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transaction.id);

      // ایجاد اشتراک
      final subscription = await _subscriptionService.createSubscription(
        userId: userId,
        trainerId: trainerId,
        serviceType: serviceType,
        originalAmount: transaction.amount,
        finalAmount: transaction.finalAmount,
        discountCode: transaction.discountCode,
        discountPercentage: transaction.discountPercentage,
        paymentTransactionId: transaction.id,
        metadata: transaction.metadata,
      );

      if (subscription == null) {
        return {
          'success': false,
          'error': 'خطا در ایجاد اشتراک',
          'code': 'SUBSCRIPTION_CREATION_FAILED',
        };
      }

      // فعال کردن اشتراک
      await _subscriptionService.updateSubscriptionStatus(
        subscription.id,
        TrainerSubscriptionStatus.active,
      );

      // ارسال اعلان به مربی
      await _notifyTrainerNewRequest(
        trainerId: trainerId,
        buyerUserId: userId,
        serviceType: serviceType,
        buyerNameOverride: buyerNameOverride,
      );

      // افزودن کاربر به شاگردان مربی (active)
      await _trainerClientService.ensureActiveRelationship(
        trainerId: trainerId,
        clientId: userId,
      );
      // اعلان پیوستن شاگرد جدید
      await _notifyTrainerNewStudent(trainerId: trainerId, buyerUserId: userId);

      return {
        'success': true,
        'message': 'اشتراک با موفقیت خریداری شد',
        'transaction_id': transaction.id,
        'subscription_id': subscription.id,
        'amount': transaction.finalAmount,
        'payment_method': 'wallet',
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش پرداخت کیف پول: $e');
      }
      return {
        'success': false,
        'error': 'خطا در پردازش پرداخت کیف پول: $e',
        'code': 'WALLET_PAYMENT_ERROR',
      };
    }
  }

  /// پردازش پرداخت مستقیم
  Future<Map<String, dynamic>> _processDirectPayment(
    PaymentTransaction transaction,
    String userId,
    String trainerId,
    TrainerServiceType serviceType,
  ) async {
    try {
      // درخواست پرداخت از درگاه
      final paymentResult = await _paymentGateway.processPayment(
        transaction: transaction,
        gateway: PaymentGateway.zibal,
        callbackUrl: '${AppConfig.zibalCallbackUrl}?orderId=${transaction.id}',
      );

      if (paymentResult?['success'] != true) {
        return {
          'success': false,
          'error': paymentResult?['error'] ?? 'خطا در درخواست پرداخت',
          'code': 'PAYMENT_GATEWAY_ERROR',
        };
      }

      return {
        'success': true,
        'message': 'درخواست پرداخت ایجاد شد',
        'transaction_id': transaction.id,
        'payment_url': paymentResult!['payUrl'],
        'track_id': paymentResult['trackId']?.toString(),
        'amount': transaction.finalAmount,
        'payment_method': 'direct',
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش پرداخت مستقیم: $e');
      }
      return {
        'success': false,
        'error': 'خطا در پردازش پرداخت مستقیم: $e',
        'code': 'DIRECT_PAYMENT_ERROR',
      };
    }
  }

  /// تایید پرداخت مستقیم
  Future<Map<String, dynamic>> verifyDirectPayment({
    required String transactionId,
    required String trackId,
  }) async {
    try {
      // دریافت تراکنش
      final transactionResponse = await _client
          .from('payment_transactions')
          .select()
          .eq('id', transactionId)
          .single();

      final transaction = PaymentTransaction.fromJson(transactionResponse);

      // تایید پرداخت از درگاه
      final verifyResult = await _paymentGateway.verifyPayment(
        transaction: transaction,
        gateway: PaymentGateway.zibal,
        gatewayResponse: trackId,
      );

      if (verifyResult?['success'] != true) {
        return {
          'success': false,
          'error': verifyResult?['error'] ?? 'خطا در تایید پرداخت',
          'code': 'PAYMENT_VERIFICATION_FAILED',
        };
      }

      // به‌روزرسانی وضعیت تراکنش
      await _client
          .from('payment_transactions')
          .update({
            'status': TransactionStatus.completed.toString().split('.').last,
            'gateway_transaction_id': trackId,
            'gateway_tracking_code': verifyResult!['refNumber'],
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      // ایجاد اشتراک
      final subscription = await _subscriptionService.createSubscription(
        userId: transaction.userId,
        trainerId: transaction.metadata?['trainer_id'] as String? ?? '',
        serviceType: TrainerServiceType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              transaction.metadata?['service_type'],
          orElse: () => TrainerServiceType.training,
        ),
        originalAmount: transaction.amount,
        finalAmount: transaction.finalAmount,
        discountCode: transaction.discountCode,
        discountPercentage: transaction.discountPercentage,
        paymentTransactionId: transaction.id,
        metadata: transaction.metadata,
      );

      if (subscription == null) {
        return {
          'success': false,
          'error': 'خطا در ایجاد اشتراک',
          'code': 'SUBSCRIPTION_CREATION_FAILED',
        };
      }

      // فعال کردن اشتراک
      await _subscriptionService.updateSubscriptionStatus(
        subscription.id,
        TrainerSubscriptionStatus.active,
      );

      // ارسال اعلان به مربی
      await _notifyTrainerNewRequest(
        trainerId: transaction.metadata?['trainer_id'] as String? ?? '',
        buyerUserId: transaction.userId,
        serviceType: TrainerServiceType.values.firstWhere(
          (e) =>
              e.toString().split('.').last ==
              transaction.metadata?['service_type'],
          orElse: () => TrainerServiceType.training,
        ),
        buyerNameOverride: (transaction.metadata?['buyer_name'] as String?)
            ?.trim(),
      );

      // افزودن کاربر به شاگردان مربی و ارسال اعلان
      final trId = transaction.metadata?['trainer_id'] as String? ?? '';
      if (trId.isNotEmpty) {
        await _trainerClientService.ensureActiveRelationship(
          trainerId: trId,
          clientId: transaction.userId,
        );
        await _notifyTrainerNewStudent(
          trainerId: trId,
          buyerUserId: transaction.userId,
        );
      }

      return {
        'success': true,
        'message': 'پرداخت با موفقیت تایید شد',
        'transaction_id': transactionId,
        'subscription_id': subscription.id,
        'amount': transaction.finalAmount,
        'ref_number': verifyResult['refNumber'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید پرداخت: $e');
      }
      return {
        'success': false,
        'error': 'خطا در تایید پرداخت: $e',
        'code': 'VERIFICATION_ERROR',
      };
    }
  }

  /// ارسال اعلان به مربی پس از خرید اشتراک
  Future<void> _notifyTrainerNewRequest({
    required String trainerId,
    required String buyerUserId,
    required TrainerServiceType serviceType,
    String? buyerNameOverride,
  }) async {
    try {
      // دریافت نام/یوزرنیم خریدار (از override یا metadata یا پروفایل)
      String buyerName = (buyerNameOverride ?? '').trim();
      // اگر override مقدار پیش‌فرض باشد، نادیده بگیر تا از پروفایل بخوانیم
      if (buyerName == 'یک کاربر') {
        buyerName = '';
      }
      if (buyerName.isEmpty) {
        try {
          final p = await _client
              .from('profiles')
              .select('first_name, last_name, username, phone_number')
              .eq('id', buyerUserId)
              .maybeSingle();
          if (p != null) {
            final firstName = (p['first_name'] as String?)?.trim() ?? '';
            final lastName = (p['last_name'] as String?)?.trim() ?? '';
            final combined = '$firstName $lastName'.trim();
            final username = (p['username'] as String?)?.trim() ?? '';
            final phone = (p['phone_number'] as String?)?.trim() ?? '';
            if (combined.isNotEmpty) {
              buyerName = combined;
            } else if (username.isNotEmpty)
              buyerName = username;
            else if (phone.isNotEmpty)
              buyerName = phone;
          }
        } catch (_) {}
      }
      if (buyerName.isEmpty) buyerName = 'یک کاربر';

      final serviceName = _getServiceTypeText(serviceType);
      const title = 'درخواست برنامه جدید';
      // یوزرنیم را فقط وقتی اضافه می‌کنیم که نام کامل در دسترس نباشد
      String usernameSuffix = '';
      try {
        final p = await _client
            .from('profiles')
            .select('username, phone_number')
            .eq('id', buyerUserId)
            .maybeSingle();
        final uname = (p?['username'] as String?)?.trim();
        final phone = (p?['phone_number'] as String?)?.trim();
        final shouldAppend =
            uname != null &&
            uname.isNotEmpty &&
            (buyerName == uname ||
                buyerName == (phone ?? '') ||
                buyerName == 'یک کاربر');
        if (shouldAppend) {
          usernameSuffix = ' (@$uname)';
        }
      } catch (_) {}
      final message =
          'درخواست $serviceName از $buyerName$usernameSuffix رسیده است.';

      await NotificationDataService.createNotification(
        userId: trainerId,
        title: title,
        message: message,
        type: NotificationType.payment,
        priority: 2,
        data: {'buyer_user_id': buyerUserId, 'service': serviceName},
      );
    } catch (_) {
      // خطا در اعلان را نادیده می‌گیریم تا جریان اصلی متوقف نشود
    }
  }

  /// ارسال اعلان: شاگرد جدید به مربی اضافه شد
  Future<void> _notifyTrainerNewStudent({
    required String trainerId,
    required String buyerUserId,
  }) async {
    try {
      // نام خریدار
      String buyerName = '';
      try {
        final p = await _client
            .from('profiles')
            .select('first_name, last_name, username, phone_number')
            .eq('id', buyerUserId)
            .maybeSingle();
        if (p != null) {
          final first = (p['first_name'] as String?)?.trim() ?? '';
          final last = (p['last_name'] as String?)?.trim() ?? '';
          final combined = '$first $last'.trim();
          final username = (p['username'] as String?)?.trim() ?? '';
          final phone = (p['phone_number'] as String?)?.trim() ?? '';
          if (combined.isNotEmpty) {
            buyerName = combined;
          } else if (username.isNotEmpty)
            buyerName = username;
          else if (phone.isNotEmpty)
            buyerName = phone;
        }
      } catch (_) {}
      if (buyerName.isEmpty) buyerName = 'یک کاربر';

      await NotificationDataService.createNotification(
        userId: trainerId,
        title: 'شاگرد جدید',
        message: '$buyerName به شاگردان شما اضافه شد.',
        type: NotificationType.payment,
        priority: 2,
        data: {'buyer_user_id': buyerUserId, 'event': 'student_added'},
      );
    } catch (_) {}
  }

  /// لغو تراکنش
  Future<Map<String, dynamic>> cancelTransaction(String transactionId) async {
    try {
      await _client
          .from('payment_transactions')
          .update({
            'status': TransactionStatus.cancelled.toString().split('.').last,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      return {'success': true, 'message': 'تراکنش لغو شد'};
    } catch (e) {
      if (kDebugMode) {
        print('خطا در لغو تراکنش: $e');
      }
      return {'success': false, 'error': 'خطا در لغو تراکنش: $e'};
    }
  }

  /// دریافت وضعیت تراکنش
  Future<Map<String, dynamic>?> getTransactionStatus(
    String transactionId,
  ) async {
    try {
      final response = await _client
          .from('payment_transactions')
          .select()
          .eq('id', transactionId)
          .maybeSingle();

      if (response != null) {
        final transaction = PaymentTransaction.fromJson(response);
        return {
          'success': true,
          'transaction': transaction.toJson(),
          'status': transaction.status.toString().split('.').last,
          'is_completed': transaction.isSuccessful,
        };
      }

      return null;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت وضعیت تراکنش: $e');
      }
      return null;
    }
  }

  /// دریافت تاریخچه پرداخت‌های کاربر
  Future<List<PaymentTransaction>> getUserPaymentHistory(String userId) async {
    try {
      final response = await _client
          .from('payment_transactions')
          .select()
          .eq('user_id', userId)
          .eq('type', TransactionType.trainerService.toString().split('.').last)
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) => PaymentTransaction.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تاریخچه پرداخت: $e');
      }
      return [];
    }
  }

  /// دریافت آمار پرداخت‌های مربی
  Future<Map<String, dynamic>> getTrainerPaymentStats(String trainerId) async {
    try {
      final response = await _client
          .from('payment_transactions')
          .select('amount, final_amount, status, created_at')
          .eq('metadata->trainer_id', trainerId)
          .eq(
            'type',
            TransactionType.trainerService.toString().split('.').last,
          );

      final stats = <String, dynamic>{
        'total_transactions': response.length,
        'total_revenue': 0,
        'successful_transactions': 0,
        'failed_transactions': 0,
        'pending_transactions': 0,
        'monthly_revenue': <String, int>{},
      };

      for (final transaction in response) {
        final amount = transaction['final_amount'] as int;
        final status = transaction['status'] as String;
        final createdAt = DateTime.parse(transaction['created_at'] as String);
        final monthKey =
            '${createdAt.year}-${createdAt.month.toString().padLeft(2, '0')}';

        stats['total_revenue'] = (stats['total_revenue'] as int) + amount;
        stats['monthly_revenue'][monthKey] =
            (stats['monthly_revenue'][monthKey] ?? 0) + amount;

        switch (status) {
          case 'completed':
            stats['successful_transactions']++;
          case 'failed':
            stats['failed_transactions']++;
          case 'pending':
            stats['pending_transactions']++;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت آمار پرداخت مربی: $e');
      }
      return {};
    }
  }

  /// متن نوع خدمات
  String _getServiceTypeText(TrainerServiceType serviceType) {
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
}
