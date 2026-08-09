import 'package:flutter/foundation.dart';
import 'package:gymaipro/core/foreground_resume_coordinator.dart';
import 'package:gymaipro/core/user_presence.dart';
import 'package:gymaipro/services/simple_profile_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// نوشتن حضور سراسری کاربر در `profiles`.
///
/// - foreground: `last_seen_at` + `last_active_at` + `is_online=true`
/// - background: فقط `is_online=false` (زمان برای «چند دقیقه پیش» می‌ماند)
class PresenceService {
  PresenceService._();
  static final PresenceService instance = PresenceService._();

  /// با باز شدن اپ / resume / heartbeat.
  Future<void> bumpForeground({String source = 'presence'}) async {
    if (!ForegroundResumeCoordinator.shouldBumpPresence(source)) {
      return;
    }
    try {
      final now = DateTime.now().toUtc().toIso8601String();
      await SimpleProfileService.updateProfile({
        'last_seen_at': now,
        'last_active_at': now,
        'is_online': true,
      });
      if (kDebugMode) {
        debugPrint(
          'PresenceService: foreground bump ($source) window=${UserPresence.onlineWindow.inMinutes}m',
        );
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PresenceService.bumpForeground error: $e');
      }
    }
  }

  /// وقتی اپ می‌رود پس‌زمینه / بسته می‌شود.
  Future<void> markBackground({String source = 'background'}) async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) return;
      await SimpleProfileService.updateProfile({
        'is_online': false,
        // last_seen را دست نزن تا UI بتواند «X دقیقه پیش» بگوید
      });
      if (kDebugMode) {
        debugPrint('PresenceService: background ($source)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('PresenceService.markBackground error: $e');
      }
    }
  }
}
