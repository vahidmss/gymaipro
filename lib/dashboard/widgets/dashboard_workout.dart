import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/widgets/common_widgets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Today's Workout Section
class TodayWorkoutSection extends StatelessWidget {
  const TodayWorkoutSection({required this.workoutItems, super.key});
  final List<Widget> workoutItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'تمرین امروز'),
        const SizedBox(height: 16),
        if (workoutItems.isEmpty)
          Container(
            padding: EdgeInsets.all(20.w),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: const Center(
              child: Text(
                'هیچ تمرینی برای امروز برنامه‌ریزی نشده',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          )
        else
          ...workoutItems,
      ],
    );
  }
}

// Workout Item Widget
class WorkoutItem extends StatelessWidget {
  const WorkoutItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        trailing: Icon(
          LucideIcons.chevronLeft,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Workout Split Section
class WorkoutSplitSection extends StatelessWidget {
  const WorkoutSplitSection({required this.splitItems, super.key});
  final List<Widget> splitItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'برنامه تمرینی'),
        const SizedBox(height: 16),
        ...splitItems,
      ],
    );
  }
}

// Split Item Widget
class SplitItem extends StatelessWidget {
  const SplitItem({
    required this.day,
    required this.workout,
    required this.isCompleted,
    required this.onTap,
    super.key,
  });
  final String day;
  final String workout;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        leading: Container(
          width: 40.w,
          height: 40.h,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Icon(
            isCompleted ? LucideIcons.check : LucideIcons.dumbbell,
            color: isCompleted ? Colors.green : AppTheme.goldColor,
            size: 20.sp,
          ),
        ),
        title: Text(
          day,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          workout,
          style: TextStyle(color: Colors.white.withValues(alpha: 0.7)),
        ),
        trailing: Icon(
          LucideIcons.chevronLeft,
          color: Colors.white.withValues(alpha: 0.5),
        ),
        onTap: onTap,
      ),
    );
  }
}

// Quick Action Button
class QuickActionButton extends StatelessWidget {
  const QuickActionButton({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
    super.key,
  });
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100.w,
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                color: color,
                fontSize: 12.sp,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
