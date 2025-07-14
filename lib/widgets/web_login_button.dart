import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/wordpress_auth_service.dart';

class WebLoginButton extends StatelessWidget {
  final String phoneNumber;

  const WebLoginButton({
    Key? key,
    required this.phoneNumber,
  }) : super(key: key);

  Future<void> _loginToWordPress(BuildContext context) async {
    try {
      final wordPressService = WordPressAuthService();

      // تنظیم کوکی در وردپرس
      final result = await wordPressService.setCookieInWordPress(phoneNumber);

      if (result) {
        // اگر تنظیم کوکی موفق بود، سایت را باز کن
        const url = 'https://gymaipro.ir/?direct_login=true';

        // نمایش پیام
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('در حال انتقال به سایت...')),
        );

        // باز کردن سایت
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      } else {
        // نمایش خطا
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('خطا در ورود به سایت. لطفاً دوباره تلاش کنید')),
        );
      }
    } catch (e) {
      print('خطا در ورود به سایت: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      icon: const Icon(Icons.web),
      label: const Text('ورود به سایت'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      ),
      onPressed: () => _loginToWordPress(context),
    );
  }
}
