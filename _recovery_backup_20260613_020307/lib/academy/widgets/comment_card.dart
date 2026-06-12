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
      borderRadius: BorderRadius.circular(10.r),
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: context.backgroundColor,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.1)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 20.r,
                backgroundColor: AppTheme.goldColor.withValues(alpha: 0.2),
                backgroundImage:
                    (avatarUrl.isNotEmpty && avatarUrl.startsWith('http'))
                    ? NetworkImage(avatarUrl)
                    : null,
                child: (avatarUrl.isEmpty)
                    ? Text(
                        (displayName.isNotEmpty ? displayName[0] : 'ک'),
                        style: TextStyle(
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 16.sp,
                        ),
                      )
                    : null,
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: AppTheme.headingStyle.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    content.replaceAll(RegExp('<[^>]*>'), ''),
                    style: AppTheme.bodyStyle.copyWith(
                      fontSize: 13.sp,
                      height: 1.6,
                      color: context.textColor,
                    ),
                    maxLines: 10,
                    overflow: TextOverflow.ellipsis,
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
