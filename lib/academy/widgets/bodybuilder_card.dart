import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/academy/models/professional_bodybuilder.dart';
import 'package:gymaipro/academy/screens/bodybuilder_detail_screen.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/widgets/gymai_network_image.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class BodybuilderCard extends StatelessWidget {
  const BodybuilderCard({required this.bodybuilder, super.key});

  final ProfessionalBodybuilder bodybuilder;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push<BodybuilderDetailScreen>(
              context,
              MaterialPageRoute<BodybuilderDetailScreen>(
                builder: (_) =>
                    BodybuilderDetailScreen(bodybuilder: bodybuilder),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16.r),
          child: Ink(
            decoration: BoxDecoration(
              color: context.cardColor,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(color: context.separatorColor),
            ),
            child: Row(
              children: [
                // Profile Image
                ClipRRect(
                  borderRadius: BorderRadius.horizontal(
                    right: Radius.circular(16.r),
                  ),
                  child: SizedBox(
                    width: 110.w,
                    height: 110.w,
                    child: GymaiNetworkImage(
                      imageUrl: bodybuilder.profileImageUrl,
                      errorWidget: ColoredBox(
                        color: context.surfaceElevated,
                        child: Icon(
                          LucideIcons.user,
                          color: context.textSecondary,
                          size: 40.sp,
                        ),
                      ),
                    ),
                  ),
                ),

            // Info
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(12.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bodybuilder.name,
                      style: context.headingStyle.copyWith(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 6.h),
                    Row(
                      children: [
                        Icon(
                          LucideIcons.mapPin,
                          size: 14.sp,
                          color: AppTheme.goldColor,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          bodybuilder.nationality,
                          style: context.bodyStyle.copyWith(
                            fontSize: 12.sp,
                            color: context.textColor,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Icon(
                          LucideIcons.cake,
                          size: 14.sp,
                          color: context.textSecondary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          '${bodybuilder.age} سال',
                          style: context.bodyStyle.copyWith(
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                    if (bodybuilder.height != null || bodybuilder.weight != null) ...[
                      SizedBox(height: 6.h),
                      Row(
                        children: [
                          if (bodybuilder.height != null) ...[
                            Icon(
                              LucideIcons.ruler,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${bodybuilder.height!.toStringAsFixed(0)} سانتی‌متر',
                              style: context.bodyStyle.copyWith(
                                fontSize: 11.sp,
                              ),
                            ),
                            SizedBox(width: 12.w),
                          ],
                          if (bodybuilder.weight != null) ...[
                            Icon(
                              LucideIcons.scale,
                              size: 14.sp,
                              color: context.textSecondary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${bodybuilder.weight!.toStringAsFixed(0)} کیلوگرم',
                              style: context.bodyStyle.copyWith(
                                fontSize: 11.sp,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.goldColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Text(
                        _getCategoryLabel(bodybuilder.category),
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 10.sp,
                          color: AppTheme.goldColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Arrow
            Padding(
              padding: EdgeInsets.only(left: 8.w),
              child: Icon(
                LucideIcons.chevronLeft,
                color: context.textSecondary.withValues(alpha: 0.7),
                size: 18.sp,
              ),
            ),
          ],
        ),
          ),
        ),
      ),
    );
  }

  String _getCategoryLabel(String category) {
    switch (category) {
      case 'classic':
        return 'کلاسیک';
      case 'bodybuilding':
        return 'بدنسازی';
      case 'physique':
        return 'فیزیک';
      case 'wellness':
        return 'ولنس';
      default:
        return category;
    }
  }
}


