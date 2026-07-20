import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/app_initializer.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/auth/services/auth_state_service.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/backend_reachability_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({
    this.onReconnect,
    super.key,
  });

  final VoidCallback? onReconnect;

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen>
    with SingleTickerProviderStateMixin {
  bool _checking = false;
  String? _statusMessage;
  DateTime? _lastBackPressed;
  StreamSubscription<bool>? _connectivitySub;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);

    _connectivitySub =
        ConnectivityService.instance.isConnectedStream.listen((online) {
      if (online && !_checking) {
        _tryReconnect();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _connectivitySub?.cancel();
    super.dispose();
  }

  void _showSnack(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: AppTheme.fontFamily,
            fontSize: 13.sp,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: AppTheme.darkCardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12.r),
        ),
      ),
    );
  }

  Future<void> _tryReconnect() async {
    if (_checking) return;
    setState(() {
      _checking = true;
      _statusMessage = 'در حال بررسی اتصال...';
    });

    try {
      final online = await ConnectivityService.instance.checkNow();
      if (!online) {
        setState(() => _statusMessage = null);
        _showSnack('اینترنت برقرار نیست. لطفاً اتصال را بررسی کنید.');
        return;
      }

      setState(() => _statusMessage = 'در حال اتصال به سرور...');

      final backendReachable = await BackendReachabilityService.isBackendReachable(
        
      );
      if (!backendReachable) {
        setState(() => _statusMessage = null);
        _showSnack(
          'سرور در دسترس نیست. چند لحظه صبر کنید و دوباره تلاش کنید.',
        );
        return;
      }

      setState(() => _statusMessage = 'در حال آماده‌سازی برنامه...');

      AuthStateService.resumeAutoRefresh();
      await AppInitializer.initialize();

      if (!AppInitializer.isSupabaseReady) {
        setState(() => _statusMessage = null);
        _showSnack('اتصال به سرور برقرار نشد. دوباره تلاش کنید.');
        return;
      }

      final route = await RouteService.getInitialRoute();
      if (!mounted) return;

      if (widget.onReconnect != null) {
        widget.onReconnect!();
        return;
      }

      final navigator = rootNavigator ?? Navigator.of(context);
      if (tryNavigateIntegratedRoute(route)) {
        navigator.popUntil((r) => r.isFirst);
        return;
      }

      unawaited(navigator.pushNamedAndRemoveUntil(route, (r) => false));
    } catch (e, stack) {
      if (kDebugMode) {
        debugPrint('Offline reconnect error: $e');
        debugPrint('$stack');
      }
      if (mounted) {
        setState(() => _statusMessage = null);
        _showSnack('خطایی رخ داد. لطفاً دوباره تلاش کنید.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _checking = false;
          _statusMessage = null;
        });
      }
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
            _showSnack('برای خروج، دوباره دکمه بازگشت را بزنید');
          }
          return;
        }
        await SystemNavigator.pop();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF0A0A0A),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  FadeTransition(
                    opacity: Tween<double>(begin: 0.55, end: 1).animate(
                      CurvedAnimation(
                        parent: _pulseController,
                        curve: Curves.easeInOut,
                      ),
                    ),
                    child: Container(
                      width: 120.w,
                      height: 120.w,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppTheme.goldColor.withValues(alpha: 0.06),
                        border: Border.all(
                          color: AppTheme.goldColor.withValues(alpha: 0.18),
                        ),
                      ),
                      child: Icon(
                        LucideIcons.wifiOff,
                        color: AppTheme.goldColor.withValues(alpha: 0.85),
                        size: 48.sp,
                      ),
                    ),
                  ),
                  SizedBox(height: 32.h),
                  Text(
                    'اتصال برقرار نیست',
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Text(
                    'اینترنت یا دسترسی به سرور را بررسی کنید.\nبعد از وصل شدن، دوباره تلاش کنید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 14.sp,
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 36.h),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.goldColor,
                        foregroundColor: AppTheme.onGoldColor,
                        disabledBackgroundColor:
                            AppTheme.goldColor.withValues(alpha: 0.35),
                        disabledForegroundColor:
                            AppTheme.onGoldColor.withValues(alpha: 0.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14.r),
                        ),
                        padding: EdgeInsets.symmetric(vertical: 14.h),
                        elevation: 0,
                      ),
                      onPressed: _checking ? null : _tryReconnect,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 200),
                        child: _checking
                            ? SizedBox(
                                key: const ValueKey('loading'),
                                height: 20.h,
                                width: 20.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppTheme.onGoldColor,
                                ),
                              )
                            : Text(
                                'تلاش مجدد',
                                key: const ValueKey('text'),
                                style: TextStyle(
                                  fontFamily: AppTheme.fontFamily,
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  SizedBox(height: 16.h),
                  AnimatedOpacity(
                    opacity: _statusMessage != null ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: Text(
                      _statusMessage ?? '',
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
      ),
    );
  }
}
