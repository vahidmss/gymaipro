import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/backend_reachability_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({
    this.onReconnect,
    super.key,
  });

  final VoidCallback? onReconnect;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _checking = false;
  DateTime? _lastBackPressed;
  StreamSubscription<bool>? _connectivitySub;

  @override
  void initState() {
    super.initState();
    // Auto-reconnect when connectivity is restored
    _connectivitySub =
        ConnectivityService.instance.isConnectedStream.listen((online) {
      if (online && !_checking) {
        _tryReconnect();
      }
    });
  }

  @override
  void dispose() {
    _connectivitySub?.cancel();
    super.dispose();
  }

  Future<void> _tryReconnect() async {
    if (_checking) return;
    setState(() => _checking = true);

    final online = await ConnectivityService.instance.checkNow();
    bool backendReachable = false;

    if (online) {
      backendReachable = await BackendReachabilityService.isBackendReachable(
        timeout: const Duration(seconds: 5),
      );
    }

    if (!mounted) return;
    setState(() => _checking = false);

    if (online && backendReachable) {
      if (widget.onReconnect != null) {
        widget.onReconnect!();
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('اتصال به سرور برقرار نشد. دوباره تلاش کنید'),
          duration: const Duration(seconds: 2),
          backgroundColor: AppTheme.darkCardColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.r),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final now = DateTime.now();
        if (_lastBackPressed == null ||
            now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
          _lastBackPressed = now;
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    const Text('برای خروج، دوباره دکمه بازگشت را بزنید'),
                duration: const Duration(seconds: 2),
                backgroundColor: AppTheme.darkCardColor,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.r),
                ),
              ),
            );
          }
          return;
        }
        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  LucideIcons.wifiOff,
                  color: AppTheme.goldColor,
                  size: 72.sp,
                ),
                const SizedBox(height: 16),
                Text(
                  'اتصال به سرور برقرار نیست',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'اینترنت یا دسترسی به سرور داخلی را بررسی کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 14.sp,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: 180.w,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.goldColor,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12.h),
                    ),
                    onPressed: _tryReconnect,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: _checking
                          ? SizedBox(
                              key: const ValueKey('loading'),
                              height: 18.h,
                              width: 18.w,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.black,
                              ),
                            )
                          : Text(
                              'تلاش مجدد',
                              key: const ValueKey('text'),
                              style: TextStyle(
                                fontFamily: AppTheme.fontFamily,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                AnimatedOpacity(
                  opacity: _checking ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 300),
                  child: Text(
                    'در حال بررسی اتصال...',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
