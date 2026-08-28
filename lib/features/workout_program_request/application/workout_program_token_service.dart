import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/coach_subscription_plan.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/services/ai_program_access.dart';
import 'package:gymaipro/payment/services/subscription_service.dart';
import 'package:gymaipro/utils/auth_helper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// دسترسی ساخت برنامه: با پاس فعال (خرید برنامه AI) آزاد است.
///
/// موجودی توکن فقط برای سازگاری با دادهٔ قدیمی نگه داشته می‌شود و دیگر
/// مسیر ساخت را برای کاربر دارای پاس فعال مسدود نمی‌کند.
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
  final AiProgramAccess _aiAccess = AiProgramAccess();

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

  /// سازگاری با خرید موفق — دیگر برای دسترسی لازم نیست.
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

  /// فقط دیباگ: موجودی توکن ساخت برنامه را صفر می‌کند.
  Future<void> clearTokensForDebug({String? userId}) async {
    assert(kDebugMode, 'clearTokensForDebug is debug-only');
    if (!kDebugMode) return;
    final uid = await _resolveUserId(userId);
    if (uid == null) return;
    await _setBalance(uid, 0);
  }

  /// No-op موفق وقتی پاس فعال است؛ در غیر این صورت موجودی قدیمی را کم می‌کند.
  Future<bool> consumeToken({String? userId}) async {
    final uid = await _resolveUserId(userId);
    if (uid == null) return false;

    if (await _aiAccess.hasPaidAccess(userId: uid)) {
      return true;
    }

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

    final snapshot = await _aiAccess.load(userId: uid);
    if (!snapshot.hasPaidAccess) {
      return const WorkoutProgramAccess(
        canBuild: false,
        reason: WorkoutProgramAccessReason.needsSubscription,
        remainingTokens: 0,
        plan: CoachSubscriptionPlan.free,
        message:
            'سوال‌ها رایگان است؛ برای ساخت برنامه با زدن «بساز»، '
            'هزینه برنامه مربی هوشمند گرفته می‌شود. '
            'اعتبار دوره از وقتی برنامه‌ات آماده شود شروع می‌شود.',
      );
    }

    final tokens = await remainingTokens(userId: uid);
    return WorkoutProgramAccess(
      canBuild: true,
      reason: WorkoutProgramAccessReason.ok,
      remainingTokens: tokens,
      plan: snapshot.plan,
      daysRemaining: snapshot.daysRemaining,
      entitlementStarted: snapshot.hasPass,
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
    this.daysRemaining = 0,
    this.entitlementStarted = false,
  });

  final bool canBuild;
  final WorkoutProgramAccessReason reason;
  final int remainingTokens;
  final CoachSubscriptionPlan plan;
  final String? message;
  final int daysRemaining;

  /// True when the paid period clock has started (program delivered).
  final bool entitlementStarted;
}
