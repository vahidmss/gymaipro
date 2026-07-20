import 'package:flutter/foundation.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/models/payment_transaction.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/payment/services/ai_coach_plan_price_service.dart';
import 'package:gymaipro/payment/services/discount_service.dart';
import 'package:gymaipro/payment/services/payment_gateway_service.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/payment/services/wallet_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/features/workout_program_request/application/workout_program_token_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// خرید پلن مربی هوشمند (کیف پول یا زیبال) بدون escrow مربی
class CoachPlanPaymentService {
  factory CoachPlanPaymentService() => _instance;
  CoachPlanPaymentService._internal();
  static final CoachPlanPaymentService _instance =
      CoachPlanPaymentService._internal();

  final SupabaseClient _client = Supabase.instance.client;
  final WalletService _walletService = WalletService();
  final PaymentGatewayService _paymentGateway = PaymentGatewayService();
  final DiscountService _discountService = DiscountService();
  final SubscriptionService _subscriptionService = SubscriptionService();
  final AiCoachPlanPriceService _priceService = AiCoachPlanPriceService();

  Future<Map<String, dynamic>> purchasePlan({
    required String planId,
    required String paymentMethod,
    String? discountCode,
  }) async {
    try {
      if (!CoachPlanCatalog.sellablePlanIds.contains(planId)) {
        return {
          'success': false,
          'error': 'پلن انتخاب‌شده قابل خرید نیست',
          'code': 'INVALID_PLAN',
        };
      }

      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) {
        return {
          'success': false,
          'error': 'کاربر وارد نشده است',
          'code': 'UNAUTHENTICATED',
        };
      }

      final price = await _priceService.getActivePrice(planId);
      if (!price.isActive) {
        return {
          'success': false,
          'error': 'این پلن در حال حاضر غیرفعال است',
          'code': 'PLAN_INACTIVE',
        };
      }

      final targetType = CoachPlanCatalog.subscriptionTypeForPlanId(planId);
      // خرید مجدد همان پلن = تمدید + توکن جدید ساخت برنامه

      final originalAmount = price.priceRial;
      var finalAmount = originalAmount;
      var discountAmount = 0;
      String? appliedCode;

      if (discountCode != null && discountCode.trim().isNotEmpty) {
        final validate = await _discountService.validateDiscountCode(
          code: discountCode.trim(),
          originalAmount: originalAmount,
          userId: userId,
        );
        if (validate['valid'] == true) {
          finalAmount = validate['final_amount'] as int;
          discountAmount = validate['discount_amount'] as int;
          appliedCode = discountCode.trim();
        } else {
          return {
            'success': false,
            'error': validate['error']?.toString() ?? 'کد تخفیف نامعتبر است',
            'code': 'INVALID_DISCOUNT',
          };
        }
      }

      final transaction = PaymentTransaction(
        id: PaymentConstants.generateTransactionId(),
        userId: userId,
        amount: originalAmount,
        finalAmount: finalAmount,
        discountAmount: discountAmount,
        discountCode: appliedCode,
        type: TransactionType.subscription,
        status: TransactionStatus.pending,
        paymentMethod: paymentMethod == 'wallet'
            ? PaymentMethod.wallet
            : PaymentMethod.direct,
        gateway: paymentMethod == 'wallet'
            ? PaymentGateway.wallet
            : PaymentGateway.zibal,
        description: 'خرید پلن ${price.title}',
        metadata: {
          'kind': 'coach_plan',
          'plan_id': planId,
          'plan_title': price.title,
          'validity_days': price.validityDays,
          'subscription_type': targetType.name,
        },
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        expiresAt: PaymentConstants.getTransactionExpiry(),
      );

      await _client.from('payment_transactions').insert(transaction.toJson());

      if (paymentMethod == 'wallet') {
        return await _processWalletPayment(
          transaction: transaction,
          price: price,
        );
      }
      return await _processDirectPayment(transaction);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در خرید پلن مربی: $e');
      }
      return {
        'success': false,
        'error': 'خطا در پردازش خرید: $e',
        'code': 'PROCESSING_ERROR',
      };
    }
  }

  Future<Map<String, dynamic>> _processWalletPayment({
    required PaymentTransaction transaction,
    required AiCoachPlanPrice price,
  }) async {
    final wallet = await _walletService.getUserWallet();
    final balance = wallet?.availableBalance ?? 0;
    if (balance < transaction.finalAmount) {
      return {
        'success': false,
        'error': 'موجودی کیف پول کافی نیست',
        'code': 'INSUFFICIENT_BALANCE',
        'required_amount': transaction.finalAmount,
        'available_balance': balance,
      };
    }

    try {
      await _walletService.payFromWallet(
        amount: transaction.finalAmount,
        description: transaction.description,
        referenceId: transaction.id,
        metadata: transaction.metadata,
      );
    } catch (e) {
      final msg = e.toString();
      final insufficient = msg.contains('موجودی');
      return {
        'success': false,
        'error': insufficient
            ? 'موجودی کیف پول کافی نیست'
            : 'خطا در کسر از کیف پول',
        'code': insufficient
            ? 'INSUFFICIENT_BALANCE'
            : 'WALLET_DEDUCTION_FAILED',
      };
    }

    await _client
        .from('payment_transactions')
        .update({
          'status': TransactionStatus.completed.name,
          'gateway_transaction_id': transaction.id,
          'completed_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        })
        .eq('id', transaction.id);

    if (transaction.discountCode != null &&
        transaction.discountCode!.isNotEmpty) {
      await _discountService.applyDiscountCode(
        code: transaction.discountCode!,
        userId: transaction.userId,
        transactionId: transaction.id,
        originalAmount: transaction.amount,
        discountAmount: transaction.discountAmount,
      );
    }

    try {
      final subscription = await _activateFromTransaction(
        transaction: transaction,
        price: price,
      );
      return {
        'success': true,
        'message': 'پلن با موفقیت فعال شد',
        'payment_method': 'wallet',
        'transaction_id': transaction.id,
        'subscription_id': subscription.id,
        'plan_id': price.planId,
        'plan_title': price.title,
      };
    } catch (e) {
      await _walletService.refundToWallet(
        amount: transaction.finalAmount,
        transactionId: 'refund-${transaction.id}',
        description: 'بازگشت وجه به‌دلیل خطا در فعال‌سازی پلن',
        metadata: transaction.metadata,
      );
      await _client
          .from('payment_transactions')
          .update({
            'status': TransactionStatus.cancelled.name,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transaction.id);
      return {
        'success': false,
        'error': e.toString().contains('همین پلن')
            ? 'شما همین پلن را فعال دارید'
            : 'خطا در فعال‌سازی پلن. مبلغ به کیف پول بازگردانده شد.',
        'code': 'ACTIVATION_FAILED',
      };
    }
  }

  Future<Map<String, dynamic>> _processDirectPayment(
    PaymentTransaction transaction,
  ) async {
    try {
      final callbackUrl =
          '${AppConfig.zibalCallbackUrl}?orderId=${transaction.id}&type=coach_plan';
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
        'plan_id': transaction.metadata?['plan_id'],
        'plan_title': transaction.metadata?['plan_title'],
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'خطا در پردازش پرداخت مستقیم: $e',
        'code': 'DIRECT_PAYMENT_ERROR',
      };
    }
  }

  /// تایید پرداخت درگاه و فعال‌سازی پلن
  Future<Map<String, dynamic>> verifyDirectPayment({
    required String transactionId,
    required String trackId,
  }) async {
    try {
      final transactionResponse = await _client
          .from('payment_transactions')
          .select()
          .eq('id', transactionId)
          .single();

      final transaction = PaymentTransaction.fromJson(transactionResponse);

      if (transaction.status == TransactionStatus.completed) {
        return {
          'success': true,
          'message': 'پرداخت قبلاً تایید شده است',
          'transaction_id': transactionId,
          'plan_title': transaction.metadata?['plan_title'],
        };
      }

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

      await _client
          .from('payment_transactions')
          .update({
            'status': TransactionStatus.completed.name,
            'gateway_transaction_id': trackId,
            'gateway_tracking_code': verifyResult!['refNumber'],
            'completed_at': DateTime.now().toIso8601String(),
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', transactionId);

      if (transaction.discountCode != null &&
          transaction.discountCode!.isNotEmpty) {
        await _discountService.applyDiscountCode(
          code: transaction.discountCode!,
          userId: transaction.userId,
          transactionId: transaction.id,
          originalAmount: transaction.amount,
          discountAmount: transaction.discountAmount,
        );
      }

      final planId =
          transaction.metadata?['plan_id']?.toString() ??
          CoachPlanCatalog.coachProId;
      final price = await _priceService.getActivePrice(planId);
      final subscription = await _activateFromTransaction(
        transaction: transaction,
        price: price,
      );

      return {
        'success': true,
        'message': 'پرداخت با موفقیت تایید شد',
        'transaction_id': transactionId,
        'subscription_id': subscription.id,
        'plan_id': planId,
        'plan_title': transaction.metadata?['plan_title'] ?? price.title,
        'ref_number': verifyResult['refNumber'],
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در تایید پرداخت پلن مربی: $e');
      }
      return {
        'success': false,
        'error': e.toString().contains('همین پلن')
            ? 'شما همین پلن را فعال دارید'
            : 'خطا در تایید پرداخت: $e',
        'code': 'VERIFY_ERROR',
      };
    }
  }

  Future<Subscription> _activateFromTransaction({
    required PaymentTransaction transaction,
    required AiCoachPlanPrice price,
  }) async {
    final planId =
        transaction.metadata?['plan_id']?.toString() ?? price.planId;
    final type = CoachPlanCatalog.subscriptionTypeForPlanId(planId);
    final validityDays =
        (transaction.metadata?['validity_days'] as num?)?.toInt() ??
        price.validityDays;

    final subscription = await _subscriptionService.createAndActivateCoachPlan(
      type: type,
      price: transaction.finalAmount,
      validityDays: validityDays,
      transactionId: transaction.id,
      metadata: {
        ...?transaction.metadata,
        'payment_transaction_id': transaction.id,
      },
    );

    if (subscription == null) {
      throw Exception('ایجاد اشتراک ناموفق بود');
    }

    try {
      await WorkoutProgramTokenService().grantPurchaseTokens(
        userId: subscription.userId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('هشدار: اعطای توکن ساخت برنامه ناموفق: $e');
      }
    }

    return subscription;
  }
}
