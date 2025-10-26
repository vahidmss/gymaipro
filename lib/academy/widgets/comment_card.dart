import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';

class CommentCard extends StatelessWidget {
  const CommentCard({
    required this.displayName,
    required this.content,
    required this.avatarUrl,
    this.onTap,
    super.key,
  });

  final String displayName;
  final String content;
  final String avatarUrl;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.white10),
        ),
        padding: EdgeInsets.all(10.w),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.goldColor,
              backgroundImage:
                  (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                  ? NetworkImage(avatarUrl)
                  : null,
              child: (avatarUrl.isEmpty)
                  ? Text(
                      (displayName.isNotEmpty ? displayName[0] : 'ک'),
                      style: const TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTheme.headingStyle.copyWith(fontSize: 14.sp),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    content.replaceAll(RegExp('<[^>]*>'), ''),
                    style: AppTheme.bodyStyle.copyWith(height: 1.5.h),
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
