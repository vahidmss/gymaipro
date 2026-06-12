import 'package:flutter/material.dart';
// دیالوگ کپی روز (CopyDayDialog) مخصوص meal plan
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class CopyDayDialog extends StatefulWidget {
  const CopyDayDialog({
    required this.days,
    required this.currentDayIndex,
    super.key,
  });
  final List<String> days;
  final int currentDayIndex;

  @override
  State<CopyDayDialog> createState() => _CopyDayDialogState();
}

class _CopyDayDialogState extends State<CopyDayDialog> {
  final Set<int> _selectedTargetDays = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Dialog(
      backgroundColor: Colors.black.withValues(alpha: 0.5),
      child: Container(
        padding: EdgeInsets.all(24.w),
        decoration: BoxDecoration(
          color: isDark
              ? Theme.of(context).cardColor
              : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: AppTheme.goldColor.withValues(alpha: isDark ? 0.4 : 0.3),
            width: 1.5.w,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withValues(alpha: 0.5)
                  : AppTheme.lightTextColor.withValues(alpha: 0.08),
              blurRadius: 20.r,
              offset: Offset(0.w, 8.h),
            ),
            BoxShadow(
              color: AppTheme.goldColor.withValues(alpha: isDark ? 0.15 : 0.1),
              blurRadius: 10.r,
              offset: Offset(0.w, 4.h),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(10.w),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppTheme.goldColor.withValues(alpha: 0.2),
                        AppTheme.darkGold.withValues(alpha: 0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.3),
                      width: 1.5.w,
                    ),
                  ),
                  child: Icon(
                    LucideIcons.copy,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'کپی وعده‌های یک روز',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  icon: Icon(
                    LucideIcons.x,
                    color: AppTheme.goldColor,
                    size: 20.sp,
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              'به کدام روزها کپی شود؟',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontSize: 14.sp,
                color: isDark ? Colors.white70 : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 40.h,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: widget.days.length,
                itemBuilder: (context, index) {
                  if (index == widget.currentDayIndex) {
                    return const SizedBox(width: 0);
                  }
                  final isSelected = _selectedTargetDays.contains(index);
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8.r),
                        onTap: () {
                          setState(() {
                            if (isSelected) {
                              _selectedTargetDays.remove(index);
                            } else {
                              _selectedTargetDays.add(index);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12.w,
                            vertical: 8.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected
                                ? LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.goldColor.withValues(alpha: 0.2),
                                      AppTheme.darkGold.withValues(alpha: 0.1),
                                    ],
                                  )
                                : LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      AppTheme.goldColor.withValues(alpha: 0.1),
                                      AppTheme.darkGold.withValues(alpha: 0.05),
                                    ],
                                  ),
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.goldColor
                                  : AppTheme.goldColor.withValues(alpha: 0.3),
                              width: 1.5.w,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: AppTheme.goldColor.withValues(
                                        alpha: 0.2,
                                      ),
                                      blurRadius: 8.r,
                                      offset: Offset(0.w, 2.h),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            widget.days[index],
                            style: TextStyle(
                              fontFamily: AppTheme.fontFamily,
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.black)
                                  : (isDark ? Colors.white70 : Colors.black87),
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            Row(
              textDirection: TextDirection.rtl,
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedTargetDays.isEmpty
                          ? AppTheme.goldColor.withValues(alpha: 0.3)
                          : AppTheme.goldColor,
                      foregroundColor: _selectedTargetDays.isEmpty
                          ? AppTheme.goldColor.withValues(alpha: 0.5)
                          : AppTheme.onGoldColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      elevation: _selectedTargetDays.isEmpty ? 0 : 4,
                      shadowColor: AppTheme.goldColor.withValues(alpha: 0.3),
                    ),
                    onPressed: _selectedTargetDays.isEmpty
                        ? null
                        : () {
                            Navigator.of(context).pop({
                              'to': _selectedTargetDays.toList(),
                            });
                          },
                    child: Text(
                      'کپی کن',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.black : Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.goldColor,
                      side: BorderSide(
                        color: AppTheme.goldColor.withValues(alpha: 0.5),
                        width: 1.5.w,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'انصراف',
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
