import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:gymaipro/theme/app_theme.dart';

// Section Title Widget
class SectionTitle extends StatelessWidget {
  final String title;

  const SectionTitle({
    Key? key,
    required this.title,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

// Today's Workout Section
class TodayWorkoutSection extends StatelessWidget {
  final List<Widget> workoutItems;

  const TodayWorkoutSection({
    Key? key,
    required this.workoutItems,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'تمرین امروز'),
        const SizedBox(height: 16),
        if (workoutItems.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.cardColor,
              borderRadius: BorderRadius.circular(16),
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
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  const WorkoutItem({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 20),
        ),
        title: Text(
          title,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
  final List<Widget> splitItems;

  const WorkoutSplitSection({
    Key? key,
    required this.splitItems,
  }) : super(key: key);

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
  final String day;
  final String workout;
  final bool isCompleted;
  final VoidCallback onTap;

  const SplitItem({
    Key? key,
    required this.day,
    required this.workout,
    required this.isCompleted,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.2)
                : AppTheme.goldColor.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(
            isCompleted ? LucideIcons.check : LucideIcons.dumbbell,
            color: isCompleted ? Colors.green : AppTheme.goldColor,
            size: 20,
          ),
        ),
        title: Text(
          day,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

// Quick Actions Section
class QuickActionsSection extends StatelessWidget {
  final List<Widget> actionButtons;

  const QuickActionsSection({
    Key? key,
    required this.actionButtons,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'دسترسی سریع'),
        const SizedBox(height: 16),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: actionButtons,
        ),
      ],
    );
  }
}

// Quick Action Button
class QuickActionButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const QuickActionButton({
    Key? key,
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
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
                fontSize: 12,
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
