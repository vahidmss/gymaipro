import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/pwa_platform.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Guides iPhone/iPad Safari users to Add to Home Screen (no auto-prompt on iOS).
class IosPwaInstallBanner extends StatefulWidget {
  const IosPwaInstallBanner({super.key});

  @override
  State<IosPwaInstallBanner> createState() => _IosPwaInstallBannerState();
}

class _IosPwaInstallBannerState extends State<IosPwaInstallBanner> {
  static const _dismissedKey = 'ios_pwa_install_banner_dismissed_v1';

  bool _visible = false;
  bool _showGuide = false;

  @override
  void initState() {
    super.initState();
    if (kIsWeb) {
      unawaited(_evaluate());
    }
  }

  Future<void> _evaluate() async {
    if (!PwaPlatform.shouldOfferIosHomeScreenInstall) return;
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getBool(_dismissedKey) ?? false) return;
    if (!mounted) return;
    // Delay so it doesn't fight the splash / first paint.
    await Future<void>.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    if (!PwaPlatform.shouldOfferIosHomeScreenInstall) return;
    setState(() => _visible = true);
  }

  Future<void> _dismiss({required bool permanent}) async {
    if (permanent) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_dismissedKey, true);
    }
    if (mounted) {
      setState(() {
        _visible = false;
        _showGuide = false;
      });
    }
  }

  void _openGuide() {
    setState(() => _showGuide = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb || !_visible) return const SizedBox.shrink();

    final bottom = MediaQuery.paddingOf(context).bottom;
    return SafeArea(
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Padding(
          padding: EdgeInsets.fromLTRB(12.w, 0, 12.w, 12.h + bottom * 0.15),
          child: Material(
            color: Colors.transparent,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: _showGuide ? _buildGuideCard(context) : _buildTeaser(context),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeaser(BuildContext context) {
    return Container(
      key: const ValueKey('pwa-teaser'),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: context.cardColor.withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.35)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 16.r,
            offset: Offset(0, 6.h),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.w,
            decoration: BoxDecoration(
              color: AppTheme.goldColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10.r),
            ),
            child: Icon(
              LucideIcons.smartphone,
              color: AppTheme.goldColor,
              size: 22.sp,
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'نصب روی صفحه اصلی آیفون',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w700,
                    color: context.textColor,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  'مثل اپ واقعی، بدون نوار آدرس — از Share اضافه کنید',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _openGuide,
            child: Text(
              'آموزش',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
                fontWeight: FontWeight.w700,
                fontSize: 12.sp,
              ),
            ),
          ),
          IconButton(
            tooltip: 'بعداً',
            onPressed: () => _dismiss(permanent: false),
            icon: Icon(
              LucideIcons.x,
              size: 18.sp,
              color: context.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideCard(BuildContext context) {
    final steps = <(IconData, String)>[
      (LucideIcons.share, '۱. دکمه Share (مربع با فلش) پایین Safari را بزنید'),
      (LucideIcons.plusSquare, '۲. گزینه «Add to Home Screen» را انتخاب کنید'),
      (LucideIcons.check, '۳. Add را بزنید — آیکن GYMAI روی صفحه اصلی می‌آید'),
    ];

    return Container(
      key: const ValueKey('pwa-guide'),
      padding: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 12.h),
      decoration: BoxDecoration(
        color: context.cardColor.withValues(alpha: 0.98),
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: AppTheme.goldColor.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20.r,
            offset: Offset(0, 8.h),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(LucideIcons.info, color: AppTheme.goldColor, size: 20.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'نصب وب‌اپ GYMAI Pro',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: context.textColor,
                  ),
                ),
              ),
              IconButton(
                onPressed: () => setState(() => _showGuide = false),
                icon: Icon(
                  LucideIcons.chevronDown,
                  size: 20.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            'در آیفون نصب خودکار وجود ندارد. این کار را فقط یک‌بار در Safari انجام دهید:',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 11.5.sp,
              height: 1.45,
              color: context.textSecondary,
            ),
          ),
          SizedBox(height: 12.h),
          for (final step in steps) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(step.$1, size: 18.sp, color: AppTheme.goldColor),
                SizedBox(width: 10.w),
                Expanded(
                  child: Text(
                    step.$2,
                    style: TextStyle(
                      fontFamily: AppTheme.fontFamily,
                      fontSize: 12.sp,
                      height: 1.4,
                      color: context.textColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 10.h),
          ],
          Text(
            'نکته: اعلان سیستمی پوش روی وب‌اپ iOS فعلاً فعال نیست؛ اعلان‌های داخل برنامه کار می‌کنند. بعد از نصب، یک‌بار وارد حساب شوید.',
            style: TextStyle(
              fontFamily: AppTheme.fontFamily,
              fontSize: 10.5.sp,
              height: 1.4,
              color: AppTheme.goldColor.withValues(alpha: 0.9),
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            children: [
              TextButton(
                onPressed: () => _dismiss(permanent: true),
                child: Text(
                  'دیگر نشان نده',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontSize: 11.sp,
                    color: context.textSecondary,
                  ),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _dismiss(permanent: false),
                child: Text(
                  'باشه',
                  style: TextStyle(
                    fontFamily: AppTheme.fontFamily,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.goldColor,
                    fontSize: 13.sp,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
