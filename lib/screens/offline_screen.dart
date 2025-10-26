import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/services/connectivity_service.dart';
import 'package:gymaipro/services/route_service.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  bool _checking = false;
  DateTime? _lastBackPressed;

  Future<void> _tryReconnect() async {
    if (_checking) return;
    setState(() => _checking = true);
    final online = await ConnectivityService.instance.checkNow();
    bool dbReachable = false;
    if (online) {
      try {
        // Lightweight DB reachability check
        await Supabase.instance.client.from('profiles').select('id').limit(1);
        dbReachable = true;
      } catch (_) {
        dbReachable = false;
      }
    }
    setState(() => _checking = false);
    if (!mounted) return;
    if (online && dbReachable) {
      try {
        final target = await RouteService.getInitialRoute();
        if (!mounted) return;
        Navigator.pushNamedAndRemoveUntil(context, target, (route) => false);
      } catch (_) {
        Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('اتصال به سرور برقرار نشد. دوباره تلاش کنید'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<bool> _handleWillPop() async {
    final now = DateTime.now();
    if (_lastBackPressed == null ||
        now.difference(_lastBackPressed!) > const Duration(seconds: 2)) {
      _lastBackPressed = now;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('برای خروج، دوباره دکمه بازگشت را بزنید'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return false; // don't pop
    }
    // Double back within 2 seconds: exit app
    await SystemNavigator.pop();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
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
                  'اتصال اینترنت برقرار نیست',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'لطفاً اینترنت را وصل کنید و دوباره تلاش کنید',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.1),
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
                    ),
                    onPressed: _tryReconnect,
                    child: _checking
                        ? SizedBox(
                            height: 18.h,
                            width: 18.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('تلاش مجدد'),
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
