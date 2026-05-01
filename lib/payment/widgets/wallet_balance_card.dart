import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/payment/models/wallet.dart';
import 'package:gymaipro/payment/utils/payment_constants.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class WalletBalanceCard extends StatelessWidget {
  const WalletBalanceCard({
    required this.wallet,
    super.key,
    this.onCharge,
    this.onViewHistory,
  });
  final Wallet wallet;
  final VoidCallback? onCharge;
  final VoidCallback? onViewHistory;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(24.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: isDark
              ? [
                  AppTheme.goldColor.withValues(alpha: 0.15),
                  AppTheme.darkCardColor,
                ]
              : [
                  AppTheme.lightGradientStart,
                  AppTheme.lightCardColor,
                ],
        ),
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: AppTheme.goldColor.withValues(alpha: 0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : AppTheme.goldColor.withValues(alpha: 0.1),
            blurRadius: 16.r,
            offset: Offset(0.w, 6.h),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // هدر کیف پول
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(12.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Icon(
                  LucideIcons.wallet,
                  color: AppTheme.goldColor,
                  size: 26.sp,
                ),
              ),
              SizedBox(width: 14.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'کیف پول',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.goldColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        Container(
                          width: 6.w,
                          height: 6.w,
                          decoration: BoxDecoration(
                            color: wallet.isActive && wallet.isVerified
                                ? AppTheme.successColor
                                : Colors.orange,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          wallet.statusText,
                          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                            fontSize: 13.sp,
                            color: context.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (wallet.needsCharge)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8.r),
                    border: Border.all(
                      color: Colors.orange.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        LucideIcons.alertCircle,
                        size: 14.sp,
                        color: Colors.orange,
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'نیاز به شارژ',
                        style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                          fontSize: 11.sp,
                          color: Colors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 28.h),

          // موجودی اصلی
          Center(
            child: Column(
              children: [
                Text(
                  'موجودی قابل برداشت',
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    color: context.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  PaymentConstants.formatAmount(wallet.availableBalance),
                  style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                    fontSize: 38.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.goldColor,
                    letterSpacing: -1,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 28.h),

          // آمار کیف پول
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? context.textColor.withValues(alpha: 0.05)
                  : Colors.white.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    context,
                    'کل شارژ',
                    PaymentConstants.formatAmount(wallet.totalCharged),
                    LucideIcons.trendingUp,
                    AppTheme.successColor,
                    isDark,
                  ),
                ),
                Container(
                  width: 1.w,
                  height: 50.h,
                  color: isDark
                      ? context.textColor.withValues(alpha: 0.1)
                      : AppTheme.lightDividerColor,
                ),
                SizedBox(width: 16.w),
                Expanded(
                  child: _buildStatItem(
                    context,
                    'کل خرج',
                    PaymentConstants.formatAmount(wallet.totalSpent),
                    LucideIcons.trendingDown,
                    Colors.red,
                    isDark,
                  ),
                ),
              ],
            ),
          ),

          if (wallet.blockedBalance > 0) ...[
            SizedBox(height: 16.h),
            Container(
              padding: EdgeInsets.all(14.w),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: Colors.orange.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.lock,
                    color: Colors.orange,
                    size: 18.sp,
                  ),
                  SizedBox(width: 10.w),
                  Expanded(
                    child: Text(
                      'موجودی مسدود: ${PaymentConstants.formatAmount(wallet.blockedBalance)}',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 13.sp,
                        color: Colors.orange,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 24.h),

          // دکمه‌های عملیات
          Row(
            children: [
              if (onCharge != null) ...[
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onCharge,
                    icon: Icon(LucideIcons.plus, size: 18.sp),
                    label: Text(
                      'شارژ کیف پول',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: AppTheme.onGoldColor,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      elevation: 4,
                      shadowColor: AppTheme.goldColor.withValues(alpha: 0.3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],

              if (onCharge != null && onViewHistory != null)
                SizedBox(width: 12.w),

              if (onViewHistory != null) ...[
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onViewHistory,
                    icon: Icon(LucideIcons.history, size: 18.sp),
                    label: Text(
                      'تاریخچه',
                      style: TextStyle(
    fontFamily: AppTheme.fontFamily,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: BorderSide(
                        color: AppTheme.goldColor,
                        width: 2,
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Icon(
            icon,
            color: color,
            size: 20.sp,
          ),
        ),
        SizedBox(height: 8.h),
        Text(
          label,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 12.sp,
            color: context.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          value,
          style: TextStyle(
    fontFamily: AppTheme.fontFamily,
            fontSize: 14.sp,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
