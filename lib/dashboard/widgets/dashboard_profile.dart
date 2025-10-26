import 'package:flutter/material.dart';
// Flutter imports
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/dashboard/widgets/common_widgets.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

// Profile Header Widget
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.username,
    required this.phoneNumber,
    required this.onEditProfile,
    super.key,
  });
  final String username;
  final String phoneNumber;
  final VoidCallback onEditProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(20.w),
        child: Row(
          children: [
            Container(
              width: 60.w,
              height: 60.h,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.goldColor, AppTheme.darkGold],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Icon(LucideIcons.user, color: Colors.white, size: 30.sp),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    username,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    phoneNumber,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 14.sp,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onEditProfile,
              icon: Icon(
                LucideIcons.edit,
                color: AppTheme.goldColor,
                size: 20.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Stats Widget
class ProfileStats extends StatelessWidget {
  const ProfileStats({required this.statItems, super.key});
  final List<Widget> statItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'آمار پروفایل'),
        const SizedBox(height: 16),
        ...statItems,
      ],
    );
  }
}

// Profile Stat Item Widget
class ProfileStatItem extends StatelessWidget {
  const ProfileStatItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    super.key,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12.sp,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Profile Actions Widget
class ProfileActions extends StatelessWidget {
  const ProfileActions({required this.actionItems, super.key});
  final List<Widget> actionItems;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'تنظیمات'),
        const SizedBox(height: 16),
        ...actionItems,
      ],
    );
  }
}

// Profile Action Item Widget
class ProfileActionItem extends StatelessWidget {
  const ProfileActionItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
    super.key,
    this.color,
  });
  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppTheme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: (color ?? AppTheme.goldColor).withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(8.r),
          ),
          child: Icon(icon, color: color ?? AppTheme.goldColor, size: 20),
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
