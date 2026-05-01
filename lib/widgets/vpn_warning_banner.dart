import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/theme/app_theme.dart';

class VpnWarningBanner extends StatefulWidget {
  const VpnWarningBanner({super.key});

  @override
  State<VpnWarningBanner> createState() => _VpnWarningBannerState();
}

class _VpnWarningBannerState extends State<VpnWarningBanner> {
  bool _dismissed = false;

  Future<bool> _checkVpnOnce() async {
    final svc = ConnectivityService.instance;
    await svc.checkNow();
    return svc.isVpn;
  }

  late final Future<bool> _vpnFuture = _checkVpnOnce();

  @override
  Widget build(BuildContext context) {
    if (_dismissed) return const SizedBox.shrink();

    // فقط وقتی دستگاه خودش وی‌پی‌ان را گزارش کند بنر نشان بده (بدون اتکا به آی‌پی)
    return FutureBuilder<bool>(
      future: _vpnFuture,
      builder: (context, snapshot) {
        if (_dismissed) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox.shrink();
        }
        if (snapshot.data != true) return const SizedBox.shrink();

        return SafeArea(
          child: Align(
            alignment: Alignment.topCenter,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const double horizontalMargin = 12;
                final double maxWidth =
                    MediaQuery.of(context).size.width - (horizontalMargin * 2);
                return Container(
                  margin: EdgeInsets.fromLTRB(
                    horizontalMargin,
                    8.h,
                    horizontalMargin,
                    0,
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: 14.w,
                    vertical: 10.h,
                  ),
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  decoration: BoxDecoration(
                    // پس‌زمینه تیره تا روی هر صفحه (حتی سفید) واضح دیده شود
                    color: Colors.black.withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(12.r),
                    border: Border.all(
                      color: AppTheme.goldColor.withValues(alpha: 0.7),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black87,
                        blurRadius: 12.r,
                        offset: Offset(0.w, 4.h),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public,
                        color: AppTheme.goldColor,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'وی‌پی‌ان روشن است. برای سرعت بیشتر خاموشش کنید.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: AppTheme.fontFamily,
                          ),
                          softWrap: true,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close,
                          size: 18,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          setState(() {
                            _dismissed = true;
                          });
                        },
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

