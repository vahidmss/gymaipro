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

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disabled ? 0.5 : 1,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        transform: isSelected
            ? (Matrix4.identity()..scale(0.98))
            : Matrix4.identity(),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: disabled ? null : onTap,
            borderRadius: BorderRadius.circular(16.r),
            child: Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: context.cardColor,
                borderRadius: BorderRadius.circular(16.r),
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor
                      : (isPopular
                          ? AppTheme.goldColor
                          : color.withValues(alpha: 0.3)),
                  width: isSelected ? 2.5 : (isPopular ? 2 : 1.5),
                ),
                boxShadow: [
                  BoxShadow(
                    color: (isSelected ? AppTheme.goldColor : color)
                        .withValues(alpha: 0.15),
                    blurRadius: 8.r,
                    offset: Offset(0.w, 2.h),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(context),
                  SizedBox(height: 16.h),
                  _buildFeaturesSection(context),
                  SizedBox(height: 16.h),
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
            color: color.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 10),
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
                        fontSize: 17.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isPopular) ...[
                    const SizedBox(width: 6),
                    _buildBadge('محبوب', AppTheme.goldColor),
                  ],
                ],
              ),
              SizedBox(height: 6.h),
              Text(
                description,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: context.textSecondary,
                  fontSize: 12.sp,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        _buildPriceSection(context),
      ],
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: AppTheme.fontFamily,
          color: Colors.white,
          fontSize: 9.sp,
          fontWeight: FontWeight.bold,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
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
            Flexible(
              child: Text(
                price,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  color: color,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
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
            color: context.textSecondary,
            fontSize: 11.sp,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'شامل:',
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            color: context.textColor,
            fontSize: 13.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 8.h),
        ...features.map(
          (feature) => Padding(
            padding: EdgeInsets.only(bottom: 6.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    LucideIcons.check,
                    color: color,
                    size: 14.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    feature,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: context.textColor,
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w500,
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
    return SizedBox(
      width: double.infinity,
      height: 44.h,
      child: ElevatedButton(
        onPressed: disabled ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isSelected
              ? AppTheme.goldColor
              : (isPopular
                  ? color.withValues(alpha: 0.2)
                  : color.withValues(alpha: 0.15)),
          foregroundColor: isSelected
              ? Colors.black
              : (isPopular ? color : context.textColor),
          elevation: isSelected ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
            side: BorderSide(
              color: isSelected
                  ? AppTheme.goldColor
                  : color.withValues(alpha: 0.5),
              width: isSelected ? 2 : 1.5,
            ),
          ),
          padding: EdgeInsets.symmetric(horizontal: 16.w),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.shoppingCart, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              'خرید برنامه',
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
