import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_exercises_tab.dart';
import 'package:gymaipro/trainer_dashboard/screens/custom_musics_tab.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Combined content hub: custom exercises + custom music.
class TrainerContentTab extends StatefulWidget {
  const TrainerContentTab({super.key});

  @override
  State<TrainerContentTab> createState() => _TrainerContentTabState();
}

class _TrainerContentTabState extends State<TrainerContentTab> {
  int _segment = 0; // 0 = exercises, 1 = music

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isDark
                  ? context.veryDarkBackground
                  : AppTheme.lightSurfaceColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Expanded(
                    child: _SegmentChip(
                      label: 'تمرین‌ها',
                      icon: LucideIcons.dumbbell,
                      selected: _segment == 0,
                      onTap: () => setState(() => _segment = 0),
                    ),
                  ),
                  Expanded(
                    child: _SegmentChip(
                      label: 'موزیک',
                      icon: LucideIcons.music,
                      selected: _segment == 1,
                      onTap: () => setState(() => _segment = 1),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: IndexedStack(
            index: _segment,
            children: const [CustomExercisesTab(), CustomMusicsTab()],
          ),
        ),
      ],
    );
  }
}

class _SegmentChip extends StatelessWidget {
  const _SegmentChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: BoxConstraints(minHeight: 44.h),
          padding: EdgeInsets.symmetric(vertical: 10.h),
          decoration: BoxDecoration(
            color: selected
                ? AppTheme.goldColor.withValues(alpha: isDark ? 0.22 : 0.18)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: selected ? AppTheme.goldColor : context.textSecondary,
              ),
              SizedBox(width: 6.w),
              Text(
                label,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 13.sp,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? context.textColor : context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
