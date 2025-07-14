import 'package:flutter/material.dart';
import '../widgets/web_login_button.dart';
import '../theme/app_theme.dart';

class WebLoginScreen extends StatelessWidget {
  final String phoneNumber;

  const WebLoginScreen({Key? key, required this.phoneNumber}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ورود به سایت'),
      ),
      body: Center(
        child: Card(
          margin: const EdgeInsets.all(16.0),
          color: AppTheme.cardColor,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.language,
                  size: 64,
                  color: AppTheme.goldColor,
                ),
                const SizedBox(height: 24),
                const Text(
                  'ورود به سایت',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'با کلیک روی دکمه زیر، مرورگر باز می‌شود و شما به صورت خودکار در سایت وارد حساب کاربری خود می‌شوید.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 32),
                WebLoginButton(phoneNumber: phoneNumber),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    'بازگشت',
                    style: TextStyle(color: AppTheme.goldColor),
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
