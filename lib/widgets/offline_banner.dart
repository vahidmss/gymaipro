import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<bool>(
      stream: ConnectivityService.instance.isConnectedStream,
      initialData: true,
      builder: (context, snapshot) {
        final isConnected = snapshot.data ?? true;
        if (isConnected) return const SizedBox.shrink();
        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double horizontalMargin = 12;
                final double maxWidth =
                    MediaQuery.of(context).size.width - (horizontalMargin * 2);
                return Container(
                  margin: const EdgeInsets.all(horizontalMargin),
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  decoration: BoxDecoration(
                    // بنر هشدار همیشه تیره — روی لایت و دارک خوانا
                    color: const Color(0xFF141414),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 14.r,
                        offset: Offset(0.w, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.wifi_off_rounded,
                        color: AppTheme.goldColor,
                        size: 22.sp,
                      ),
                      SizedBox(width: 10.w),
                      Flexible(
                        child: Text(
                          'اتصال اینترنت برقرار نیست. لطفاً اینترنت را روشن کنید.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13.5.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: AppTheme.fontFamily,
                            height: 1.45,
                            decoration: TextDecoration.none,
                          ),
                          softWrap: true,
                          overflow: TextOverflow.visible,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
