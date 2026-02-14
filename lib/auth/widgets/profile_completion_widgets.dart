import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:responsive_framework/responsive_framework.dart';

// کارت wrapper برای مراحل تکمیل پروفایل
class ProfileCardWrapper extends StatelessWidget {
  const ProfileCardWrapper({
    required this.child,
    this.padding,
    super.key,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    return Align(
      alignment: Alignment.topCenter,
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.only(
          left: 20.w,
          right: 20.w,
          top: 10.h,
          bottom: 4.h + keyboardHeight,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: 360.w),
          child: RepaintBoundary(
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              behavior: HitTestBehavior.translucent,
              child: Container(
                padding: padding ?? EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.lightCardColor,
                    AppTheme.lightGradientStart.withValues(alpha: 0.2),
                    AppTheme.lightCardColor,
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                borderRadius: BorderRadius.circular(28.r),
                border: Border.all(
                  color: AppTheme.goldColor.withValues(alpha: 0.5),
                  width: 2.5.w,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.goldColor.withValues(alpha: 0.35),
                    blurRadius: 32.r,
                    offset: Offset(0.w, 12.h),
                    spreadRadius: 3.r,
                  ),
                  BoxShadow(
                    color: AppTheme.lightTextColor.withValues(alpha: 0.08),
                    blurRadius: 20.r,
                    offset: Offset(0.w, 6.h),
                    spreadRadius: 1.r,
                  ),
                ],
              ),
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// گزینه انتخاب جنسیت
class GenderOption extends StatelessWidget {
  const GenderOption({
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightGradientStart.withValues(alpha: 0.4),
                          AppTheme.lightCardColor,
                          AppTheme.lightGoldGradient.withValues(alpha: 0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: isSelected ? null : AppTheme.lightCardColor,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : AppTheme.lightDividerColor,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.25),
                          blurRadius: 12.r,
                          spreadRadius: 1.r,
                          offset: Offset(0.w, 4.h),
                        ),
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.05),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.06),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.goldColor.withValues(alpha: 0.15),
                                AppTheme.goldColor.withValues(alpha: 0.25),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : AppTheme.lightDividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(14.r),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 32.sp,
                      color: isSelected
                          ? AppTheme.goldColor
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  SizedBox(width: 20.w),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: ResponsiveValue(
                          context,
                          defaultValue: 18.sp,
                          conditionalValues: [
                            Condition.smallerThan(name: MOBILE, value: 16.sp),
                            Condition.largerThan(name: TABLET, value: 20.sp),
                          ],
                        ).value,
                        fontWeight:
                            isSelected ? FontWeight.bold : FontWeight.w600,
                        color: isSelected
                            ? AppTheme.goldColor
                            : AppTheme.lightTextColor,
                        fontFamily: AppTheme.fontFamily,
                      ),
                    ),
                  ),
                  if (isSelected)
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor,
                              AppTheme.darkGold,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Dropdown برای تاریخ
class DateDropdown<T> extends StatelessWidget {
  const DateDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    super.key,
  });

  final String label;
  final T? value;
  final List<T> items;
  final void Function(T?) onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : AppTheme.lightDividerColor,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: AppTheme.lightCardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.lightCardColor,
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: value != null
                ? AppTheme.goldColor
                : AppTheme.lightTextSecondary,
            size: 20.sp,
          ),
          hint: Text(
            label,
            style: TextStyle(
              color: AppTheme.lightTextSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          items: items.map((T item) {
            return DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                style: TextStyle(
                  color: AppTheme.lightTextColor,
                  fontSize: 14.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// Dropdown برای ماه‌های شمسی
class MonthDropdown extends StatelessWidget {
  const MonthDropdown({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final int? value;
  final void Function(int?) onChanged;

  String _getPersianMonthName(int month) {
    const months = [
      '',
      'فروردین',
      'اردیبهشت',
      'خرداد',
      'تیر',
      'مرداد',
      'شهریور',
      'مهر',
      'آبان',
      'آذر',
      'دی',
      'بهمن',
      'اسفند',
    ];
    return months[month];
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        border: Border.all(
          color: value != null
              ? AppTheme.goldColor.withValues(alpha: 0.5)
              : AppTheme.lightDividerColor,
        ),
        borderRadius: BorderRadius.circular(12.r),
        color: AppTheme.lightCardColor,
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: value,
          isExpanded: true,
          dropdownColor: AppTheme.lightCardColor,
          style: TextStyle(
            color: AppTheme.lightTextColor,
            fontSize: 14.sp,
            fontFamily: AppTheme.fontFamily,
          ),
          icon: Icon(
            Icons.keyboard_arrow_down,
            color: value != null
                ? AppTheme.goldColor
                : AppTheme.lightTextSecondary,
            size: 20.sp,
          ),
          hint: Text(
            'ماه',
            style: TextStyle(
              color: AppTheme.lightTextSecondary,
              fontSize: 14.sp,
              fontFamily: AppTheme.fontFamily,
            ),
          ),
          items: List.generate(12, (i) => i + 1).map((int month) {
            return DropdownMenuItem<int>(
              value: month,
              child: Text(
                _getPersianMonthName(month),
                style: TextStyle(
                  color: AppTheme.lightTextColor,
                  fontSize: 14.sp,
                  fontFamily: AppTheme.fontFamily,
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

// گزینه انتخاب سطح فعالیت
class ActivityOption extends StatelessWidget {
  const ActivityOption({
    required this.value,
    required this.label,
    required this.description,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    super.key,
  });

  final String value;
  final String label;
  final String description;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(20.r),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.lightGradientStart.withValues(alpha: 0.4),
                          AppTheme.lightCardColor,
                          AppTheme.lightGoldGradient.withValues(alpha: 0.3),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      )
                    : null,
                color: isSelected ? null : AppTheme.lightCardColor,
                border: Border.all(
                  color: isSelected
                      ? AppTheme.goldColor.withValues(alpha: 0.6)
                      : AppTheme.lightDividerColor,
                  width: isSelected ? 2 : 1.5,
                ),
                borderRadius: BorderRadius.circular(20.r),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.goldColor.withValues(alpha: 0.25),
                          blurRadius: 12.r,
                          spreadRadius: 1.r,
                          offset: Offset(0.w, 4.h),
                        ),
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.05),
                          blurRadius: 8.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ]
                    : [
                        BoxShadow(
                          color: AppTheme.lightTextColor.withValues(alpha: 0.06),
                          blurRadius: 6.r,
                          offset: Offset(0.w, 2.h),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      gradient: isSelected
                          ? LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                AppTheme.goldColor.withValues(alpha: 0.15),
                                AppTheme.goldColor.withValues(alpha: 0.25),
                              ],
                            )
                          : null,
                      color: isSelected
                          ? null
                          : AppTheme.lightDividerColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12.r),
                      border: isSelected
                          ? Border.all(
                              color: AppTheme.goldColor.withValues(alpha: 0.3),
                              width: 1,
                            )
                          : null,
                    ),
                    child: Icon(
                      icon,
                      size: 28.sp,
                      color: isSelected
                          ? AppTheme.goldColor
                          : AppTheme.lightTextSecondary,
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 18.sp,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 16.sp),
                                Condition.largerThan(name: TABLET, value: 20.sp),
                              ],
                            ).value,
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w600,
                            color: isSelected
                                ? AppTheme.goldColor
                                : AppTheme.lightTextColor,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          description,
                          style: TextStyle(
                            fontSize: ResponsiveValue(
                              context,
                              defaultValue: 13.sp,
                              conditionalValues: [
                                Condition.smallerThan(name: MOBILE, value: 11.sp),
                                Condition.largerThan(name: TABLET, value: 15.sp),
                              ],
                            ).value,
                            color: AppTheme.lightTextSecondary,
                            fontFamily: AppTheme.fontFamily,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    AnimatedScale(
                      scale: isSelected ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.elasticOut,
                      child: Container(
                        width: 28.w,
                        height: 28.h,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              AppTheme.goldColor,
                              AppTheme.darkGold,
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.goldColor.withValues(alpha: 0.4),
                              blurRadius: 8.r,
                              spreadRadius: 1.r,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 18.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

