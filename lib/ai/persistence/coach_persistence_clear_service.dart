import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/persistence/coach_persistence_keys.dart';
import 'package:gymaipro/ai/services/user_context_cache_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Clears coach-related local caches on logout.
///
/// Cloud rows remain attached to the authenticated account.
class CoachPersistenceClearService {
  static Future<void> clearLocalCoachData() async {
    try {
      await UserContextCacheService.clearCache();

      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().toList(growable: false);
      var removed = 0;

      for (final key in keys) {
        final shouldRemove = CoachPersistenceKeys.logoutPrefixes.any(key.startsWith);
        if (!shouldRemove) continue;
        await prefs.remove(key);
        removed++;
      }

      if (kDebugMode) {
        debugPrint('[CoachPersistence] cleared $removed local keys on logout');
      }
    } on Object catch (error) {
      if (kDebugMode) {
        debugPrint('[CoachPersistence] logout clear failed: $error');
      }
    }
  }
}
