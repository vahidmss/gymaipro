import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/chat/widgets/user_avatar_widget.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/user_role_badge.dart';
import 'package:lucide_icons/lucide_icons.dart';

class TrainerCardWidget extends StatelessWidget {
  const TrainerCardWidget({
    required this.trainer,
    required this.onChatPressed,
    required this.onInfoPressed,
    super.key,
  });

  final Map<String, dynamic> trainer;
  final VoidCallback onChatPressed;
  final VoidCallback onInfoPressed;

  @override
  Widget build(BuildContext context) {
    final name = trainer['name'] as String? ?? 'نامشخص';
    final specialization = trainer['specialization'] as String? ?? '';
    final avatar = trainer['avatar'] as String?;
    final role = trainer['role'] as String? ?? 'trainer';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: AppTheme.textColor.withValues(alpha: 0.1)),
      ),
      child: ListTile(
        contentPadding: EdgeInsets.all(12.w),
        leading: UserAvatarWidget(
          avatarUrl: avatar,
          size: 48,
          role: role,
          showOnlineStatus: false,
        ),
        title: Text(
          name,
          style: TextStyle(
            color: AppTheme.textColor,
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (specialization.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                specialization,
                style: TextStyle(
                  color: AppTheme.bodyStyle.color,
                  fontSize: 12.sp,
                ),
              ),
            ],
            const SizedBox(height: 8),
            UserRoleBadge(role: role),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: Icon(
                LucideIcons.info,
                color: AppTheme.primaryColor,
                size: 20.sp,
              ),
              onPressed: onInfoPressed,
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: onChatPressed,
              icon: Icon(
                LucideIcons.messageCircle,
                color: AppTheme.textColor,
                size: 16.sp,
              ),
              label: const Text('چت'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.goldColor,
                foregroundColor: AppTheme.textColor,
                padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
