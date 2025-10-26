import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gymaipro/payment/models/trainer_subscription.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// کارت نمایش اشتراک مربی
class TrainerSubscriptionCard extends StatelessWidget {
  const TrainerSubscriptionCard({
    required this.subscription,
    super.key,
    this.onTap,
    this.showTrainerInfo = false,
  });
  final TrainerSubscription subscription;
  final VoidCallback? onTap;
  final bool showTrainerInfo;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      color: const Color(0xFF2A2A2A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: _getStatusColor().withValues(alpha: 0.1)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.r),
        child: Padding(
          padding: EdgeInsets.all(16.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // هدر کارت
              Row(
                children: [
                  // آیکون نوع خدمات
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: _getServiceColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Icon(
                      _getServiceIcon(),
                      color: _getServiceColor(),
                      size: 20.sp,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // اطلاعات اصلی
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.serviceTypeText,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 16.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subscription.description,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // وضعیت
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8.w,
                      vertical: 4.h,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor().withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    child: Text(
                      subscription.statusText,
                      style: GoogleFonts.vazirmatn(
                        color: _getStatusColor(),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // اطلاعات مالی
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: LucideIcons.dollarSign,
                      label: 'مبلغ',
                      value: subscription.formattedFinalAmount,
                      color: AppTheme.goldColor,
                    ),
                  ),
                  if (subscription.discountAmount > 0) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: LucideIcons.percent,
                        label: 'تخفیف',
                        value: subscription.formattedDiscountAmount,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ],
              ),
              const SizedBox(height: 12),
              // اطلاعات زمانی
              Row(
                children: [
                  Expanded(
                    child: _buildInfoItem(
                      icon: LucideIcons.calendar,
                      label: 'تاریخ خرید',
                      value: _formatDate(subscription.purchaseDate),
                      color: Colors.blue,
                    ),
                  ),
                  if (subscription.programRegistrationDate != null) ...[
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildInfoItem(
                        icon: LucideIcons.clock,
                        label: 'ثبت برنامه',
                        value: _formatDate(
                          subscription.programRegistrationDate!,
                        ),
                        color: Colors.orange,
                      ),
                    ),
                  ],
                ],
              ),
              if (subscription.expiryDate.isAfter(DateTime.now())) ...[
                const SizedBox(height: 12),
                // نوار پیشرفت زمان باقی‌مانده
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'زمان باقی‌مانده',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.grey[400],
                            fontSize: 12.sp,
                          ),
                        ),
                        Text(
                          subscription.remainingTimeText,
                          style: GoogleFonts.vazirmatn(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(
                      value: _calculateRemainingPercentage(),
                      backgroundColor: Colors.grey[800],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        subscription.isExpired ? Colors.red : Colors.green,
                      ),
                    ),
                  ],
                ),
              ],
              if (subscription.hasDelay) ...[
                const SizedBox(height: 12),
                // هشدار تاخیر
                Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.1),
                    ),
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
                          'تاخیر مربی: ${subscription.trainerDelayDays} روز',
                          style: GoogleFonts.vazirmatn(
                            color: Colors.orange,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.vazirmatn(
                  color: Colors.grey[400],
                  fontSize: 10.sp,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.vazirmatn(
                  color: Colors.white,
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Color _getStatusColor() {
    switch (subscription.status) {
      case TrainerSubscriptionStatus.pending:
        return Colors.orange;
      case TrainerSubscriptionStatus.paid:
        return Colors.blue;
      case TrainerSubscriptionStatus.active:
        return subscription.isExpired ? Colors.red : Colors.green;
      case TrainerSubscriptionStatus.expired:
        return Colors.red;
      case TrainerSubscriptionStatus.cancelled:
        return Colors.grey;
      case TrainerSubscriptionStatus.suspended:
        return Colors.purple;
    }
  }

  Color _getServiceColor() {
    switch (subscription.serviceType) {
      case TrainerServiceType.training:
        return Colors.orange;
      case TrainerServiceType.diet:
        return Colors.purple;
      case TrainerServiceType.consulting:
        return Colors.blue;
      case TrainerServiceType.package:
        return AppTheme.goldColor;
    }
  }

  IconData _getServiceIcon() {
    switch (subscription.serviceType) {
      case TrainerServiceType.training:
        return LucideIcons.dumbbell;
      case TrainerServiceType.diet:
        return LucideIcons.apple;
      case TrainerServiceType.consulting:
        return LucideIcons.headphones;
      case TrainerServiceType.package:
        return LucideIcons.crown;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date).inDays;

    if (difference == 0) {
      return 'امروز';
    } else if (difference == 1) {
      return 'دیروز';
    } else if (difference < 7) {
      return '$difference روز پیش';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  double _calculateRemainingPercentage() {
    if (subscription.isExpired) return 0;

    final totalDuration = subscription.expiryDate
        .difference(subscription.purchaseDate)
        .inDays;
    final remainingDuration = subscription.expiryDate
        .difference(DateTime.now())
        .inDays;

    if (totalDuration <= 0) return 0;
    return (remainingDuration / totalDuration).clamp(0.0, 1.0);
  }
}
