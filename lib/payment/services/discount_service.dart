import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/discount_code.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس مدیریت کدهای تخفیف
class DiscountService {
  factory DiscountService() => _instance;
  DiscountService._internal();
  static final DiscountService _instance = DiscountService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// اعتبارسنجی کد تخفیف
  Future<Map<String, dynamic>> validateDiscountCode({
    required String code,
    required int originalAmount,
    String? userId,
  }) async {
    try {
      userId ??= await AuthHelper.getCurrentUserId();
      if (userId == null) {
        return {'valid': false, 'error': 'کاربر وارد نشده است'};
      }

      // جستجوی کد تخفیف
      final discountCode = await _getDiscountCode(code);
      if (discountCode == null) {
        return {'valid': false, 'error': PaymentConstants.invalidDiscountCode};
      }

      // بررسی قابلیت استفاده
      if (!discountCode.isUsable) {
        if (discountCode.isExpired) {
          return {
            'valid': false,
            'error': PaymentConstants.expiredDiscountCode,
          };
        } else if (discountCode.isUsedUp) {
          return {'valid': false, 'error': 'کد تخفیف تمام شده است'};
        } else {
          return {'valid': false, 'error': 'کد تخفیف غیرفعال است'};
        }
      }

      // بررسی حداقل مبلغ خرید
      if (originalAmount < discountCode.minPurchaseAmount) {
        return {
          'valid': false,
          'error': 'حداقل مبلغ خرید ${discountCode.formattedMinPurchase} است',
        };
      }

      // بررسی قابلیت استفاده برای کاربر
      final userUsageCount = await _getUserDiscountUsageCount(
        discountCode.id,
        userId,
      );
      final isNewUser = await _isNewUser(userId);

      if (!discountCode.canUseForUser(
        userId,
        userUsageCount: userUsageCount,
        isNewUser: isNewUser,
      )) {
        if (discountCode.newUsersOnly && !isNewUser) {
          return {
            'valid': false,
            'error': 'این کد تخفیف فقط برای کاربران جدید است',
          };
        } else if (discountCode.maxUsagePerUser != null &&
            userUsageCount >= discountCode.maxUsagePerUser!) {
          return {'valid': false, 'error': PaymentConstants.usedDiscountCode};
        } else {
          return {
            'valid': false,
            'error': 'شما مجاز به استفاده از این کد تخفیف نیستید',
          };
        }
      }

      // محاسبه تخفیف
      final discountAmount = discountCode.calculateDiscount(originalAmount);
      final finalAmount = originalAmount - discountAmount;

      return {
        'valid': true,
        'discount_code': discountCode.toJson(),
        'original_amount': originalAmount,
        'discount_amount': discountAmount,
        'final_amount': finalAmount,
        'discount_percentage': discountCode.type == DiscountType.percentage
            ? discountCode.value
            : null,
        'message': 'کد تخفیف اعمال شد',
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در اعتبارسنجی کد تخفیف: $e');
      }
      return {'valid': false, 'error': 'خطا در بررسی کد تخفیف'};
    }
  }

  /// اعمال کد تخفیف و ثبت استفاده
  Future<bool> applyDiscountCode({
    required String code,
    required String userId,
    required String transactionId,
    required int originalAmount,
    required int discountAmount,
  }) async {
    try {
      final discountCode = await _getDiscountCode(code);
      if (discountCode == null) return false;

      // ثبت استفاده از کد تخفیف
      await _client.from('discount_usages').insert({
        'discount_code_id': discountCode.id,
        'user_id': userId,
        'transaction_id': transactionId,
        'original_amount': originalAmount,
        'discount_amount': discountAmount,
        'used_at': DateTime.now().toIso8601String(),
      });

      // به‌روزرسانی تعداد استفاده
      await _client
          .from('discount_codes')
          .update({
            'used_count': discountCode.usedCount + 1,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', discountCode.id);

      if (kDebugMode) {
        print('کد تخفیف $code اعمال شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در اعمال کد تخفیف: $e');
      }
      return false;
    }
  }

  /// ایجاد کد تخفیف جدید
  Future<DiscountCode?> createDiscountCode({
    required String code,
    required String title,
    required DiscountType type,
    required double value,
    String description = '',
    int? maxDiscountAmount,
    int minPurchaseAmount = 0,
    DateTime? expiryDate,
    int? maxTotalUsage,
    int? maxUsagePerUser,
    bool newUsersOnly = false,
    List<String>? allowedUsers,
    List<String>? applicableCategories,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final createdBy = await AuthHelper.getCurrentUserId();
      if (createdBy == null) throw Exception('کاربر وارد نشده است');

      // بررسی تکراری نبودن کد
      final existingCode = await _getDiscountCode(code);
      if (existingCode != null) {
        throw Exception('کد تخفیف تکراری است');
      }

      final discountCode = DiscountCodeBuilder()
          .setCode(code)
          .setTitle(title)
          .setDescription(description)
          .setCreatedBy(createdBy);

      if (type == DiscountType.percentage) {
        discountCode.setPercentageDiscount(value, maxAmount: maxDiscountAmount);
      } else {
        discountCode.setFixedDiscount(value.round());
      }

      discountCode.setMinPurchaseAmount(minPurchaseAmount);

      if (expiryDate != null) {
        discountCode.setExpiryDate(expiryDate);
      }

      final newDiscountCode = discountCode.build();

      // اضافه کردن فیلدهای اضافی
      final discountData = newDiscountCode.toJson();
      discountData.addAll({
        'max_total_usage': maxTotalUsage,
        'max_usage_per_user': maxUsagePerUser,
        'new_users_only': newUsersOnly,
        'allowed_users': allowedUsers != null ? jsonEncode(allowedUsers) : null,
        'applicable_categories': applicableCategories != null
            ? jsonEncode(applicableCategories)
            : null,
        'metadata': metadata != null ? jsonEncode(metadata) : null,
      });

      final response = await _client
          .from('discount_codes')
          .insert(discountData)
          .select()
          .single();

      if (kDebugMode) {
        print('کد تخفیف جدید ایجاد شد: $code');
      }

      return DiscountCode.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ایجاد کد تخفیف: $e');
      }
      return null;
    }
  }

  /// دریافت کدهای تخفیف فعال
  Future<List<DiscountCode>> getActiveDiscountCodes({
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      final response = await _client
          .from('discount_codes')
          .select()
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .range(offset, offset + limit - 1);

      return response.map<DiscountCode>(DiscountCode.fromJson).toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت کدهای تخفیف فعال: $e');
      }
      return [];
    }
  }

