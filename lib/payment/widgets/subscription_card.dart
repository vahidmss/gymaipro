import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SubscriptionCard extends StatelessWidget {
  const SubscriptionCard({
    required this.subscription,
    super.key,
    this.onTap,
    this.onCancel,
    this.onRenew,
  });
  final Subscription subscription;
  final VoidCallback? onTap;
  final VoidCallback? onCancel;
  final VoidCallback? onRenew;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: subscription.isActive
              ? AppTheme.goldColor.withValues(alpha: 0.1)
              : Colors.white24,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // هدر اشتراک
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8.w),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.r),
                      ),
                      child: Icon(
                        _getSubscriptionIcon(),
                        color: _getStatusColor(),
                        size: 20.sp,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            subscription.typeText,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            subscription.statusText,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 12.sp,
                              color: _getStatusColor(),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 4.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getStatusColor().withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        subscription.formattedPrice,
                        style: GoogleFonts.vazirmatn(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: _getStatusColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // اطلاعات زمانی
                if (subscription.isActive) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.clock,
                          color: Colors.blue,
                          size: 16.sp,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            subscription.remainingTimeText,
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14.sp,
                              color: Colors.blue,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        // نوار پیشرفت
                        Container(
                          width: 60.w,
                          height: 4.h,
                          decoration: BoxDecoration(
                            color: Colors.blue.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(2.r),
                          ),
                          child: FractionallySizedBox(
                            alignment: Alignment.centerRight,
                            widthFactor: subscription.remainingPercentage / 100,
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(2.r),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (subscription.status ==
                    SubscriptionStatus.expired) ...[
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: Colors.orange.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          LucideIcons.alertTriangle,
                          color: Colors.orange,
                          size: 16.sp,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'اشتراک منقضی شده - برای تمدید کلیک کنید',
                            style: GoogleFonts.vazirmatn(
                              fontSize: 14.sp,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // ویژگی‌ها
                Text(
                  'ویژگی‌ها:',
                  style: GoogleFonts.vazirmatn(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 8),
                ...subscription.features
                    .take(3)
                    .map(
                      (feature) => Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Row(
                          children: [
                            Icon(
                              LucideIcons.check,
                              color: Colors.green,
                              size: 14.sp,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                feature,
                                style: GoogleFonts.vazirmatn(
                                  fontSize: 12.sp,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                if (subscription.features.length > 3) ...[
                  Text(
                    'و ${subscription.features.length - 3} ویژگی دیگر...',
                    style: GoogleFonts.vazirmatn(
                      fontSize: 11.sp,
                      color: Colors.white54,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // دکمه‌های عملیات
                Row(
                  children: [
                    if (subscription.isActive && onCancel != null) ...[
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onCancel,
                          icon: const Icon(LucideIcons.x, size: 16),
                          label: Text(
                            'لغو اشتراک',
                            style: GoogleFonts.vazirmatn(fontSize: 12),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],

                    if (subscription.status == SubscriptionStatus.expired &&
                        onRenew != null) ...[
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: onRenew,
                          icon: const Icon(LucideIcons.refreshCw, size: 16),
                          label: Text(
                            'تمدید',
                            style: GoogleFonts.vazirmatn(fontSize: 12),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.goldColor,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 8),
                          ),
                        ),
                      ),
                    ],

                    if (subscription.isActive && subscription.needsRenewal) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4.r),
                        ),
                        child: Text(
                          'نیاز به تمدید',
                          style: GoogleFonts.vazirmatn(
                            fontSize: 10.sp,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  IconData _getSubscriptionIcon() {
    switch (subscription.type) {
      case SubscriptionType.monthly:
        return LucideIcons.calendar;
      case SubscriptionType.aiPremium:
        return LucideIcons.brain;
      case SubscriptionType.trainerAccess:
        return LucideIcons.userCheck;
      case SubscriptionType.fullAccess:
        return LucideIcons.crown;
    }
  }

  Color _getStatusColor() {
    switch (subscription.status) {
      case SubscriptionStatus.active:
        return subscription.isExpired ? Colors.orange : Colors.green;
      case SubscriptionStatus.expired:
        return Colors.orange;
      case SubscriptionStatus.cancelled:
        return Colors.red;
      case SubscriptionStatus.suspended:
        return Colors.grey;
      case SubscriptionStatus.pendingPayment:
        return Colors.blue;
    }
  }
}
