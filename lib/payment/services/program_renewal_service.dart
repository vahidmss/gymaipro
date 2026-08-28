import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/payment/services/trainer_subscription_service.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/workout_log/services/beginner_starter_program_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// قواعد تمدید برنامه مربی (الهام از Trainerize / ClassPass / اپ‌های کوچینگ):
/// - فقط برنامهٔ ارسال‌شدهٔ مربی (نه برنامهٔ مبتدی رایگان)
/// - قیمت = ۵۰٪ قیمت اصلی آخرین خرید همان مربی+تمرین؛ در غیر این صورت ۵۰٪ نرخ فعلی مربی
/// - مدت = ۳۳ روز از max(الان، انقضای فعلی) — همان پنجرهٔ تحویل برنامه
/// - اشتراک مربی هم ۳۰ روز از max(الان، انقضای اشتراک) تمدید/فعال می‌شود
/// - محتوای برنامه عوض نمی‌شود؛ فقط دسترسی باز می‌ماند (وفاداری به همان مربی)
class ProgramRenewalQuote {
  const ProgramRenewalQuote({
    required this.programId,
    required this.userId,
    required this.trainerId,
    required this.programName,
    required this.trainerName,
    required this.fullPriceRial,
    required this.renewPriceRial,
    required this.currentExpiry,
    required this.newExpiry,
    this.subscriptionId,
  });

  final String programId;
  final String userId;
  final String trainerId;
  final String programName;
  final String trainerName;
  final int fullPriceRial;
  final int renewPriceRial;
  final DateTime currentExpiry;
  final DateTime newExpiry;
  final String? subscriptionId;

  String get renewPriceLabel => PaymentConstants.formatAmount(renewPriceRial);
  String get fullPriceLabel => PaymentConstants.formatAmount(fullPriceRial);
  int get savingsRial => fullPriceRial - renewPriceRial;
}

class ProgramRenewalService {
  factory ProgramRenewalService() => _instance;
  ProgramRenewalService._internal();
  static final ProgramRenewalService _instance =
      ProgramRenewalService._internal();

  static const String metadataKind = 'program_renewal';
  static const double renewFactor = 0.5;
  static const int programExtensionDays = 33;
  static const int subscriptionExtensionDays = 30;

  final SupabaseClient _client = Supabase.instance.client;

  /// برآورد قیمت و تاریخ جدید برای تمدید
  Future<ProgramRenewalQuote?> quote({
    required String programId,
    required String userId,
  }) async {
    try {
      final program = await _client
          .from('workout_programs')
          .select(
            'id, program_name, user_id, trainer_id, sent_at, expiry_date, '
            'created_at, data, '
            'trainer:profiles!workout_programs_trainer_id_fkey('
            'id, username, first_name, last_name)',
          )
          .eq('id', programId)
          .eq('user_id', userId)
          .maybeSingle();

      if (program == null) return null;

      if (BeginnerStarterProgramService.isStarterProgramData(program['data'])) {
        return null;
      }

      final trainerId = (program['trainer_id'] as String?)?.trim() ?? '';
      if (trainerId.isEmpty) return null;

      final sentAt = DateTime.tryParse(program['sent_at']?.toString() ?? '');
      if (sentAt == null) return null;

      final createdAt = DateTime.tryParse(
        program['created_at']?.toString() ?? '',
      );
      var currentExpiry = DateTime.tryParse(
        program['expiry_date']?.toString() ?? '',
      );
      currentExpiry ??=
          (createdAt ?? sentAt).add(const Duration(days: programExtensionDays));

      final trainer = program['trainer'] as Map<String, dynamic>?;
      final trainerName = _formatTrainerName(trainer);
      final programName =
          (program['program_name'] as String?)?.trim().isNotEmpty ?? false
          ? (program['program_name'] as String).trim()
          : 'برنامه تمرینی';

      final priceInfo = await _resolveFullPriceRial(
        userId: userId,
        trainerId: trainerId,
        trainer: trainer,
      );
      if (priceInfo == null) return null;

      final renewPrice = (priceInfo.fullPriceRial * renewFactor).round();
      if (renewPrice < PaymentConstants.minPaymentAmount) {
        if (kDebugMode) {
          print(
            'RENEW: renew price $renewPrice below min '
            '${PaymentConstants.minPaymentAmount}',
          );
        }
        return null;
      }

      final base = DateTime.now().isAfter(currentExpiry)
          ? DateTime.now()
          : currentExpiry;
      final newExpiry = base.add(const Duration(days: programExtensionDays));

      return ProgramRenewalQuote(
        programId: programId,
        userId: userId,
        trainerId: trainerId,
        programName: programName,
        trainerName: trainerName,
        fullPriceRial: priceInfo.fullPriceRial,
        renewPriceRial: renewPrice,
        currentExpiry: currentExpiry,
        newExpiry: newExpiry,
        subscriptionId: priceInfo.subscriptionId,
      );
    } catch (e) {
      if (kDebugMode) {
        print('RENEW: quote failed: $e');
      }
      return null;
    }
  }

