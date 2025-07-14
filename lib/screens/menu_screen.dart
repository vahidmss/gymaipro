import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'web_login_screen.dart';

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  // اضافه کردن یک آیتم منو برای ورود به سایت
  Widget _buildWebLoginMenuItem(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        leading: const Icon(Icons.language, color: AppTheme.goldColor),
        title: const Text('ورود به سایت'),
        subtitle: const Text('انتقال خودکار به سایت با حساب کاربری شما'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () async {
          final user = Supabase.instance.client.auth.currentUser;
          if (user != null) {
            // دریافت شماره موبایل کاربر
            try {
              final profile = await Supabase.instance.client
                  .from('profiles')
                  .select('phone_number')
                  .eq('id', user.id)
                  .single();

              final phoneNumber = profile['phone_number'] as String?;

              if (phoneNumber != null && phoneNumber.isNotEmpty) {
                if (!context.mounted) return;
                // باز کردن پاپ‌آپ تأیید
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('ورود به سایت'),
                    content: const Text(
                        'شما در حال انتقال به سایت هستید. این صفحه در مرورگر باز خواهد شد و به طور خودکار وارد حساب کاربری شما می‌شود.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('انصراف'),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                          // استفاده از دکمه ورود به سایت
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  WebLoginScreen(phoneNumber: phoneNumber),
                            ),
                          );
                        },
                        child: const Text('ادامه'),
                      ),
                    ],
                  ),
                );
              } else {
                // نمایش خطا
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text(
                          'شماره موبایل شما یافت نشد. لطفاً با پشتیبانی تماس بگیرید.')),
                );
              }
            } catch (e) {
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('خطا در دریافت اطلاعات: $e')),
              );
            }
          } else {
            // نمایش خطا
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('ابتدا وارد حساب کاربری خود شوید.')),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('منوی اصلی'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          // اضافه کردن گزینه ورود به سایت
          _buildWebLoginMenuItem(context),

          // سایر گزینه‌های منو
          // ...
        ],
      ),
    );
  }
}
