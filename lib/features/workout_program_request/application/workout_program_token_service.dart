import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// توکن ساخت برنامه تمرینی: با خرید پلن مربوطه ۱ توکن می‌آید؛ هر ساخت موفق ۱ توکن مصرف می‌کند.
class WorkoutProgramTokenService {
  factory WorkoutProgramTokenService() => _instance;
  WorkoutProgramTokenService._internal();
  static final WorkoutProgramTokenService _instance =
      WorkoutProgramTokenService._internal();

  static const String featureName = 'workout_program_generation';
  static const String balanceUsageType = 'token_balance';
  static const String bootstrapUsageType = 'token_bootstrap';
  static const String _localBalanceKey = 'workout_program_token_balance';
  static const int tokensPerPurchase = 1;

  final SupabaseClient _client = Supabase.instance.client;
  final SubscriptionService _subscriptions = SubscriptionService();

  Future<int> remainingTokens({String? userId}) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) return 0;

    await _bootstrapLegacySubscriberIfNeeded(uid);

    try {
      final response = await _client
          .from('user_feature_usage')
          .select('usage_count')
          .eq('user_id', uid)
          .eq('feature_name', featureName)
          .eq('usage_type', balanceUsageType)
          .maybeSingle();

      if (response != null && response['usage_count'] != null) {
        final balance = (response['usage_count'] as num).toInt();
        await _saveLocal(balance);
        return balance < 0 ? 0 : balance;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProgramToken] read balance failed: $e');
      }
    }

    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_localBalanceKey) ?? 0;
  }

  /// پس از خرید موفق Coach Pro / Ultimate AI
  Future<void> grantPurchaseTokens({
    String? userId,
    int count = tokensPerPurchase,
  }) async {
    if (count <= 0) return;
    final uid = await _resolveUserId(userId);
    if (uid == null) return;

    final current = await remainingTokens(userId: uid);
    await _setBalance(uid, current + count);
  }

  Future<bool> consumeToken({String? userId}) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) return false;

    final current = await remainingTokens(userId: uid);
    if (current <= 0) return false;
    await _setBalance(uid, current - 1);
    return true;
  }

  Future<WorkoutProgramAccess> checkAccess({String? userId}) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) {
      return const WorkoutProgramAccess(
        canBuild: false,
        reason: WorkoutProgramAccessReason.notLoggedIn,
        remainingTokens: 0,
        plan: CoachSubscriptionPlan.free,
        message: 'برای ساخت برنامه ابتدا وارد حساب شو.',
      );
    }

    final subscription = await _subscriptions.peekActiveSubscription(
      userId: uid,
    );
    final plan = subscription == null
        ? CoachSubscriptionPlan.free
        : CoachPlanCatalog.planFromSubscriptionType(subscription.type);

    final caps = SubscriptionCapabilityMap.forPlan(plan);
    final hasCapability = caps.contains(CoachCapability.generateWorkout);

    if (!hasCapability) {
      return WorkoutProgramAccess(
        canBuild: false,
        reason: WorkoutProgramAccessReason.needsSubscription,
        remainingTokens: 0,
        plan: plan,
        message:
            'ساخت برنامه تمرینی فقط با اشتراک Coach Pro یا Ultimate AI فعال می‌شود.',
      );
    }

    final tokens = await remainingTokens(userId: uid);
    if (tokens <= 0) {
      return WorkoutProgramAccess(
        canBuild: false,
        reason: WorkoutProgramAccessReason.noTokens,
        remainingTokens: 0,
        plan: plan,
        message:
            'توکن ساخت برنامه‌ات تموم شده. با خرید/تمدید پلن یک توکن جدید می‌گیری.',
      );
    }

    return WorkoutProgramAccess(
      canBuild: true,
      reason: WorkoutProgramAccessReason.ok,
      remainingTokens: tokens,
      plan: plan,
    );
  }

  /// مشترکین قبلی که پلن دارند ولی هنوز ردیف توکن ندارند → یک‌بار ۱ توکن
  Future<void> _bootstrapLegacySubscriberIfNeeded(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    const bootstrapLocalKey = 'workout_program_token_bootstrapped';
    if (prefs.containsKey(_localBalanceKey)) return;
    if (prefs.getBool(bootstrapLocalKey) == true) return;

    try {
      final existing = await _client
          .from('user_feature_usage')
          .select('usage_count')
          .eq('user_id', userId)
          .eq('feature_name', featureName)
          .eq('usage_type', balanceUsageType)
          .maybeSingle();
      if (existing != null) {
        final balance = (existing['usage_count'] as num?)?.toInt() ?? 0;
        await _saveLocal(balance);
        await prefs.setBool(bootstrapLocalKey, true);
        return;
      }

      final bootstrapped = await _client
          .from('user_feature_usage')
          .select('usage_count')
          .eq('user_id', userId)
          .eq('feature_name', featureName)
          .eq('usage_type', bootstrapUsageType)
          .maybeSingle();
      if (bootstrapped != null) {
        await prefs.setBool(bootstrapLocalKey, true);
        return;
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProgramToken] bootstrap db read skipped: $e');
      }
    }

    final subscription = await _subscriptions.peekActiveSubscription(
      userId: userId,
    );
    if (subscription == null) {
      await prefs.setBool(bootstrapLocalKey, true);
      return;
    }

    final plan = CoachPlanCatalog.planFromSubscriptionType(subscription.type);
    final caps = SubscriptionCapabilityMap.forPlan(plan);
    if (!caps.contains(CoachCapability.generateWorkout)) {
      await prefs.setBool(bootstrapLocalKey, true);
      return;
    }

    await _setBalance(userId, tokensPerPurchase);
    await prefs.setBool(bootstrapLocalKey, true);
    try {
      await _client.from('user_feature_usage').upsert({
        'user_id': userId,
        'feature_name': featureName,
        'usage_type': bootstrapUsageType,
        'usage_count': 1,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_name,usage_type');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProgramToken] bootstrap marker skipped: $e');
      }
    }
  }

  Future<void> _setBalance(String userId, int balance) async {
    final safe = balance < 0 ? 0 : balance;
    try {
      await _client.from('user_feature_usage').upsert({
        'user_id': userId,
        'feature_name': featureName,
        'usage_type': balanceUsageType,
        'usage_count': safe,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'user_id,feature_name,usage_type');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[ProgramToken] upsert balance failed: $e');
      }
    }
    await _saveLocal(safe);
  }

  Future<void> _saveLocal(int balance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_localBalanceKey, balance);
  }

  Future<String?> _resolveUserId(String? userId) async {
    if (userId != null && userId.trim().isNotEmpty) return userId;
    return AuthHelper.getCurrentUserId();
  }
}

enum WorkoutProgramAccessReason {
  ok,
  notLoggedIn,
  needsSubscription,
  noTokens,
}

class WorkoutProgramAccess {
  const WorkoutProgramAccess({
    required this.canBuild,
    required this.reason,
    required this.remainingTokens,
    required this.plan,
    this.message,
  });

  final bool canBuild;
  final WorkoutProgramAccessReason reason;
  final int remainingTokens;
  final CoachSubscriptionPlan plan;
  final String? message;
}
