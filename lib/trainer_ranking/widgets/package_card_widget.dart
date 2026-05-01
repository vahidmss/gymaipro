import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PackageCardWidget extends StatelessWidget {
  const PackageCardWidget({
    required this.cost,
    required this.packageRaw,
    required this.discountPct,
    this.isSelected = false,
    this.isProcessing = false,
    this.onTap,
    super.key,
  });

  final double cost;
  final num packageRaw;
  final num discountPct;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.goldColor.withValues(alpha: 0.2),
                    AppTheme.goldColor.withValues(alpha: 0.1),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor
                      : AppTheme.goldColor.withValues(alpha: 0.5),
                  width: isSelected ? 2.5 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.2),
                    blurRadius: 12.r,
                    offset: Offset(0.w, 4.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  const SizedBox(height: 16),
                  _buildDescription(context),
                  const SizedBox(height: 16),
                  if (packageRaw > 0 && discountPct > 0) _buildDiscountBadge(),
                  const SizedBox(height: 16),
                  _buildPurchaseButton(context),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(6.w),
          decoration: BoxDecoration(
            color: AppTheme.goldColor,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(
            LucideIcons.crown,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بسته کامل',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: AppTheme.goldColor,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'همه خدمات با تخفیف ویژه',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        _buildPriceSection(context),
      ],
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'تومان ',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: context.textSecondary,
                fontSize: 11.sp,
              ),
            ),
            Text(
              FormatUtils.formatAmount(cost),
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Text(
          'ماهانه',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textSecondary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'شامل: برنامه تمرینی + برنامه رژیم غذایی + مشاوره و نظارت',
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: context.textColor,
        fontSize: 13.sp,
        height: 1.6,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.justify,
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: Colors.green,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'تخفیف ${FormatUtils.toPersianDigits(discountPct.toStringAsFixed(0))}٪',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppTheme.goldColor
              : AppTheme.goldColor.withValues(alpha: 0.3),
          foregroundColor: isSelected ? Colors.black : Colors.white,
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: AppTheme.goldColor,
              width: isSelected ? 2 : 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.crown, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'خرید بسته کامل',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 15.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