  /// دریافت کدهای تخفیف کاربر
  Future<List<Map<String, dynamic>>> getUserDiscountUsages({
    String? userId,
    int limit = 50,
    int offset = 0,
  }) async {
    try {
      userId ??= await AuthHelper.getCurrentUserId();
      if (userId == null) return [];

      final response = await _client
          .from('discount_usages')
          .select('''
            *,
            discount_codes (
              code,
              title,
              type,
              value
            )
          ''')
          .eq('user_id', userId)
          .order('used_at', ascending: false)
          .range(offset, offset + limit - 1);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تاریخچه کدهای تخفیف کاربر: $e');
      }
      return [];
    }
  }

  /// غیرفعال کردن کد تخفیف
  Future<bool> deactivateDiscountCode(String codeId) async {
    try {
      await _client
          .from('discount_codes')
          .update({
            'status': 'inactive',
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', codeId);

      if (kDebugMode) {
        print('کد تخفیف $codeId غیرفعال شد');
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در غیرفعال کردن کد تخفیف: $e');
      }
      return false;
    }
  }

  /// به‌روزرسانی کدهای تخفیف منقضی شده
  Future<void> updateExpiredDiscountCodes() async {
    try {
      final now = DateTime.now();

      await _client
          .from('discount_codes')
          .update({'status': 'expired', 'updated_at': now.toIso8601String()})
          .eq('status', 'active')
          .lt('expiry_date', now.toIso8601String());

      if (kDebugMode) {
        print('کدهای تخفیف منقضی شده به‌روزرسانی شدند');
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در به‌روزرسانی کدهای تخفیف منقضی: $e');
      }
    }
  }

  /// دریافت آمار کدهای تخفیف
  Future<Map<String, dynamic>> getDiscountStats() async {
    try {
      final activeCodes = await _client
          .from('discount_codes')
          .select('count')
          .eq('status', 'active');

      final expiredCodes = await _client
          .from('discount_codes')
          .select('count')
          .eq('status', 'expired');

      final totalUsages = await _client.from('discount_usages').select('count');

      final totalDiscountAmount = await _client
          .from('discount_usages')
          .select('discount_amount');

      int totalDiscount = 0;
      if (totalDiscountAmount.isNotEmpty) {
        for (final item in totalDiscountAmount) {
          totalDiscount += item['discount_amount'] as int? ?? 0;
        }
      }

      return {
        'active_codes': activeCodes.length,
        'expired_codes': expiredCodes.length,
        'total_usages': totalUsages.length,
        'total_discount_amount': totalDiscount,
      };
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت آمار کدهای تخفیف: $e');
      }
      return {};
    }
  }

  /// متدهای کمکی خصوصی

  Future<DiscountCode?> _getDiscountCode(String code) async {
    try {
      final response = await _client
          .from('discount_codes')
          .select()
          .eq('code', code.toUpperCase())
          .maybeSingle();

      if (response != null) {
        return DiscountCode.fromJson(response);
      }
      return null;
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت کد تخفیف: $e');
      }
      return null;
    }
  }

  Future<int> _getUserDiscountUsageCount(
    String discountCodeId,
    String userId,
  ) async {
    try {
      final response = await _client
          .from('discount_usages')
          .select('count')
          .eq('discount_code_id', discountCodeId)
          .eq('user_id', userId);

      return response.length;
    } catch (e) {
      return 0;
    }
  }

  Future<bool> _isNewUser(String userId) async {
    try {
      // کاربر جدید کسی است که کمتر از 30 روز از ثبت‌نامش گذشته
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));

      final response = await _client
          .from('profiles')
          .select('created_at')
          .eq('id', userId)
          .single();

      final createdAt = DateTime.parse(response['created_at'] as String);
      return createdAt.isAfter(thirtyDaysAgo);
    } catch (e) {
      return false;
    }
  }
}
