import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/models/trainer_ranking_model.dart'
    show TrainerReview;
import 'package:lucide_icons/lucide_icons.dart';

class TrainerReviewWidget extends StatelessWidget {
  const TrainerReviewWidget({required this.review, super.key});
  final TrainerReview review;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // هدر نظر
            Row(
              children: [
                // آواتار کاربر
                Container(
                  width: 40.w,
                  height: 40.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.2),
                        AppTheme.goldColor.withValues(alpha: 0.1),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.goldColor.withValues(alpha: 0.3),
                        blurRadius: 4.r,
                        offset: Offset(0.w, 2.h),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: review.userAvatar != null
                        ? Image.network(
                            review.userAvatar!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                LucideIcons.user,
                                color: AppTheme.goldColor,
                                size: 20.sp,
                              );
                            },
                          )
                        : Icon(
                            LucideIcons.user,
                            color: AppTheme.goldColor,
                            size: 20.sp,
                          ),
                  ),
                ),
                const SizedBox(width: 12),

                // اطلاعات کاربر
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            review.userFullName ?? review.studentName,
                            style: GoogleFonts.vazirmatn(
                              color: Colors.white,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (review.isVerifiedStudent) ...[
                            SizedBox(width: 6.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.green,
                                    Colors.green.withValues(alpha: 0.8),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(8.r),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.green.withValues(alpha: 0.3),
                                    blurRadius: 3.r,
                                    offset: Offset(0.w, 1.h),
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    LucideIcons.check,
                                    color: Colors.white,
                                    size: 8.sp,
                                  ),
                                  SizedBox(width: 3.w),
                                  Text(
                                    'شاگرد',
                                    style: GoogleFonts.vazirmatn(
                                      color: Colors.white,
                                      fontSize: 8.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        _formatDate(review.createdAt),
                        style: GoogleFonts.vazirmatn(
                          color: Colors.grey[400],
                          fontSize: 12.sp,
                        ),
                      ),
                    ],
                  ),
                ),

                // امتیاز
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 4.h,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.amber,
                        Colors.amber.withValues(alpha: 0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(8.r),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.amber.withValues(alpha: 0.3),
                        blurRadius: 3.r,
                        offset: Offset(0.w, 1.h),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(LucideIcons.star, color: Colors.white, size: 12),
                      SizedBox(width: 3.w),
                      Text(
                        review.rating.toStringAsFixed(1),
                        style: GoogleFonts.vazirmatn(
                          color: Colors.white,
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // متن نظر
            if (review.comment.isNotEmpty)
              Text(
                review.comment,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 14.sp,
                  height: 1.5.h,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'امروز';
    } else if (difference.inDays == 1) {
      return 'دیروز';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} روز پیش';
    } else if (difference.inDays < 30) {
      final weeks = (difference.inDays / 7).floor();
      return '$weeks هفته پیش';
    } else if (difference.inDays < 365) {
      final months = (difference.inDays / 30).floor();
      return '$months ماه پیش';
    } else {
      final years = (difference.inDays / 365).floor();
      return '$years سال پیش';
    }
  }
}
