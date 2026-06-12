import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/trainer_ranking/utils/format_utils.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class PackageCardWidget extends StatelessWidget {
  const PackageCardWidget({
    required this.cost,
    required this.packageRaw,
    required this.discountPct,
    this.disabled = false,
    this.isSelected = false,
    this.isProcessing = false,
    this.onTap,
    super.key,
  });

  final double cost;
  final num packageRaw;
  final num discountPct;
  final bool disabled;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback? onTap;

  bool get _locked => disabled || onTap == null;

  @override
  Widget build(BuildContext context) {
    final muted = context.textSecondary;

    return Opacity(
      opacity: _locked ? 0.5 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _locked ? null : onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.all(18.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: _locked
                      ? [
                          muted.withValues(alpha: 0.08),
                          muted.withValues(alpha: 0.04),
                        ]
                      : [
                          AppTheme.goldColor.withValues(alpha: 0.22),
                          AppTheme.goldColor.withValues(alpha: 0.08),
                        ],
                  begin: Alignment.topRight,
                  end: Alignment.bottomLeft,
                ),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: _locked
                      ? muted.withValues(alpha: 0.3)
                      : (isSelected
                          ? AppTheme.goldColor
                          : AppTheme.goldColor.withValues(alpha: 0.55)),
                  width: isSelected ? 2.5 : 2,
                ),
                boxShadow: [
                  if (!_locked)
                    BoxShadow(
                      color: AppTheme.goldColor.withValues(alpha: 0.18),
                      blurRadius: 14.r,
                      offset: Offset(0, 5.h),
                    ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 12.h),
                  _buildDescription(context),
                  SizedBox(height: 12.h),
                  if (!_locked && packageRaw > 0 && discountPct > 0) ...[
                    _buildDiscountBadge(),
                    SizedBox(height: 12.h),
                  ],
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
    final muted = context.textSecondary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: _locked
                ? muted.withValues(alpha: 0.15)
                : AppTheme.goldColor,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(
            LucideIcons.crown,
            color: _locked ? muted : AppTheme.darkTextColor,
            size: 22.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'بسته کامل',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: _locked ? muted : AppTheme.goldColor,
                  fontSize: 17.sp,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 3.h),
              Text(
                'تمرین + رژیم + مشاوره با یک تخفیف',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 12.sp,
                  height: 1.35,
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
    final muted = context.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: _locked
            ? muted.withValues(alpha: 0.08)
            : AppTheme.goldColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: _locked
              ? muted.withValues(alpha: 0.2)
              : AppTheme.goldColor.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تومان',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: muted,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(width: 4.w),
                Text(
                  FormatUtils.formatAmount(cost),
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: _locked ? muted : AppTheme.goldColor,
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'ماهانه',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: muted,
                fontSize: 10.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDescription(BuildContext context) {
    return Text(
      'شامل: برنامه تمرینی، برنامه رژیم غذایی، مشاوره و نظارت — در صورت فعال بودن هر بخش توسط مربی.',
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        color: context.textColor,
        fontSize: 12.5.sp,
        height: 1.55,
        fontWeight: FontWeight.w500,
      ),
      textAlign: TextAlign.start,
    );
  }

  Widget _buildDiscountBadge() {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12.w,
        vertical: 6.h,
      ),
      decoration: BoxDecoration(
        color: AppTheme.successColor,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        'تخفیف ${FormatUtils.toPersianDigits(discountPct.toStringAsFixed(0))}٪',
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppTheme.darkTextColor,
          fontSize: 12.sp,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildPurchaseButton(BuildContext context) {
    final muted = context.textSecondary;
    return SizedBox(
      width: double.infinity,
      height: 46.h,
      child: FilledButton(
        onPressed: _locked ? null : onTap,
        style: FilledButton.styleFrom(
          backgroundColor: _locked
              ? muted.withValues(alpha: 0.18)
              : (isSelected
                  ? AppTheme.goldColor
                  : AppTheme.goldColor.withValues(alpha: 0.85)),
          foregroundColor:
              _locked ? muted : (isSelected ? AppTheme.onGoldColor : AppTheme.darkTextColor),
          disabledBackgroundColor: muted.withValues(alpha: 0.12),
          disabledForegroundColor: muted.withValues(alpha: 0.8),
          elevation: _locked ? 0 : (isSelected ? 2 : 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(
              color: _locked
                  ? muted.withValues(alpha: 0.25)
                  : AppTheme.goldColor.withValues(alpha: 0.9),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _locked ? LucideIcons.lock : LucideIcons.crown,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              _locked ? 'غیرقابل خرید' : 'خرید بسته کامل',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
