import 'dart:async';

import 'package:flutter/foundation.dart';

/// Best-effort background sync helper for coach persistence.
abstract final class CoachPersistenceSync {
  static void run(String label, Future<void> Function() action) {
    unawaited(
      action().catchError((Object error, StackTrace stack) {
        if (kDebugMode) {
          debugPrint('[CoachPersistence] $label sync failed: $error');
        }
      }),
    );
  }
}
