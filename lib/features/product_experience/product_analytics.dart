import 'package:flutter/foundation.dart';

/// Product analytics events (EPIC 35) — no AI logic, observability only.
enum ProductAnalyticsEvent {
  workoutStarted('workout_started'),
  workoutFinished('workout_finished'),
  modifyUsed('modify_used'),
  reviewUsed('review_used'),
  coachChatOpened('coach_chat_opened'),
  coachChatMessageSent('coach_chat_message_sent'),
  coachHomeOpened('coach_home_opened'),
  workoutTodayOpened('workout_today_opened');

  const ProductAnalyticsEvent(this.name);

  final String name;
}

/// Lightweight event sink for release candidate instrumentation.
///
/// Events are buffered in-memory for debug inspection. Wire to a remote sink
/// post-release without touching Coach engines.
abstract final class ProductAnalytics {
  static final List<ProductAnalyticsRecord> _buffer = <ProductAnalyticsRecord>[];
  static const int _maxBuffer = 200;

  static List<ProductAnalyticsRecord> get recentEvents =>
      List<ProductAnalyticsRecord>.unmodifiable(_buffer);

  static void track(
    ProductAnalyticsEvent event, {
    Map<String, Object?> properties = const <String, Object?>{},
  }) {
    final record = ProductAnalyticsRecord(
      event: event,
      properties: properties,
      recordedAt: DateTime.now(),
    );
    _buffer.add(record);
    if (_buffer.length > _maxBuffer) {
      _buffer.removeAt(0);
    }
    if (kDebugMode) {
      debugPrint('[ProductAnalytics] ${event.name} $properties');
    }
  }

  @visibleForTesting
  static void clear() => _buffer.clear();
}

class ProductAnalyticsRecord {
  const ProductAnalyticsRecord({
    required this.event,
    required this.properties,
    required this.recordedAt,
  });

  final ProductAnalyticsEvent event;
  final Map<String, Object?> properties;
  final DateTime recordedAt;
}
