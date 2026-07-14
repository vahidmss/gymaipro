import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/theme/gym_radius.dart';
import 'package:gymaipro/design_system/theme/gym_shadows.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';

enum GymCardVariant {
  hero,
  metric,
  insight,
  action,
  warning,
  timeline,
  glass,
  compact,
}

/// Base card container with design-system variants.
class GymCard extends StatelessWidget {
  const GymCard({
    required this.child,
    this.variant = GymCardVariant.insight,
    this.padding,
    this.onTap,
    super.key,
  });

  final Widget child;
  final GymCardVariant variant;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final decoration = _decoration(context);
    final borderRadius = decoration.borderRadius ?? GymRadius.radiusXl;
    final content = Container(
      width: double.infinity,
      padding: padding ?? _defaultPadding(),
      decoration: decoration,
      child: child,
    );

    if (onTap == null) return content;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius is BorderRadius
            ? borderRadius
            : BorderRadius.circular(GymRadius.xl),
        child: content,
      ),
    );
  }

  EdgeInsetsGeometry _defaultPadding() {
    return variant == GymCardVariant.compact
        ? GymSpacing.paddingMd
        : GymSpacing.card;
  }

  BoxDecoration _decoration(BuildContext context) {
    final card = context.gymCard;
    final surface = context.gymSurface;
    final elevated = context.gymElevated;
    final primary = context.gymPrimary;
    final borderSubtle = context.gymBorderSubtle;
    final border = context.gymBorder;

    return switch (variant) {
      GymCardVariant.hero => BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: <Color>[elevated, card],
        ),
        borderRadius: GymRadius.radiusXxl,
        border: Border.all(color: primary.withValues(alpha: 0.2)),
        boxShadow: GymShadows.large,
      ),
      GymCardVariant.metric => BoxDecoration(
        color: card,
        borderRadius: GymRadius.radiusXl,
        border: Border.all(color: borderSubtle),
        boxShadow: GymShadows.small,
      ),
      GymCardVariant.insight => BoxDecoration(
        color: card,
        borderRadius: GymRadius.radiusXl,
        border: Border.all(color: borderSubtle),
      ),
      GymCardVariant.action => BoxDecoration(
        color: surface,
        borderRadius: GymRadius.radiusXl,
        border: Border.all(color: primary.withValues(alpha: 0.24)),
        boxShadow: GymShadows.medium,
      ),
      GymCardVariant.warning => BoxDecoration(
        color: context.gymWarningMuted,
        borderRadius: GymRadius.radiusXl,
        border: Border.all(color: context.gymWarning.withValues(alpha: 0.3)),
      ),
      GymCardVariant.timeline => BoxDecoration(
        color: surface,
        borderRadius: GymRadius.radiusLg,
        border: Border.all(color: border),
      ),
      GymCardVariant.glass => BoxDecoration(
        color: card.withValues(alpha: context.gymIsDark ? 0.92 : 0.96),
        borderRadius: GymRadius.radiusXxl,
        border: Border.all(
          color: context.gymTextPrimary.withValues(alpha: 0.08),
        ),
        boxShadow: GymShadows.large,
      ),
      GymCardVariant.compact => BoxDecoration(
        color: card,
        borderRadius: GymRadius.radiusMd,
        border: Border.all(color: borderSubtle),
      ),
    };
  }
}

/// Expandable card with header and collapsible body.
class GymExpandableCard extends StatefulWidget {
  const GymExpandableCard({
    required this.title,
    required this.child,
    this.subtitle,
    this.initiallyExpanded = false,
    this.variant = GymCardVariant.insight,
    super.key,
  });

  final String title;
  final String? subtitle;
  final Widget child;
  final bool initiallyExpanded;
  final GymCardVariant variant;

  @override
  State<GymExpandableCard> createState() => _GymExpandableCardState();
}

class _GymExpandableCardState extends State<GymExpandableCard> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    return GymCard(
      variant: widget.variant,
      padding: GymSpacing.paddingLg,
      onTap: () => setState(() => _expanded = !_expanded),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      widget.title,
                      style: context.gymTextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (widget.subtitle != null) ...<Widget>[
                      const SizedBox(height: GymSpacing.xs),
                      Text(
                        widget.subtitle!,
                        style: context.gymTextStyle(
                          fontSize: 12,
                          color: context.gymTextTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                color: context.gymTextTertiary,
              ),
            ],
          ),
          if (_expanded) ...<Widget>[
            const SizedBox(height: GymSpacing.lg),
            widget.child,
          ],
        ],
      ),
    );
  }
}
