import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/core/app_navigator.dart';
import 'package:gymaipro/debug/debug_account_switch_service.dart';
import 'package:gymaipro/debug/debug_test_accounts.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Bottom sheet listing seeded debug accounts for quick session switch.
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
  String? _switchingPhone;
  String? _error;

  Future<void> _onSelect(DebugTestAccount account) async {
    if (_switchingPhone != null) return;
    setState(() {
      _switchingPhone = account.phone;
      _error = null;
    });

    // Close the sheet before auth/nav work so we never replace /main while
    // a modal route is still active (that race was freezing the app).
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.darkTextColor : AppTheme.lightTextColor;
    final secondary = textColor.withValues(alpha: 0.65);

    return SafeArea(
      child: Padding(
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
              'سوییچ اکانت تستی',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.goldColor,
                fontSize: 16.sp,
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6.h),
            Text(
              'فقط در حالت دیباگ — بدون OTP',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondary, fontSize: 12.sp),
            ),
            SizedBox(height: 16.h),
            ...DebugTestAccounts.all.map((account) {
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
                  onTap: _switchingPhone != null
                      ? null
                      : () => _onSelect(account),
                ),
              );
            }),
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