  /// بعد از پرداخت موفق: تمدید برنامه + اشتراک
  Future<Map<String, dynamic>> fulfill({
    required String programId,
    required String userId,
    required String trainerId,
    required int paidAmount,
    String? paymentTransactionId,
    String? existingSubscriptionId,
  }) async {
    try {
      final now = DateTime.now();

      final programRow = await _client
          .from('workout_programs')
          .select('id, expiry_date, created_at, sent_at')
          .eq('id', programId)
          .eq('user_id', userId)
          .maybeSingle();

      if (programRow == null) {
        return {
          'success': false,
          'error': 'برنامه پیدا نشد',
          'code': 'PROGRAM_NOT_FOUND',
        };
      }

      var currentExpiry = DateTime.tryParse(
        programRow['expiry_date']?.toString() ?? '',
      );
      if (currentExpiry == null) {
        final createdAt = DateTime.tryParse(
          programRow['created_at']?.toString() ?? '',
        );
        final sentAt = DateTime.tryParse(
          programRow['sent_at']?.toString() ?? '',
        );
        currentExpiry = (createdAt ?? sentAt ?? now).add(
          const Duration(days: programExtensionDays),
        );
      }

      final base = now.isAfter(currentExpiry) ? now : currentExpiry;
      final newExpiry = base.add(const Duration(days: programExtensionDays));

      await _client
          .from('workout_programs')
          .update({
            'expiry_date': newExpiry.toIso8601String(),
            'updated_at': now.toIso8601String(),
          })
          .eq('id', programId);

      String? subscriptionId = existingSubscriptionId;
      if (subscriptionId == null || subscriptionId.isEmpty) {
        subscriptionId = await _findLatestTrainingSubscriptionId(
          userId: userId,
          trainerId: trainerId,
        );
      }

      if (subscriptionId != null && subscriptionId.isNotEmpty) {
        final sub = await _client
            .from('trainer_subscriptions')
            .select('id, expiry_date')
            .eq('id', subscriptionId)
            .maybeSingle();

        if (sub != null) {
          final subExpiry =
              DateTime.tryParse(sub['expiry_date']?.toString() ?? '') ?? now;
          final subBase = now.isAfter(subExpiry) ? now : subExpiry;
          final newSubExpiry = subBase.add(
            const Duration(days: subscriptionExtensionDays),
          );

          await _client
              .from('trainer_subscriptions')
              .update({
                'expiry_date': newSubExpiry.toIso8601String(),
                'status': TrainerSubscriptionStatus.active
                    .toString()
                    .split('.')
                    .last,
                'updated_at': now.toIso8601String(),
                if (paymentTransactionId != null)
                  'payment_transaction_id': paymentTransactionId,
              })
              .eq('id', subscriptionId);
        }
      } else {
        // اگر اشتراک قبلی نبود، یک اشتراک فعال برای ادامهٔ رابطه می‌سازیم
        final created = await TrainerSubscriptionService().createSubscription(
          userId: userId,
          trainerId: trainerId,
          serviceType: TrainerServiceType.training,
          originalAmount: (paidAmount / renewFactor).round(),
          finalAmount: paidAmount,
          paymentTransactionId: paymentTransactionId,
          metadata: {
            'kind': metadataKind,
            'program_id': programId,
          },
        );
        if (created != null) {
          await TrainerSubscriptionService().updateSubscriptionStatus(
            created.id,
            TrainerSubscriptionStatus.active,
          );
          subscriptionId = created.id;
        }
      }

      if (kDebugMode) {
        print(
          'RENEW: fulfilled program=$programId until '
          '${newExpiry.toIso8601String()} sub=$subscriptionId',
        );
      }

      return {
        'success': true,
        'program_id': programId,
        'subscription_id': subscriptionId,
        'new_expiry': newExpiry.toIso8601String(),
        'amount': paidAmount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('RENEW: fulfill failed: $e');
      }
      return {
        'success': false,
        'error': 'خطا در ثبت تمدید: $e',
        'code': 'RENEWAL_FULFILL_FAILED',
      };
    }
  }

