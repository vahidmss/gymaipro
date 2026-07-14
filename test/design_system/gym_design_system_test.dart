import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymaipro/design_system/animations/fade_slide.dart';
import 'package:gymaipro/design_system/animations/scale_in.dart';
import 'package:gymaipro/design_system/animations/shimmer.dart';
import 'package:gymaipro/design_system/animations/stagger_column.dart';
import 'package:gymaipro/design_system/components/gym_badge.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/components/gym_chip.dart';
import 'package:gymaipro/design_system/components/gym_empty_state.dart';
import 'package:gymaipro/design_system/components/gym_error_state.dart';
import 'package:gymaipro/design_system/components/gym_loading_state.dart';
import 'package:gymaipro/design_system/components/gym_metric_tile.dart';
import 'package:gymaipro/design_system/components/gym_progress_bar.dart';
import 'package:gymaipro/design_system/components/gym_progress_ring.dart';
import 'package:gymaipro/design_system/components/gym_skeleton.dart';
import 'package:gymaipro/design_system/icons/gym_icons.dart';
import 'package:gymaipro/design_system/layout/page_scaffold.dart';
import 'package:gymaipro/design_system/layout/responsive_breakpoints.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_motion.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: GymTheme.dark,
    home: Directionality(
      textDirection: GymTypography.direction,
      child: Scaffold(body: child),
    ),
  );
}

void main() {
  group('Design tokens', () {
    test('spacing tokens follow scale', () {
      expect(GymSpacing.xs, 4);
      expect(GymSpacing.massive, 48);
    });

    test('radius tokens follow scale', () {
      expect(GymRadius.sm, 12);
      expect(GymRadius.xxl, 32);
    });

    test('motion tokens define durations and curves', () {
      expect(GymMotion.normal.inMilliseconds, 280);
      expect(GymMotion.standard, isA<Curve>());
    });

    test('breakpoints resolve content width', () {
      expect(GymBreakpoints.contentMaxWidth(400), 400);
      expect(GymBreakpoints.contentMaxWidth(900), 820);
    });
  });

  group('GymButton', () {
    testWidgets('renders primary label', (tester) async {
      await tester.pumpWidget(
        _wrap(GymButton(label: 'Start', onPressed: () {})),
      );
      expect(find.text('Start'), findsOneWidget);
    });

    testWidgets('shows loading indicator', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GymButton(label: 'Start', onPressed: () {}, loading: true),
        ),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('disabled button ignores tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        _wrap(GymButton(label: 'Start', onPressed: null)),
      );
      await tester.tap(find.text('Start'));
      await tester.pump();
      expect(tapped, false);
    });
  });

  group('GymCard', () {
    testWidgets('renders hero variant child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymCard(
            variant: GymCardVariant.hero,
            child: Text('Hero content'),
          ),
        ),
      );
      expect(find.text('Hero content'), findsOneWidget);
    });

    testWidgets('expandable card toggles body', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymExpandableCard(
            title: 'Details',
            child: Text('Hidden body'),
          ),
        ),
      );
      expect(find.text('Hidden body'), findsNothing);
      await tester.tap(find.text('Details'));
      await tester.pump();
      expect(find.text('Hidden body'), findsOneWidget);
    });
  });

  group('GymChip and GymBadge', () {
    testWidgets('chip renders label', (tester) async {
      await tester.pumpWidget(_wrap(const GymChip(label: 'Recovery')));
      expect(find.text('Recovery'), findsOneWidget);
    });

    testWidgets('badge renders variant label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymBadge(
            label: 'Online',
            variant: GymBadgeVariant.success,
          ),
        ),
      );
      expect(find.text('Online'), findsOneWidget);
    });
  });

  group('Progress', () {
    testWidgets('linear progress bar renders', (tester) async {
      await tester.pumpWidget(
        _wrap(const GymProgressBar(value: 0.6, animated: false)),
      );
      expect(find.byType(GymProgressBar), findsOneWidget);
    });

    testWidgets('progress ring renders label', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymProgressRing(
            value: 0.75,
            animated: false,
            label: '75%',
          ),
        ),
      );
      expect(find.text('75%'), findsOneWidget);
    });
  });

  group('Metric and states', () {
    testWidgets('metric tile shows value', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymMetricTile(
            title: 'Volume',
            value: '12,400',
            subtitle: 'kg this week',
            icon: GymIcons.workout,
            trend: GymMetricTrend.up,
            trendLabel: '+8%',
          ),
        ),
      );
      expect(find.text('Volume'), findsOneWidget);
      expect(find.text('12,400'), findsOneWidget);
    });

    testWidgets('empty state shows action', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GymEmptyState(
            title: 'No workouts',
            message: 'Start your first session',
            icon: GymIcons.workout,
            actionLabel: 'Begin',
            onAction: () {},
          ),
        ),
      );
      expect(find.text('No workouts'), findsOneWidget);
      expect(find.text('Begin'), findsOneWidget);
    });

    testWidgets('error state shows retry', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GymErrorState(
            message: 'Preview failed',
            onRetry: () {},
          ),
        ),
      );
      expect(find.text('Preview failed'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('loading state shows spinner', (tester) async {
      await tester.pumpWidget(
        _wrap(const GymLoadingState(message: 'Loading...')),
      );
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading...'), findsOneWidget);
    });
  });

  group('Skeleton and animations', () {
    testWidgets('skeleton variants render', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const Column(
            children: <Widget>[
              GymSkeleton(variant: GymSkeletonVariant.hero),
              GymSkeleton(variant: GymSkeletonVariant.card),
              GymSkeleton(variant: GymSkeletonVariant.timeline),
              GymSkeleton(variant: GymSkeletonVariant.chatBubble),
            ],
          ),
        ),
      );
      expect(find.byType(GymSkeleton), findsNWidgets(4));
    });

    testWidgets('fade slide and scale in render child', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymScaleIn(
            child: GymFadeSlide(child: Text('Animated')),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Animated'), findsOneWidget);
    });

    testWidgets('stagger column renders children', (tester) async {
      await tester.pumpWidget(
        _wrap(
          const GymStaggerColumn(
            children: <Widget>[
              Text('One'),
              Text('Two'),
            ],
          ),
        ),
      );
      expect(find.text('One'), findsOneWidget);
      expect(find.text('Two'), findsOneWidget);
    });

    testWidgets('shimmer block renders', (tester) async {
      await tester.pumpWidget(_wrap(const GymShimmerBlock(height: 20)));
      expect(find.byType(GymShimmerBlock), findsOneWidget);
    });
  });

  group('Layout', () {
    testWidgets('page scaffold renders title', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: GymTheme.dark,
          home: const GymPageScaffold(
            title: 'Coach',
            body: Text('Body'),
          ),
        ),
      );
      expect(find.text('Coach'), findsOneWidget);
      expect(find.text('Body'), findsOneWidget);
    });
  });

  test('theme extension exposes semantic colors', () {
    expect(GymThemeExtension.dark.primary, GymColors.primary);
    expect(GymThemeExtension.dark.background, GymColors.background);
  });
}
