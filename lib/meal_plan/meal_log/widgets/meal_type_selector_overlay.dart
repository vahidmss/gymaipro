import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:lucide_icons/lucide_icons.dart';

class MealTypeSelectorOverlay extends StatelessWidget {
  const MealTypeSelectorOverlay({
    required this.onClose,
    required this.onMealTypeSelected,
    super.key,
  });
  final VoidCallback onClose;
  final void Function(String) onMealTypeSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        onTap: onClose,
        child: ColoredBox(
          color: Colors.black.withValues(alpha: 0.7),
          child: Center(
            child: Container(
              width: 220.w,
              margin: EdgeInsets.all(10.w),
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                  color: const Color(0xFFD4AF37).withValues(alpha: 0.25),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 12.r,
                    offset: Offset(0.w, 6.h),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title with close
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.all(6.w),
                        decoration: BoxDecoration(
                          color: const Color(
                            0xFFD4AF37,
                          ).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8.r),
                          border: Border.all(
                            color: const Color(
                              0xFFD4AF37,
                            ).withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          LucideIcons.utensils,
                          color: const Color(0xFFD4AF37),
                          size: 14.sp,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'نوع وعده غذایی را انتخاب کنید',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ),
                      Container(
                        width: 30.w,
                        height: 30.h,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(6.r),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: IconButton(
                          icon: Icon(
                            LucideIcons.x,
                            color: Colors.white70,
                            size: 14.sp,
                          ),
                          onPressed: onClose,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 260.h,
                    width: 200.w,
                    child: GridView.count(
                      shrinkWrap: true,
                      crossAxisCount: 2,
                      crossAxisSpacing: 6,
                      mainAxisSpacing: 6,
                      childAspectRatio: 0.8,
                      physics: const NeverScrollableScrollPhysics(),
                      children: [
                        _buildCard(
                          'صبحانه',
                          LucideIcons.sunrise,
                          Colors.orange[400]!,
                        ),
                        _buildCard(
                          'ناهار',
                          LucideIcons.sun,
                          Colors.green[400]!,
                        ),
                        _buildCard('شام', LucideIcons.moon, Colors.blue[400]!),
                        _buildCard(
                          'میان‌وعده',
                          LucideIcons.coffee,
                          Colors.purple[400]!,
                        ),
                      ],
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

  Widget _buildCard(String title, IconData icon, Color color) {
    return GestureDetector(
      onTap: () => onMealTypeSelected(title),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: color.withValues(alpha: 0.18)),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.07),
              blurRadius: 4.r,
              offset: Offset(0.w, 2.h),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(7.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(icon, size: 18.sp, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: Colors.amber[100],
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
