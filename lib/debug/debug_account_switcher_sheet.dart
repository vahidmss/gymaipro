import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/debug/debug_account_switch_service.dart';
import 'package:gymaipro/debug/debug_premium_service.dart';
import 'package:gymaipro/debug/debug_test_accounts.dart';
import 'package:gymaipro/payment/models/coach_plan_catalog.dart';
import 'package:gymaipro/payment/models/subscription.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet: debug account switch + grant/revoke AI premium.
Future<void> showDebugAccountSwitcherSheet(BuildContext context) async {
  assert(kDebugMode, 'showDebugAccountSwitcherSheet is debug-only');
  if (!kDebugMode) return;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).brightness == Brightness.dark
        ? AppTheme.darkCardColor
        : AppTheme.lightCardColor,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
    ),
    builder: (sheetContext) => const DebugAccountSwitcherSheet(),
  );
}

class DebugAccountSwitcherSheet extends StatefulWidget {
  const DebugAccountSwitcherSheet({super.key});

  @override
  State<DebugAccountSwitcherSheet> createState() =>
      _DebugAccountSwitcherSheetState();
}

class _DebugAccountSwitcherSheetState extends State<DebugAccountSwitcherSheet> {
  final _service = DebugAccountSwitchService();
  final _premium = DebugPremiumService();

  String? _switchingPhone;
  bool _premiumBusy = false;
  String? _error;
  Subscription? _activePremium;
  bool _premiumLoaded = false;

  @override
  void initState() {
    super.initState();
    unawaited(_loadPremium());
  }

  Future<void> _loadPremium() async {
    try {
      final sub = await _premium.currentPremium();
      if (!mounted) return;
      setState(() {
        _activePremium = sub;
        _premiumLoaded = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _activePremium = null;
        _premiumLoaded = true;
      });
    }
  }