  Future<_PriceResolution?> _resolveFullPriceRial({
    required String userId,
    required String trainerId,
    Map<String, dynamic>? trainer,
  }) async {
    try {
      final rows = await _client
          .from('trainer_subscriptions')
          .select('id, original_amount, final_amount, created_at')
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq(
            'service_type',
            TrainerServiceType.training.toString().split('.').last,
          )
          .order('created_at', ascending: false)
          .limit(5);

      for (final row in rows as List<dynamic>) {
        final map = Map<String, dynamic>.from(row as Map);
        final original = (map['original_amount'] as num?)?.toInt() ?? 0;
        if (original >= PaymentConstants.minPaymentAmount) {
          return _PriceResolution(
            fullPriceRial: original,
            subscriptionId: map['id'] as String?,
          );
        }
        final paid = (map['final_amount'] as num?)?.toInt() ?? 0;
        if (paid >= PaymentConstants.minPaymentAmount) {
          // اگر فقط مبلغ نهایی داریم، آن را قیمت پایه در نظر می‌گیریم
          return _PriceResolution(
            fullPriceRial: paid,
            subscriptionId: map['id'] as String?,
          );
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RENEW: subscription price lookup failed: $e');
      }
    }

    // Fallback: نرخ فعلی مربی (تومان در پروفایل → ریال ×۱۰ مثل خرید اولیه)
    final costToman =
        (trainer?['monthly_training_cost'] as num?)?.toDouble() ?? 0;
    if (costToman > 0) {
      final rial = (costToman * 10).round();
      if (rial >= PaymentConstants.minPaymentAmount) {
        return _PriceResolution(fullPriceRial: rial);
      }
    }

    try {
      final profile = await _client
          .from('profiles')
          .select('monthly_training_cost')
          .eq('id', trainerId)
          .maybeSingle();
      final cost = (profile?['monthly_training_cost'] as num?)?.toDouble() ?? 0;
      if (cost > 0) {
        final rial = (cost * 10).round();
        if (rial >= PaymentConstants.minPaymentAmount) {
          return _PriceResolution(fullPriceRial: rial);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('RENEW: trainer rate fallback failed: $e');
      }
    }

    return null;
  }

  Future<String?> _findLatestTrainingSubscriptionId({
    required String userId,
    required String trainerId,
  }) async {
    try {
      final row = await _client
          .from('trainer_subscriptions')
          .select('id')
          .eq('user_id', userId)
          .eq('trainer_id', trainerId)
          .eq(
            'service_type',
            TrainerServiceType.training.toString().split('.').last,
          )
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return row?['id'] as String?;
    } catch (_) {
      return null;
    }
  }

  String _formatTrainerName(Map<String, dynamic>? trainer) {
    if (trainer == null) return 'مربی';
    final first = (trainer['first_name'] as String?)?.trim() ?? '';
    final last = (trainer['last_name'] as String?)?.trim() ?? '';
    final combined = '$first $last'.trim();
    if (combined.isNotEmpty) return combined;
    final username = (trainer['username'] as String?)?.trim() ?? '';
    if (username.isNotEmpty) return username;
    return 'مربی';
  }
}

class _PriceResolution {
  const _PriceResolution({
    required this.fullPriceRial,
    this.subscriptionId,
  });

  final int fullPriceRial;
  final String? subscriptionId;
}
