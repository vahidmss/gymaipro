import 'package:flutter/material.dart';
import 'package:gymaipro/design_system/components/gym_card.dart';
import 'package:gymaipro/design_system/theme/gym_spacing.dart';
import 'package:gymaipro/design_system/theme/gym_theme_context.dart';
import 'package:gymaipro/workout_plan_builder/models/workout_program.dart';

/// Shared session-day chips for Workout Today, Live Workout, and Workout Log.
class WorkoutSessionDayPicker extends StatelessWidget {
  const WorkoutSessionDayPicker({
    required this.sessions,
    required this.selectedSessionDay,
    required this.onSessionDaySelected,
    this.locked = false,
    super.key,
  });

  final List<WorkoutSession> sessions;
  final String? selectedSessionDay;
  final ValueChanged<String> onSessionDaySelected;
  final bool locked;

  @override
  Widget build(BuildContext context) {
    final usable = sessions
        .where((session) => session.exercises.isNotEmpty)
        .toList(growable: false);
    if (usable.isEmpty) return const SizedBox.shrink();

    return GymCard(
      variant: GymCardVariant.insight,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'امروز می‌خواهی کدام روز برنامه را اجرا کنی؟',
            style: context.gymTextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: context.gymTextPrimary,
            ),
          ),
          GymSpacing.gapMd,
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: usable.length,
              separatorBuilder: (_, __) => GymSpacing.gapSm,
              itemBuilder: (context, index) {
                final session = usable[index];
                final selected = selectedSessionDay == session.day;
                return _SessionChip(
                  label: session.day,
                  selected: selected,
                  onTap: locked ? null : () => onSessionDaySelected(session.day),
                );
              },
            ),
          ),
          if (locked) ...<Widget>[
            GymSpacing.gapSm,
            Text(
              'انتخاب روز در حال حاضر غیرفعال است.',
              style: context.gymTextStyle(
                fontSize: 12,
                color: context.gymTextSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SessionChip extends StatelessWidget {
  const _SessionChip({
    required this.label,
    required this.selected,
    this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final borderColor = selected ? context.gymPrimary : context.gymBorder;
    final background = selected
        ? context.gymPrimary.withValues(alpha: 0.12)
        : context.gymSurface;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
            horizontal: GymSpacing.lg,
            vertical: GymSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: selected ? 1.5 : 1),
          ),
          child: Center(
            child: Text(
              label,
              style: context.gymTextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? context.gymPrimary : context.gymTextPrimary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
