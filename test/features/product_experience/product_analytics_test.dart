import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/features/product_experience/product_analytics.dart';

void main() {
  tearDown(ProductAnalytics.clear);

  test('track buffers product events', () {
    ProductAnalytics.track(ProductAnalyticsEvent.workoutStarted);
    ProductAnalytics.track(
      ProductAnalyticsEvent.workoutFinished,
      properties: const <String, Object?>{'completedSets': 12},
    );

    expect(ProductAnalytics.recentEvents, hasLength(2));
    expect(
      ProductAnalytics.recentEvents.last.event,
      ProductAnalyticsEvent.workoutFinished,
    );
    expect(
      ProductAnalytics.recentEvents.last.properties['completedSets'],
      12,
    );
  });
}
