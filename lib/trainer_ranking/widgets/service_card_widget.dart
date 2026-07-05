import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ServiceCardWidget extends StatelessWidget {
  const ServiceCardWidget({
    required this.icon,
    required this.title,
    required this.description,
    required this.price,
    required this.period,
    required this.features,
    required this.color,
    this.isPopular = false,
    this.disabled = false,
    this.serviceId,
    this.isSelected = false,
    this.isProcessing = false,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final String price;
  final String period;
  final List<String> features;
  final Color color;
  final bool isPopular;
  final bool disabled;
  final String? serviceId;
  final bool isSelected;
  final bool isProcessing;
  final VoidCallback? onTap;

  bool get _locked => disabled || onTap == null;

  @override
  Widget build(BuildContext context) {
    final muted = context.textSecondary;
    final borderColor = _locked
        ? muted.withValues(alpha: 0.25)
        : (isSelected
            ? AppTheme.goldColor
            : (isPopular ? AppTheme.goldColor : color.withValues(alpha: 0.35)));

    return Opacity(
      opacity: _locked ? 0.52 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? (Matrix4.identity()..scaleByDouble(0.98, 0.98, 0.98, 1))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _locked ? null : onTap,
            borderRadius: BorderRadius.circular(18.r),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(18.r),
                border: Border.all(
                  color: borderColor,
                  width: isSelected ? 2.5 : (isPopular ? 2 : 1.5),
                ),
                boxShadow: [
                  if (!_locked)
                    BoxShadow(
                      color: (isSelected ? AppTheme.goldColor : color)
                          .withValues(alpha: 0.12),
                      blurRadius: 12.r,
                      offset: Offset(0, 4.h),
                    ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(17.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      height: 3.h,
                      color: _locked ? muted.withValues(alpha: 0.35) : color,
                    ),
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 16.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(context),
                          SizedBox(height: 14.h),
                          _buildFeaturesSection(context),
                          SizedBox(height: 14.h),
                          _buildPurchaseButton(context),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: EdgeInsets.all(8.w),
          decoration: BoxDecoration(
            color: color.withValues(alpha: _locked ? 0.08 : 0.18),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Icon(icon, color: color, size: 22.sp),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        color: context.textColor,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPopular && !_locked) ...[
                    SizedBox(width: 6.w),
                    _buildBadge('محبوب', AppTheme.goldColor),
                  ],
                ],
              ),
              SizedBox(height: 5.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 12.sp,
                  height: 1.35,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        _buildPriceSection(context),
      ],
    );
  }

  Widget _buildBadge(String text, Color badgeColor) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: AppTheme.darkTextColor,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildPriceSection(BuildContext context) {
    final muted = context.textSecondary;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color.withValues(alpha: _locked ? 0.05 : 0.1),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: color.withValues(alpha: _locked ? 0.12 : 0.22),
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
                Flexible(
                  child: Text(
                    price,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: _locked ? muted : color,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w800,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              period,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: muted,
                fontSize: 10.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شامل',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 12.sp,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 8.h),
        ...features.map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 5.h),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  LucideIcons.check,
                  color: color.withValues(alpha: _locked ? 0.45 : 0.9),
                  size: 16.sp,
                ),
                SizedBox(width: 8.w),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
              ? muted.withValues(alpha: 0.2)
              : (isSelected
                  ? AppTheme.goldColor
                  : color.withValues(alpha: 0.22)),
          foregroundColor: _locked
              ? muted
              : (isSelected ? AppTheme.onGoldColor : context.textColor),
          disabledBackgroundColor: muted.withValues(alpha: 0.15),
          disabledForegroundColor: muted.withValues(alpha: 0.75),
          elevation: _locked ? 0 : (isSelected ? 2 : 0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14.r),
            side: BorderSide(
              color: _locked
                  ? muted.withValues(alpha: 0.25)
                  : color.withValues(alpha: 0.45),
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _locked ? LucideIcons.lock : LucideIcons.shoppingCart,
              size: 18.sp,
            ),
            SizedBox(width: 8.w),
            Text(
              _locked ? 'غیرقابل خرید' : 'ادامه و پرداخت',
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
