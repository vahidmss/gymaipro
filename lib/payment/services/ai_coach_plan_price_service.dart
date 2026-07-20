import 'package:flutter/foundation.dart';
import 'package:gymaipro/payment/models/ai_coach_plan_price.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// سرویس قیمت پلن‌های مربی هوشمند
class AiCoachPlanPriceService {
  factory AiCoachPlanPriceService() => _instance;
  AiCoachPlanPriceService._internal();
  static final AiCoachPlanPriceService _instance =
      AiCoachPlanPriceService._internal();

  final SupabaseClient _client = Supabase.instance.client;

  /// قیمت فعال یک پلن (با fallback کاتالوگ)
  Future<AiCoachPlanPrice> getActivePrice(String planId) async {
    try {
      final response = await _client
          .from('ai_coach_plan_prices')
          .select()
          .eq('plan_id', planId)
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return AiCoachPlanPrice.fromJson(response);
      }
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت قیمت پلن $planId: $e');
      }
    }
    return CoachPlanCatalog.fallbackPrice(planId);
  }

  /// همه قیمت‌های فعال فروش‌پذیر
  Future<List<AiCoachPlanPrice>> getActiveSellablePrices() async {
    final results = <AiCoachPlanPrice>[];
    for (final planId in CoachPlanCatalog.sellablePlanIds) {
      results.add(await getActivePrice(planId));
    }
    return results;
  }

  /// همه ردیف‌ها برای ادمین
  Future<List<AiCoachPlanPrice>> getAllPrices() async {
    try {
      final response = await _client
          .from('ai_coach_plan_prices')
          .select()
          .order('created_at', ascending: false);

      return (response as List<dynamic>)
          .map(
            (json) => AiCoachPlanPrice.fromJson(json as Map<String, dynamic>),
          )
          .toList();
    } catch (e) {
      if (kDebugMode) {
        print('خطا در دریافت تمام قیمت‌های پلن AI: $e');
      }
      return [];
    }
  }

  /// غیرفعال کردن نسخه قبلی همان پلن و درج نسخه جدید
  Future<AiCoachPlanPrice?> upsertActivePrice({
    required String planId,
    required String title,
    required String description,
    required int priceRial,
    required int validityDays,
    required List<String> features,
    bool isActive = true,
  }) async {
    try {
      final userId = _client.auth.currentUser?.id;

      await _client
          .from('ai_coach_plan_prices')
          .update({'is_active': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('plan_id', planId)
          .eq('is_active', true);

      final response = await _client
          .from('ai_coach_plan_prices')
          .insert({
            'plan_id': planId,
            'title': title,
            'description': description,
            'price_rial': priceRial,
            'validity_days': validityDays,
            'features': features,
            'is_active': isActive,
            if (userId != null) 'created_by': userId,
          })
          .select()
          .single();

      return AiCoachPlanPrice.fromJson(response);
    } catch (e) {
      if (kDebugMode) {
        print('خطا در ذخیره قیمت پلن AI: $e');
      }
      return null;
    }
  }
}
