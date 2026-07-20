import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_button.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/features/coach/presentation/state/coach_home_state.dart';
import 'package:gymaipro/features/product_experience/product_copy.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CoachMessageCard extends StatelessWidget {
  const CoachMessageCard({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: GymSpacing.card,
      decoration: BoxDecoration(
        color: context.gymCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.gymPrimary.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: context.gymPrimary.withValues(alpha: 0.14),
            ),
            child: Icon(
              LucideIcons.messageCircle,
              size: 18,
              color: context.gymPrimary,
            ),
          ),
          GymSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'پیام مربی',
                  style: context.gymTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: context.gymTextSecondary,
                  ),
                ),
                GymSpacing.gapSm,
                Text(
                  message,
                  style: context.gymTextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.55,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachPrimaryStartButton extends StatelessWidget {
  const CoachPrimaryStartButton({
    required this.onPressed,
    this.label = ProductCopy.goToTodayWorkout,
    this.icon = LucideIcons.calendarDays,
    super.key,
  });

  final VoidCallback onPressed;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return GymButton(
      label: label,
      icon: icon,
      fullWidth: true,
      onPressed: onPressed,
    );
  }
}

/// Compact readiness / recovery / fatigue monitor.
class CoachStatusMonitor extends StatelessWidget {
  const CoachStatusMonitor({required this.recovery, super.key});

  final CoachRecoverySnapshot recovery;

  @override
  Widget build(BuildContext context) {
    if (recovery.readiness <= 0 &&
        recovery.recovery <= 0 &&
        recovery.fatigue <= 0 &&
        recovery.sleep <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(GymSpacing.lg),
        decoration: BoxDecoration(
          color: context.gymCard,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: context.gymBorderSubtle),
        ),
        child: Text(
          'هنوز داده ریکاوری ثبت نشده. بعد از اولین جلسه تمرین، آمادگی و خستگی اینجا دیده می‌شود.',
          style: context.gymTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            height: 1.45,
            color: context.gymTextSecondary,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(GymSpacing.lg),
      decoration: BoxDecoration(
        color: context.gymCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.gymBorderSubtle),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(
                LucideIcons.activity,
                size: 16,
                color: context.gymPrimary,
              ),
              GymSpacing.gapSm,
              Text(
                ProductCopy.coachMonitorTitle,
                style: context.gymTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          if (recovery.readiness > 0) ...<Widget>[
            GymSpacing.gapLg,
            _ReadinessBanner(readiness: recovery.readiness),
          ],
          GymSpacing.gapLg,
          _MetricBar(
            label: 'ریکاوری',
            value: recovery.recovery,
            color: const Color(0xFF4CAF50),
          ),
          GymSpacing.gapMd,
          _MetricBar(
            label: 'خستگی',
            value: recovery.fatigue,
            color: const Color(0xFFFF9800),
          ),
          GymSpacing.gapMd,
          _MetricBar(
            label: 'خواب',
            value: recovery.sleep,
            color: const Color(0xFF42A5F5),
          ),
        ],
      ),
    );
  }
}

class _ReadinessBanner extends StatelessWidget {
  const _ReadinessBanner({required this.readiness});

  final int readiness;

  @override
  Widget build(BuildContext context) {
    final progress = (readiness.clamp(0, 100)) / 100;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: GymSpacing.md,
        vertical: GymSpacing.md,
      ),
      decoration: BoxDecoration(
        color: context.gymPrimary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: context.gymPrimary.withValues(alpha: 0.28),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Text(
                'آمادگی',
                style: context.gymTextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: context.gymTextSecondary,
                ),
              ),
              const Spacer(),
              Text(
                '$readiness٪',
                style: context.gymTextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: context.gymTextPrimary,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: context.gymBorderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(context.gymPrimary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricBar extends StatelessWidget {
  const _MetricBar({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final progress = (value.clamp(0, 100)) / 100;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              label,
              style: context.gymTextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: context.gymTextSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value > 0 ? '$value٪' : '—',
              style: context.gymTextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: context.gymTextPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: LinearProgressIndicator(
            value: value > 0 ? progress : 0,
            minHeight: 8,
            backgroundColor: color.withValues(alpha: 0.18),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class CoachTipCard extends StatelessWidget {
  const CoachTipCard({
    required this.title,
    required this.body,
    this.icon = LucideIcons.lightbulb,
    super.key,
  });

  final String title;
  final String body;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: GymSpacing.card,
      decoration: BoxDecoration(
        color: context.gymCard,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: context.gymBorderSubtle,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: context.gymPrimary),
          GymSpacing.gapMd,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  style: context.gymTextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: context.gymTextPrimary,
                  ),
                ),
                GymSpacing.gapSm,
                Text(
                  body,
                  style: context.gymTextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    color: context.gymTextPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoachGuideChip {
  const CoachGuideChip({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class CoachGuideChips extends StatelessWidget {
  const CoachGuideChips({required this.chips, super.key});

  final List<CoachGuideChip> chips;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ProductCopy.coachGuideTitle,
          style: context.gymTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: context.gymTextSecondary,
          ),
        ),
        GymSpacing.gapMd,
        Wrap(
          spacing: GymSpacing.sm,
          runSpacing: GymSpacing.sm,
          children: chips.map((chip) {
            return Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: chip.onTap,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: context.gymCard,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: context.gymPrimary.withValues(alpha: 0.28),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Icon(chip.icon, size: 14, color: context.gymPrimary),
                      const SizedBox(width: 6),
                      Text(
                        chip.label,
                        style: context.gymTextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class CoachQuickTool {
  const CoachQuickTool({
    required this.id,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String id;
  final String label;
  final IconData icon;
  final VoidCallback onTap;
}

class CoachQuickToolsRow extends StatelessWidget {
  const CoachQuickToolsRow({required this.tools, super.key});

  final List<CoachQuickTool> tools;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          ProductCopy.quickTools,
          style: context.gymTextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: context.gymTextSecondary,
          ),
        ),
        GymSpacing.gapMd,
        Row(
          children: <Widget>[
            for (var i = 0; i < tools.length; i++) ...<Widget>[
              if (i > 0) GymSpacing.gapMd,
              Expanded(child: _QuickToolTile(tool: tools[i])),
            ],
          ],
        ),
      ],
    );
  }
}

class _QuickToolTile extends StatelessWidget {
  const _QuickToolTile({required this.tool});

  final CoachQuickTool tool;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: tool.onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 88,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF16161A) : context.gymCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: context.gymBorderSubtle),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(tool.icon, size: 22, color: context.gymPrimary),
              const SizedBox(height: GymSpacing.sm),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  tool.label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.gymTextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
