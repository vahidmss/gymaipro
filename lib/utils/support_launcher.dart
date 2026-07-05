import 'package:flutter/material.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens support channels configured via --dart-define or .env (debug only).
class SupportLauncher {
  SupportLauncher._();

  static Future<void> openPhone(BuildContext context) async {
    final phone = supportPhone.trim();
    if (phone.isEmpty) {
      _showNotConfigured(context);
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static Future<void> openTelegram(BuildContext context) async {
    final telegram = supportTelegram.trim();
    if (telegram.isEmpty) {
      _showNotConfigured(context);
      return;
    }
    final handle =
        telegram.startsWith('@') ? telegram.substring(1) : telegram;
    final uri = Uri.parse('https://t.me/$handle');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  static String get supportPhone => AppConfig.supportPhone;

  static String get supportTelegram => AppConfig.supportTelegram;

  static String get telegramDisplayHandle {
    final t = supportTelegram.trim();
    if (t.isEmpty) return '';
    return t.startsWith('@') ? t : '@$t';
  }

  static Future<void> openBestContact(BuildContext context) async {
    final whatsapp = AppConfig.supportWhatsApp.trim();
    if (whatsapp.isNotEmpty) {
      final digits = whatsapp.replaceAll(RegExp(r'\D'), '');
      final uri = Uri.parse('https://wa.me/$digits');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    final phone = AppConfig.supportPhone.trim();
    if (phone.isNotEmpty) {
      final uri = Uri(scheme: 'tel', path: phone);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
        return;
      }
    }

    final telegram = AppConfig.supportTelegram.trim();
    if (telegram.isNotEmpty) {
      final handle = telegram.startsWith('@') ? telegram.substring(1) : telegram;
      final uri = Uri.parse('https://t.me/$handle');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }
    }

    if (!context.mounted) return;
    _showNotConfigured(context);
  }

  static void _showNotConfigured(BuildContext context) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'شماره پشتیبانی هنوز در اپ تنظیم نشده. با مدیر باشگاه تماس بگیرید.',
          textAlign: TextAlign.center,
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
        backgroundColor: AppTheme.goldColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
