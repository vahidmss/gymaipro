import 'package:gymaipro/models/meal_plan.dart';

import '../../../services/supabase_service.dart' as supabase_service;

class MealPlanService {
  Future<List<MealPlan>> getPlans() async {
    final response = await supabase_service.SupabaseService.client
        .from('meal_plans')
        .select()
        .order('created_at', ascending: false);
    return (response as List).map((json) => MealPlan.fromJson(json)).toList();
  }

  Future<MealPlan?> getPlanById(String id) async {
    final response = await supabase_service.SupabaseService.client
        .from('meal_plans')
        .select()
        .eq('id', id)
        .single();
    return MealPlan.fromJson(response);
  }

  Future<void> savePlan(MealPlan plan) async {
    print('=== MEAL PLAN SERVICE SAVE ===');
    print('Plan userId: ${plan.userId}');
    print('Plan toJson: ${plan.toJson()}');
    final client = supabase_service.SupabaseService.client;

    if (plan.id.isEmpty) {
      // Check if a plan with the same user_id and plan_name exists
      final existing = await client
          .from('meal_plans')
          .select('id')
          .eq('user_id', plan.userId)
          .eq('plan_name', plan.planName)
          .maybeSingle();

      if (existing != null && existing['id'] != null) {
        // If exists, update it
        print('Plan with same name exists, updating instead of inserting...');
        await client
            .from('meal_plans')
            .update(plan.toJson())
            .eq('id', existing['id']);
      } else {
        // If not, insert new
        print('Inserting new meal plan...');
        await client.from('meal_plans').insert(plan.toJson());
      }
    } else {
      // Update existing by id
      print('Updating existing meal plan...');
      await client.from('meal_plans').update(plan.toJson()).eq('id', plan.id);
    }
    print('Meal plan saved successfully');
  }

  Future<void> deletePlan(String id) async {
    await supabase_service.SupabaseService.client
        .from('meal_plans')
        .delete()
        .eq('id', id);
  }

  /// Get meal plan for a specific date
  Future<MealPlan?> getPlanForDate(DateTime date) async {
    try {
      final user = supabase_service.SupabaseService.client.auth.currentUser;
      if (user == null) {
        return null;
      }

      // For now, return the most recent plan
      // In the future, this could be enhanced to support date-specific plans
      final response = await supabase_service.SupabaseService.client
          .from('meal_plans')
          .select()
          .eq('user_id', user.id)
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (response != null) {
        return MealPlan.fromJson(response);
      }

      return null;
    } catch (e) {
      print('Error getting meal plan for date: $e');
      return null;
    }
  }
}
