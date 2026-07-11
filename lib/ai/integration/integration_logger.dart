import 'package:flutter/foundation.dart';
import 'package:gymaipro/ai/integration/integration_event.dart';

/// In-memory logger for the Coach v2 dry-run pipeline.
///
/// This logger never writes to database, storage, analytics, or network. It can
/// optionally print in debug builds for local diagnostics.
class IntegrationLogger {
  IntegrationLogger({this.debugPrintEnabled = false});

  /// Whether events should also be printed in debug mode.
  final bool debugPrintEnabled;

  final List<IntegrationEvent> _events = <IntegrationEvent>[];

  /// Immutable event snapshot.
  List<IntegrationEvent> get events =>
      List<IntegrationEvent>.unmodifiable(_events);

  /// Adds a pipeline event.
  void log(
    IntegrationEventType type,
    String message, {
    Map<String, Object?> metadata = const <String, Object?>{},
  }) {
    final event = IntegrationEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
      metadata: metadata,
    );
    _events.add(event);

    if (debugPrintEnabled && kDebugMode) {
      debugPrint('[CoachIntegration] ${type.name}: $message');
    }
  }

  /// Clears the in-memory events.
  void clear() {
    _events.clear();
  }
}
