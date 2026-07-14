import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_colors.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_typography.dart';

enum GymMetricTrend { up, down, neutral }

/// Metric display tile with title, value, subtitle, icon, and trend.
class GymMetricTile extends StatelessWidget {
  const GymMetricTile({
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.trend,
    this.trendLabel,
    this.compact = false,
    super.key,
  });

  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final GymMetricTrend? trend;
  final String? trendLabel;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: compact ? GymCardVariant.compact : GymCardVariant.metric,
      child: Row(
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Container(
              width: compact ? 36 : 44,
              height: compact ? 36 : 44,
              decoration: BoxDecoration(
                color: GymColors.primary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(compact ? 10 : 14),
              ),
              child: Icon(icon, color: GymColors.primary, size: compact ? 18 : 22),
            ),
            SizedBox(width: compact ? GymSpacing.md : GymSpacing.lg),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(title, style: GymTypography.caption),
                const SizedBox(height: GymSpacing.xs),
                Text(
                  value,
                  style: compact
                      ? GymTypography.title
                      : GymTypography.metric,
                ),
                if (subtitle != null) ...<Widget>[
                  const SizedBox(height: GymSpacing.xs),
                  Text(subtitle!, style: GymTypography.body),
                ],
              ],
            ),
          ),
          if (trend != null)
            _TrendBadge(trend: trend!, label: trendLabel),
        ],
      ),
    );
  }
}

class _TrendBadge extends StatelessWidget {
  const _TrendBadge({required this.trend, this.label});

  final GymMetricTrend trend;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final color = switch (trend) {
      GymMetricTrend.up => GymColors.success,
      GymMetricTrend.down => GymColors.danger,
      GymMetricTrend.neutral => GymColors.textTertiary,
    };
    final icon = switch (trend) {
      GymMetricTrend.up => Icons.trending_up,
      GymMetricTrend.down => Icons.trending_down,
      GymMetricTrend.neutral => Icons.trending_flat,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Icon(icon, color: color, size: 18),
        if (label != null) ...<Widget>[
          const SizedBox(height: GymSpacing.xs),
          Text(
            label!,
            style: GymTypography.overline.copyWith(color: color),
          ),
        ],
      ],
    );
  }
}