  Future<void> _onSelect(DebugTestAccount account) async {
    if (_switchingPhone != null || _premiumBusy) return;
    setState(() {
      _switchingPhone = account.phone;
      _error = null;
    });

    Navigator.of(context).pop();

    try {
      await Future<void>.delayed(const Duration(milliseconds: 180));
      final host = appNavigatorKey.currentContext;
      if (host != null && host.mounted) {
        ScaffoldMessenger.of(host).showSnackBar(
          SnackBar(
            content: Text(
              'سوییچ به ${account.labelFa}...',
              style: const TextStyle(fontFamily: AppTheme.fontFamily),
            ),
            duration: const Duration(seconds: 2),
          ),
        );
      }
      await _service.switchTo(account);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('DEBUG switch failed: $e');
      }
      final host = appNavigatorKey.currentContext;
      if (host == null || !host.mounted) return;
      ScaffoldMessenger.of(host).showSnackBar(
        SnackBar(
          content: Text(
            'سوییچ ناموفق: $e',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  Future<void> _grantPremium({required String planId}) async {
    if (_premiumBusy || _switchingPhone != null) return;
    setState(() {
      _premiumBusy = true;
      _error = null;
    });
    try {
      final sub = await _premium.grantPremium(planId: planId);
      if (!mounted) return;
      setState(() {
        _activePremium = sub;
        _premiumBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${CoachPlanCatalog.productTitle} فعال شد '
            '(دیباگ · ${CoachPlanCatalog.defaultValidityDays} روز)',
            style: const TextStyle(fontFamily: AppTheme.fontFamily),
          ),
          backgroundColor: Colors.green.shade700,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _premiumBusy = false;
        _error = e.toString();
      });
    }
  }

  Future<void> _revokePremium() async {
    if (_premiumBusy || _switchingPhone != null) return;
    setState(() {
      _premiumBusy = true;
      _error = null;
    });
    try {
      await _premium.revokePremium();
      if (!mounted) return;
      setState(() {
        _activePremium = null;
        _premiumBusy = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'پرمیوم دیباگ حذف شد',
            style: TextStyle(fontFamily: AppTheme.fontFamily),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _premiumBusy = false;
        _error = e.toString();
      });
    }
  }

  IconData _iconForRole(String role) {
    switch (role) {
      case 'admin':
        return LucideIcons.shield;
      case 'trainer':
        return LucideIcons.dumbbell;
      default:
        return LucideIcons.user;
    }
  }

  List<Widget> _accountGroup({
    required String title,
    required List<DebugTestAccount> accounts,
    required Color textColor,
    required Color secondary,
    required bool locked,
  }) {
    return [
      SizedBox(height: 12.h),
      Text(
        title,
        style: TextStyle(
          color: secondary,
          fontSize: 11.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
      SizedBox(height: 8.h),
      ...accounts.map((account) {
        final busy = _switchingPhone == account.phone;
        return Padding(
          padding: EdgeInsets.only(bottom: 8.h),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
              side: BorderSide(
                color: AppTheme.goldColor.withValues(alpha: 0.35),
              ),
            ),
            leading: busy
                ? SizedBox(
                    width: 24.w,
                    height: 24.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    _iconForRole(account.role),
                    color: AppTheme.goldColor,
                  ),
            title: Text(
              account.labelFa,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
            subtitle: Text(
              '${account.username} · ${account.phone}',
              style: TextStyle(color: secondary, fontSize: 11.sp),
            ),
            trailing: Text(
              account.role,
              style: TextStyle(
                color: AppTheme.goldColor.withValues(alpha: 0.9),
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            onTap: locked ? null : () => _onSelect(account),
          ),
        );
      }),
    ];
  }

  String _planLabel(Subscription sub) {
    final plan = CoachPlanCatalog.planFromSubscriptionType(sub.type);
    return CoachPlanCatalog.persianTitle(plan);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor;
    final secondary = textColor.withValues(alpha: 0.65);
    final locked = _switchingPhone != null || _premiumBusy;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: secondary,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            Text(
              'ابزارهای دیباگ',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'فقط در حالت دیباگ — بدون OTP / بدون پرداخت',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary, fontSize: 12.sp),
            ),
            SizedBox(height: 20.h),
            Text(
              'پرمیوم هوش مصنوعی',
              style: TextStyle(
                color: textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              _premiumLoaded
                  ? (_activePremium == null
                        ? 'وضعیت فعلی: رایگان'
                        : 'وضعیت فعلی: ${_planLabel(_activePremium!)} · تا ${_activePremium!.expiryDate.toLocal().toString().split(' ').first}')
                  : 'در حال خواندن وضعیت…',
              style: TextStyle(color: secondary, fontSize: 11.5.sp),
            ),
            SizedBox(height: 10.h),
            _DebugActionTile(
              icon: LucideIcons.clipboardList,
              title: 'فعال‌سازی برنامه مربی هوشمند',
              subtitle:
                  '${CoachPlanCatalog.defaultValidityDays} روز دسترسی کامل ابزارها',
              busy: _premiumBusy,
              enabled: !locked,
              onTap: () => _grantPremium(planId: CoachPlanCatalog.coachProId),
            ),
            SizedBox(height: 8.h),
            _DebugActionTile(
              icon: LucideIcons.circleMinus,
              title: 'حذف دسترسی برنامه',
              subtitle: 'لغو پاس فعال',
              busy: _premiumBusy,
              enabled: !locked && _activePremium != null,
              destructive: true,
              onTap: _revokePremium,
            ),
            SizedBox(height: 20.h),
            Text(
              'سوییچ اکانت تستی',
              style: TextStyle(
                color: textColor,
                fontSize: 13.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            ..._accountGroup(
              title: 'ورزشکاران',
              accounts: DebugTestAccounts.athletes,
              textColor: textColor,
              secondary: secondary,
              locked: locked,
            ),
            ..._accountGroup(
              title: 'مربیان',
              accounts: DebugTestAccounts.trainers,
              textColor: textColor,
              secondary: secondary,
              locked: locked,
            ),
            ..._accountGroup(
              title: 'ادمین',
              accounts: const [DebugTestAccounts.admin],
              textColor: textColor,
              secondary: secondary,
              locked: locked,
            ),
            if (_error != null) ...[
              SizedBox(height: 8.h),
              Text(
                _error!,
                style: TextStyle(
                  color: Colors.redAccent,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebugActionTile extends StatelessWidget {
  const _DebugActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    required this.enabled,
    this.busy = false,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;
  final bool busy;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor;
    final accent = destructive ? Colors.redAccent : AppTheme.goldColor;

    return ListTile(
      enabled: enabled,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.r),
        side: BorderSide(color: accent.withValues(alpha: 0.35)),
      ),
      leading: busy
          ? SizedBox(
              width: 24.w,
              height: 24.w,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: accent,
              ),
            )
          : Icon(icon, color: accent),
      title: Text(
        title,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w600,
          fontSize: 14.sp,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: textColor.withValues(alpha: 0.65),
          fontSize: 11.sp,
        ),
      ),
      onTap: enabled && !busy ? onTap : null,
    );
  }
}
