import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/entitlement/coach_capability.dart';
import 'package:gymaipro/ai/entitlement/entitlement_registry.dart';
import 'package:gymaipro/ai/entitlement/subscription_capability_map.dart';
import 'package:gymaipro/payment/services/ai_program_access.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Daily free-tier quota for coach consult chat.
///
/// Paid AI program pass (`unlimitedMessages`) removes the cap.
/// Counters are scoped per userId (with one-time migrate from legacy global keys).
class CoachChatDailyLimitService {
  CoachChatDailyLimitService({
    EntitlementRegistry registry = const EntitlementRegistry(),
  }) : _registry = registry;

  static const String _legacyCountKey = 'ai_chat_daily_messages';
  static const String _legacyResetDateKey = 'ai_chat_last_reset_date';

  final EntitlementRegistry _registry;

  int get dailyLimit {
    return _registry
            .capabilityDefinition(CoachCapability.coachConversation)
            ?.defaultDailyLimit ??
        10;
  }

  Future<CoachChatDailyLimitSnapshot> load({String? userId}) async {
    final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) {
      return CoachChatDailyLimitSnapshot(
        used: 0,
        limit: dailyLimit,
        unlimited: false,
        canSend: false,
      );
    }

    final unlimited = await _hasUnlimitedMessages(uid);
    if (unlimited) {
      return CoachChatDailyLimitSnapshot(
        used: 0,
        limit: dailyLimit,
        unlimited: true,
        canSend: true,
      );
    }

    final used = await _readUsedToday(uid);
    return CoachChatDailyLimitSnapshot(
      used: used,
      limit: dailyLimit,
      unlimited: false,
      canSend: used < dailyLimit,
    );
  }

  /// Usage count to feed into entitlement snapshots (0 when unlimited).
  Future<int> dailyUsageForEntitlement({required String userId}) async {
    final snapshot = await load(userId: userId);
    if (snapshot.unlimited) return 0;
    return snapshot.used;
  }

  Future<void> recordSuccessfulReply({String? userId}) async {
    final uid = userId ?? Supabase.instance.client.auth.currentUser?.id;
    if (uid == null || uid.isEmpty) return;

    try {
      if (await _hasUnlimitedMessages(uid)) return;

      final prefs = await SharedPreferences.getInstance();
      await _ensureTodayBucket(prefs, uid);
      final used = prefs.getInt(_countKey(uid)) ?? 0;
      if (used >= dailyLimit) return;
      await prefs.setInt(_countKey(uid), used + 1);
    } on Object catch (e) {
      if (kDebugMode) {
        debugPrint('CoachChatDailyLimitService.record failed: $e');
      }
    }
  }

  Future<bool> _hasUnlimitedMessages(String userId) async {
    try {
      final access = await AiProgramAccess().load(userId: userId);
      // Unlimited chat only after the program is delivered and the clock started.
      if (!access.hasPass) return false;
      return SubscriptionCapabilityMap.forPlan(
        access.plan,
      ).contains(CoachCapability.unlimitedMessages);
    } on Object {
      return false;
    }
  }

  Future<int> _readUsedToday(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    await _ensureTodayBucket(prefs, userId);
    return prefs.getInt(_countKey(userId)) ?? 0;
  }

  Future<void> _ensureTodayBucket(
    SharedPreferences prefs,
    String userId,
  ) async {
    final today = _dateKey(DateTime.now());
    final dateKey = _resetDateKey(userId);
    final countKey = _countKey(userId);
    final stored = prefs.getString(dateKey);
    if (stored == today) return;

    // Migrate same-day legacy device-global counters once per user.
    if (stored == null) {
      final legacyDate = prefs.getString(_legacyResetDateKey);
      final legacyCount = prefs.getInt(_legacyCountKey);
      if (legacyDate == today && legacyCount != null) {
        await prefs.setString(dateKey, today);
        await prefs.setInt(countKey, legacyCount);
        return;
      }
    }

    await prefs.setString(dateKey, today);
    await prefs.setInt(countKey, 0);
  }

  static String _countKey(String userId) => 'ai_chat_daily_messages_$userId';

  static String _resetDateKey(String userId) =>
      'ai_chat_last_reset_date_$userId';

  static String _dateKey(DateTime value) {
    final y = value.year.toString().padLeft(4, '0');
    final m = value.month.toString().padLeft(2, '0');
    final d = value.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

class CoachChatDailyLimitSnapshot {
  const CoachChatDailyLimitSnapshot({
    required this.used,
    required this.limit,
    required this.unlimited,
    required this.canSend,
  });

  final int used;
  final int limit;
  final bool unlimited;
  final bool canSend;

  int get remaining => unlimited ? limit : (limit - used).clamp(0, limit);
}
