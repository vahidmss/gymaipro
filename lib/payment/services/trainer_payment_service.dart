import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/notification/models/notification_model.dart';
import 'package:gymaipro/notification/push_notification_policy.dart';
import 'package:gymaipro/notification/services/notification_push_invoker.dart';
import 'package:gymaipro/notification/services/in_app_notification_delivery_service.dart';
import 'package:gymaipro/notification/services/notification_data_service.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_escrow_service.dart';
import 'package:gymaipro/payment/services/discount_service.dart';
// removed unused import
import 'package:gymaipro/payment/services/payment_gateway_service.dart';
import 'package:gymaipro/payment/services/trainer_program_sms_service.dart';
import 'package:gymaipro/payment/services/trainer_subscription_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/profile/repositories/profile_repository.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
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
  final ProfileRepository _profiles = ProfileRepository.instance;
  final TrainerClientService _trainerClientService = TrainerClientService();

  /// پردازش خرید اشتراک مربی
  Future<Map<String, dynamic>> processTrainerSubscriptionPurchase({
    required String userId, // این باید auth.users.id باشد
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

      // دریافت profileId برای استفاده در تراکنش
      // constraint در دیتابیس به profiles reference می‌کند، پس باید از profileId استفاده کنیم
      // اگر پروفایل پیدا نشد، retry می‌کنیم (ممکن است مشکل connection باشد)
      String? effectiveUserId;
      int retryCount = 0;
      const maxRetries = 3;

      while (effectiveUserId == null && retryCount < maxRetries) {
        try {
          final profile = await SimpleProfileService.getCurrentProfile();
          if (profile != null) {
            final profileId = profile['id'] as String?;
            if (profileId != null && profileId.isNotEmpty) {
              effectiveUserId =
                  profileId; // استفاده از profileId چون constraint به profiles reference می‌کند
              if (kDebugMode) {
                print(
                  'TRAINER_PAY: Using profileId=$profileId (instead of authUserId=$userId)',
                );
              }
              break;
            }
          }

          // اگر پروفایل پیدا نشد و retry باقی مانده، دوباره تلاش می‌کنیم
          if (retryCount < maxRetries - 1) {
            if (kDebugMode) {
              print(
                'TRAINER_PAY: Profile not found, retrying... (attempt ${retryCount + 1}/$maxRetries)',
              );
            }
            await Future<void>.delayed(
              Duration(milliseconds: 500 * (retryCount + 1)),
            );
            retryCount++;
          } else {
            if (kDebugMode) {
              print(
                'TRAINER_PAY: Profile not found after $maxRetries attempts',
              );
            }
            break;
          }
        } catch (e) {
          if (kDebugMode) {
            print(
              'TRAINER_PAY: Error getting profile (attempt ${retryCount + 1}/$maxRetries): $e',
            );
          }

          // اگر retry باقی مانده، دوباره تلاش می‌کنیم
          if (retryCount < maxRetries - 1) {
            await Future<void>.delayed(
              Duration(milliseconds: 500 * (retryCount + 1)),
            );
            retryCount++;
          } else {
            if (kDebugMode) {
              print(
                'TRAINER_PAY: Failed to get profile after $maxRetries attempts',
              );
            }
            break;
          }
        }
      }

      // اگر بعد از retry هم پروفایل پیدا نشد، خطا throw می‌کنیم
      if (effectiveUserId == null) {
        const errorMsg = 'پروفایل کاربر پیدا نشد. لطفاً دوباره تلاش کنید.';
        if (kDebugMode) {
          print('TRAINER_PAY: ERROR - Cannot proceed without profileId');
        }
        return {
          'success': false,
          'error': errorMsg,
          'code': 'PROFILE_NOT_FOUND',
        };
      }

      // بررسی وجود اشتراک فعال
      // استفاده از effectiveUserId (profileId) چون constraint به profiles reference می‌کند
      final hasActive = await _subscriptionService.hasActiveSubscription(
        effectiveUserId,
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
      // استفاده از SimpleProfileService برای دریافت پروفایل (مثل سایر بخش‌های برنامه)
      String buyerName = '';
      try {
        final profile = await SimpleProfileService.getCurrentProfile();
        if (kDebugMode) {
          print(
            'TRAINER_PAY: buyer profile for $userId => ${profile != null ? "found" : "null"}',
          );
        }
        if (profile != null) {
          final firstName = (profile['first_name'] as String?)?.trim() ?? '';
          final lastName = (profile['last_name'] as String?)?.trim() ?? '';
          final combined = '$firstName $lastName'.trim();
          final username = (profile['username'] as String?)?.trim() ?? '';
          final phone = (profile['phone_number'] as String?)?.trim() ?? '';
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
          userId: effectiveUserId, // استفاده از profileId
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

      // بررسی معتبر بودن effectiveUserId
      if (kDebugMode) {
        print(
          'TRAINER_PAY: Creating transaction with effectiveUserId: $effectiveUserId (original authUserId: $userId)',
        );
      }

      // ایجاد تراکنش پرداخت
      // استفاده از effectiveUserId (که profileId است چون constraint به profiles reference می‌کند)
      final transaction = PaymentTransaction(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: effectiveUserId,
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
      // استفاده از effectiveUserId (profileId) برای subscription
      if (paymentMethod == 'wallet') {
        return await _processWalletPayment(
          transaction,
          effectiveUserId, // استفاده از profileId
          trainerId,
          serviceType,
          buyerNameOverride: buyerName,
        );
      } else {
        return await _processDirectPayment(
          transaction,
          effectiveUserId, // استفاده از profileId
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
      try {
        await _walletService.payFromWallet(
          amount: transaction.finalAmount,
          description: 'خرید اشتراک مربی',
          referenceId: transaction.id,
          metadata: transaction.metadata,
        );
      } catch (e) {
        final msg = e.toString().toLowerCase();
        final isInsufficient =
            msg.contains('موجودی') &&
            (msg.contains('کافی نیست') || msg.contains('منفی'));
        return {
          'success': false,
          'error': isInsufficient
              ? 'موجودی کیف پول کافی نیست'
              : 'خطا در کسر از کیف پول. لطفاً دوباره تلاش کنید.',
          'code': isInsufficient
              ? 'INSUFFICIENT_BALANCE'
              : 'WALLET_DEDUCTION_FAILED',
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

      // ایجاد اشتراک؛ در صورت شکست موجودی را برمی‌گردانیم
      TrainerSubscription? subscription;
      try {
        subscription = await _subscriptionService.createSubscription(
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
      } catch (e) {
        if (kDebugMode) {
          print('خطا در ایجاد اشتراک، در حال بازگرداندن وجه: $e');
        }
        await _walletService.refundToWallet(
          amount: transaction.finalAmount,
          transactionId: 'refund-${transaction.id}',
          description: 'بازگشت وجه به‌دلیل خطا در ثبت اشتراک',
          metadata: transaction.metadata,
        );
        await _client
            .from('payment_transactions')
            .update({
              'status': TransactionStatus.cancelled.toString().split('.').last,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', transaction.id);
        return {
          'success': false,
          'error': 'خطا در ایجاد اشتراک. مبلغ به کیف پول بازگردانده شد.',
          'code': 'SUBSCRIPTION_CREATION_FAILED',
        };
      }

      if (subscription == null) {
        await _walletService.refundToWallet(
          amount: transaction.finalAmount,
          transactionId: 'refund-${transaction.id}',
          description: 'بازگشت وجه به‌دلیل خطا در ثبت اشتراک',
          metadata: transaction.metadata,
        );
        await _client
            .from('payment_transactions')
            .update({
              'status': TransactionStatus.cancelled.toString().split('.').last,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', transaction.id);
        return {
          'success': false,
          'error': 'خطا در ایجاد اشتراک. مبلغ به کیف پول بازگردانده شد.',
          'code': 'SUBSCRIPTION_CREATION_FAILED',
        };
      }

      // فعال کردن اشتراک؛ در صورت شکست بازگشت وجه
      try {
        await _subscriptionService.updateSubscriptionStatus(
          subscription.id,
          TrainerSubscriptionStatus.active,
        );
      } catch (e) {
        if (kDebugMode) {
          print('خطا در فعال‌سازی اشتراک، در حال بازگرداندن وجه: $e');
        }
        await _walletService.refundToWallet(
          amount: transaction.finalAmount,
          transactionId: 'refund-${transaction.id}',
          description: 'بازگشت وجه به‌دلیل خطا در فعال‌سازی اشتراک',
          metadata: transaction.metadata,
        );
        await _client
            .from('payment_transactions')
            .update({
              'status': TransactionStatus.cancelled.toString().split('.').last,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', transaction.id);
        return {
          'success': false,
          'error': 'خطا در فعال‌سازی اشتراک. مبلغ به کیف پول بازگردانده شد.',
          'code': 'SUBSCRIPTION_ACTIVATION_FAILED',
        };
      }

      // ثبت escrow و کمیسیون (مثل پرداخت مستقیم)
      await _processCommission(
        transactionId: transaction.id,
        subscriptionId: subscription.id,
        trainerId: trainerId,
        finalAmount: transaction.finalAmount,
      );

      // ارسال اعلان به مربی
      await _notifyTrainerNewRequest(
        trainerId: trainerId,
        buyerUserId: userId,
        subscriptionId: subscription.id,
        serviceType: serviceType,
        buyerNameOverride: buyerNameOverride,
      );

      // افزودن کاربر به شاگردان مربی (active)
      final isNewRelationship = await _trainerClientService
          .ensureActiveRelationship(trainerId: trainerId, clientId: userId);
      // اعلان پیوستن شاگرد جدید - فقط اگر رابطه جدید باشد
      if (isNewRelationship) {
        await _notifyTrainerNewStudent(
          trainerId: trainerId,
          buyerUserId: userId,
        );
      }

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
      // اضافه کردن trainer_id به callback URL برای بازگشت به صفحه مربی
      final callbackUrl =
          '${AppConfig.zibalCallbackUrl}?orderId=${transaction.id}&trainerId=$trainerId&type=trainer';
      final paymentResult = await _paymentGateway.processPayment(
        transaction: transaction,
        gateway: PaymentGateway.zibal,
        callbackUrl: callbackUrl,
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

      // محاسبه و ثبت کمیسیون
      await _processCommission(
        transactionId: transaction.id,
        subscriptionId: subscription.id,
        trainerId: transaction.metadata?['trainer_id'] as String? ?? '',
        finalAmount: transaction.finalAmount,
      );

      // ارسال اعلان به مربی
      await _notifyTrainerNewRequest(
        trainerId: transaction.metadata?['trainer_id'] as String? ?? '',
        buyerUserId: transaction.userId,
        subscriptionId: subscription.id,
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
        final isNewRelationship = await _trainerClientService
            .ensureActiveRelationship(
              trainerId: trId,
              clientId: transaction.userId,
            );
        // اعلان پیوستن شاگرد جدید - فقط اگر رابطه جدید باشد
        if (isNewRelationship) {
          await _notifyTrainerNewStudent(
            trainerId: trId,
            buyerUserId: transaction.userId,
          );
        }
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

  /// بر اساس profile id، auth user id را برمی‌گرداند (برای اعلان و device_tokens که با auth.uid کار می‌کنند)
  Future<String> _getAuthUserIdForProfileId(String profileId) =>
      _profiles.resolveAuthUserId(profileId);

  String _buyerNameFromProfile(
    Map<String, dynamic>? profile, {
    String fallback = 'یک کاربر',
  }) {
    if (profile == null) return fallback;
    return _profiles.displayNameFromMap(profile, fallback: fallback);
  }

  Future<Map<String, dynamic>?> _fetchBuyerProfile(String buyerUserId) =>
      _profiles.fetchProfile(buyerUserId);

  /// ارسال اعلان به مربی پس از خرید اشتراک
  Future<void> _notifyTrainerNewRequest({
    required String trainerId,
    required String buyerUserId,
    required String subscriptionId,
    required TrainerServiceType serviceType,
    String? buyerNameOverride,
  }) async {
    try {
      // اعلان و device_tokens با auth.uid کار می‌کنند؛ trainerId ممکن است profile id باشد
      final trainerAuthId = await _getAuthUserIdForProfileId(trainerId);

      // دریافت نام/یوزرنیم خریدار (از override یا metadata یا پروفایل)
      String buyerName = (buyerNameOverride ?? '').trim();
      // اگر override مقدار پیش‌فرض باشد، نادیده بگیر تا از پروفایل بخوانیم
      if (buyerName == 'یک کاربر') {
        buyerName = '';
      }
      Map<String, dynamic>? buyerProfile;
      if (buyerName.isEmpty) {
        buyerProfile = await _fetchBuyerProfile(buyerUserId);
        buyerName = _buyerNameFromProfile(buyerProfile, fallback: '');
      }
      if (buyerName.isEmpty) buyerName = 'یک کاربر';

      final serviceName = _getServiceTypeText(serviceType);
      const title = 'درخواست برنامه جدید';
      // یوزرنیم را فقط وقتی اضافه می‌کنیم که نام کامل در دسترس نباشد
      String usernameSuffix = '';
      try {
        buyerProfile ??= await _fetchBuyerProfile(buyerUserId);
        final uname = (buyerProfile?['username'] as String?)?.trim();
        final phone = (buyerProfile?['phone_number'] as String?)?.trim();
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

      final notifData = <String, dynamic>{
        'type': 'payment',
        'event': 'trainer_program_purchase',
        'buyer_user_id': buyerUserId,
        'subscription_id': subscriptionId,
        'service': serviceName,
        'route': '/trainer-dashboard',
      };

      await InAppNotificationDeliveryService.deliverTrainerProgramPurchase(
        trainerProfileId: trainerId,
        trainerAuthUserId: trainerAuthId,
        title: title,
        body: message,
        data: notifData,
        actionUrl: '/trainer-dashboard',
        dedupeKey: 'trainer_program:$subscriptionId',
      );

      if (subscriptionId.isNotEmpty) {
        await TrainerProgramSmsService.notifyPurchaseCompleteSms(
          trainerProfileOrAuthId: trainerId,
          buyerProfileId: buyerUserId,
          subscriptionId: subscriptionId,
        );
      }
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ خطا در ایجاد اعلان: $e');
      }
    }
  }

  /// ارسال اعلان: شاگرد جدید به مربی اضافه شد
  Future<void> _notifyTrainerNewStudent({
    required String trainerId,
    required String buyerUserId,
  }) async {
    try {
      final trainerAuthId = await _getAuthUserIdForProfileId(trainerId);

      // نام خریدار
      final buyerProfile = await _fetchBuyerProfile(buyerUserId);
      var buyerName = _buyerNameFromProfile(buyerProfile, fallback: '');
      if (buyerName.isEmpty) buyerName = 'یک کاربر';

      const title = 'شاگرد جدید';
      final message = '$buyerName به شاگردان شما اضافه شد.';

      // ایجاد نوتیفیکیشن داخل برنامه (user_id باید auth.uid باشد)
      await NotificationDataService.createNotification(
        userId: trainerAuthId,
        title: title,
        message: message,
        type: NotificationType.payment,
        priority: 2,
        data: {'buyer_user_id': buyerUserId, 'event': 'student_added'},
      );

      // ارسال پوش: سمت سرور توکن مربی را می‌خواند (RLS اجازه خواندن به خریدار نمی‌دهد)
      try {
        if (PushNotificationPolicy.shouldAttemptServerPush) {
          await NotificationPushInvoker.sendNotifications(
            client: _client,
            body: {
              'mode': 'trainer_new_student',
              'trainer_id': trainerId,
              'title': title,
              'body': message,
              'data': {
                'type': 'payment',
                'route': '/trainer-dashboard',
                'buyer_user_id': buyerUserId,
                'event': 'student_added',
              },
            },
          );
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ خطا در ارسال پوش نوتیفیکیشن: $e');
        }
      }
  } catch (e) {
      if (kDebugMode) {
        print('⚠️ خطا در ایجاد اعلان: $e');
      }
    }
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

  /// پردازش کمیسیون — ثبت escrow (مربی تا زمان مناسب پول را نمی‌بیند)
  Future<void> _processCommission({
    required String transactionId,
    required String subscriptionId,
    required String trainerId,
    required int finalAmount,
  }) async {
    try {
      await TrainerEscrowService().recordPaymentEscrow(
        subscriptionId: subscriptionId,
        trainerId: trainerId,
        transactionId: transactionId,
        finalAmountRial: finalAmount,
      );

      if (kDebugMode) {
        print('Escrow پردازش شد برای اشتراک: $subscriptionId');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در پردازش escrow: $e');
      }
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
