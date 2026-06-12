import 'package:flutter/material.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/support_launcher.dart';

/// Gate for online payment / wallet top-up when [AppConfig.onlinePaymentEnabled] is off.
class PaymentGuard {
  PaymentGuard._();

  static bool get onlinePaymentEnabled => AppConfig.onlinePaymentEnabled;

  static bool get blocksOnlineCheckout => !onlinePaymentEnabled;

  /// Shows a short dialog; returns true if online payment is allowed.
  static Future<bool> ensureOnlinePaymentAllowed(BuildContext context) async {
    if (onlinePaymentEnabled) return true;
    await showManualPaymentDialog(context);
    return false;
  }

  static Future<void> showManualPaymentDialog(BuildContext context) async {
    if (!context.mounted) return;
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text(
          'پرداخت آنلاین غیرفعال',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        content: const Text(
          'در نسخه فعلی باشگاه، پرداخت و تمدید به‌صورت دستی انجام می‌شود.\n'
          'با مربی یا پشتیبانی باشگاه هماهنگ کنید.',
          style: TextStyle(fontFamily: AppTheme.fontFamily, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text(
              'بستن',
              style: TextStyle(fontFamily: AppTheme.fontFamily),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              SupportLauncher.openBestContact(context);
            },
            child: const Text(
              'تماس با پشتیبانی',
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                color: AppTheme.goldColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
