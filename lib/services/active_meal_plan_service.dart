import 'package:flutter/foundation.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ActiveMealPlanService {
  ActiveMealPlanService();

  final SupabaseClient _db = Supabase.instance.client;

  /// بررسی می‌کند که آیا خطا مربوط به شبکه است یا دیتابیس
  bool _isNetworkError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('socketexception') ||
        errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('clientexception') ||
        errorString.contains('connection') ||
        errorString.contains('network');
  }

  /// بررسی می‌کند که آیا خطا مربوط به عدم وجود ستون است
  bool _isColumnNotFoundError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('column') &&
        (errorString.contains('does not exist') ||
            errorString.contains('not found') ||
            errorString.contains('unknown column'));
  }

  Future<String?> getActiveMealPlanId() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return null;

      final row = await _db
          .from('profiles')
          .select('active_meal_plan_id')
          .eq('id', userId)
          .maybeSingle();

      return row?['active_meal_plan_id'] as String?;
    } catch (e) {
      if (kDebugMode) {
        if (_isNetworkError(e)) {
          debugPrint('[ActiveMealPlan] getActiveMealPlanId network error: $e');
          debugPrint('[ActiveMealPlan] مشکل اتصال به اینترنت یا سرور Supabase');
        } else if (_isColumnNotFoundError(e)) {
          debugPrint('[ActiveMealPlan] getActiveMealPlanId column error: $e');
          debugPrint(
            '[ActiveMealPlan] ⚠️ ستون active_meal_plan_id در جدول profiles وجود ندارد!',
          );
          debugPrint(
            '[ActiveMealPlan] لطفاً فایل SQL زیر را در Supabase SQL Editor اجرا کنید:',
          );
          debugPrint(
            '[ActiveMealPlan] sql/add_active_meal_plan_id_to_profiles.sql',
          );
        } else {
          debugPrint('[ActiveMealPlan] getActiveMealPlanId error: $e');
        }
      }
      // در صورت خطای شبکه یا ستون، null برمی‌گردانیم
      return null;
    }
  }

  Future<bool> setActiveMealPlan(String mealPlanId) async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;

      await _db
          .from('profiles')
          .update({
            'active_meal_plan_id': mealPlanId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (_isNetworkError(e)) {
          debugPrint('[ActiveMealPlan] setActiveMealPlan network error: $e');
          debugPrint('[ActiveMealPlan] مشکل اتصال به اینترنت یا سرور Supabase');
        } else if (_isColumnNotFoundError(e)) {
          debugPrint('[ActiveMealPlan] setActiveMealPlan column error: $e');
          debugPrint(
            '[ActiveMealPlan] ⚠️ ستون active_meal_plan_id در جدول profiles وجود ندارد!',
          );
          debugPrint(
            '[ActiveMealPlan] لطفاً فایل SQL زیر را در Supabase SQL Editor اجرا کنید:',
          );
          debugPrint(
            '[ActiveMealPlan] sql/add_active_meal_plan_id_to_profiles.sql',
          );
        } else {
          debugPrint('[ActiveMealPlan] setActiveMealPlan error: $e');
        }
      }
      return false;
    }
  }

  Future<bool> clearActiveMealPlan() async {
    try {
      final userId = await AuthHelper.getCurrentUserId();
      if (userId == null) return false;

      await _db
          .from('profiles')
          .update({
            'active_meal_plan_id': null,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', userId);
      return true;
    } catch (e) {
      if (kDebugMode) {
        if (_isNetworkError(e)) {
          debugPrint('[ActiveMealPlan] clearActiveMealPlan network error: $e');
          debugPrint('[ActiveMealPlan] مشکل اتصال به اینترنت یا سرور Supabase');
        } else if (_isColumnNotFoundError(e)) {
          debugPrint('[ActiveMealPlan] clearActiveMealPlan column error: $e');
          debugPrint(
            '[ActiveMealPlan] ⚠️ ستون active_meal_plan_id در جدول profiles وجود ندارد!',
          );
          debugPrint(
            '[ActiveMealPlan] لطفاً فایل SQL زیر را در Supabase SQL Editor اجرا کنید:',
          );
          debugPrint(
            '[ActiveMealPlan] sql/add_active_meal_plan_id_to_profiles.sql',
          );
        } else {
          debugPrint('[ActiveMealPlan] clearActiveMealPlan error: $e');
        }
      }
      return false;
    }
  }
}
