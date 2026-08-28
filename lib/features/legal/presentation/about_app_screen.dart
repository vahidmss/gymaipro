import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:gymaipro/config/app_config.dart';
import 'package:gymaipro/features/legal/legal_copy.dart';
import 'package:gymaipro/theme/app_theme.dart';
import 'package:gymaipro/utils/support_launcher.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

/// صفحه درباره — معرفی GymAI Pro + بازخورد + تماس مستقیم.
class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  static const _phone = LegalCopy.supportPhoneRaw;

  Future<void> _call(BuildContext context) async {
    final uri = Uri(scheme: 'tel', path: _phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    await SupportLauncher.openPhone(context);
  }

  Future<void> _smsFeedback(BuildContext context) async {
    final body = Uri.encodeComponent(LegalCopy.feedbackSmsBody);
    final uri = Uri.parse('sms:$_phone?body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      return;
    }
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'پیامک باز نشد — مستقیم با همین شماره تماس بگیر',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      ),
    );
  }

  Future<void> _copyPhone(BuildContext context) async {
    await Clipboard.setData(const ClipboardData(text: _phone));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'شماره کپی شد',
          style: TextStyle(fontFamily: AppTheme.fontFamily),
        ),
      ),
    );
  }

  Future<void> _openTelegram(BuildContext context) async {
    await SupportLauncher.openTelegram(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final telegram = AppConfig.supportTelegram.trim();

    return Directionality(
      textDirection: TextDirection.rtl,
      child: DecoratedBox(
        decoration: context.pageDecoration,
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor:
                isDark ? context.backgroundColor : Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Icon(
                LucideIcons.arrowRight,
                color: isDark ? AppTheme.goldColor : context.textColor,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              LegalCopy.aboutTitle,
              style: TextStyle(
                fontFamily: AppTheme.fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: 18.sp,
                color: isDark ? AppTheme.goldColor : context.textColor,
              ),
            ),
          ),
          body: ListView(
            padding: EdgeInsets.fromLTRB(20.w, 8.h, 20.w, 32.h),
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: AppTheme.goldColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14.r),
                  border: Border.all(
                    color: AppTheme.goldColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      LucideIcons.sparkles,
                      color: AppTheme.goldColor,
                      size: 22.sp,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'GymAI Pro برای تمرین واقعی طراحی شده: برنامه، جلسه زنده، '
                        'مربی هوشمند و پرداخت امن با زیبال. نظرت مسیر بهتر شدن را می‌سازد.',
                        style: TextStyle(
                          fontFamily: AppTheme.fontFamily,
                          fontSize: 13.sp,
                          height: 1.55,
                          fontWeight: FontWeight.w600,
                          color: context.textColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 20.h),
              Text(
                'GymAI Pro چیست؟',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'اپ تمرین و تغذیه: برنامه می‌سازد، تمرین امروز را نشان می‌دهد، '
                'حین جلسه کنارت است و بعد از تمرین جمع‌بندی می‌دهد. '
                'مربی هوشمند و مربیان انسانی هم اینجا هستند.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  height: 1.75,
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 22.h),
              Text(
                'ازت چه می‌خواهیم؟',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontWeight: FontWeight.w800,
                  fontSize: 16.sp,
                  color: context.textColor,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'بگو کجا گیر کردی، چه چیزی گیج‌کننده بود، چه چیزی را دوست داشتی، '
                'و چه چیزی کم است. حتی یک جمله هم کافیست.',
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 14.sp,
                  height: 1.75,
                  color: context.textSecondary,
                ),
              ),
              SizedBox(height: 18.h),
              _ActionTile(
                icon: LucideIcons.messageSquarePlus,
                title: 'ارسال بازخورد با پیامک',
                subtitle: 'انتقاد، باگ، پیشنهاد',
                onTap: () => _smsFeedback(context),
              ),
              SizedBox(height: 10.h),
              _ActionTile(
                icon: LucideIcons.phone,
                title: 'تماس مستقیم',
                subtitle: LegalCopy.supportPhoneDisplay,
                onTap: () => _call(context),
                onLongPress: () => _copyPhone(context),
              ),
              if (telegram.isNotEmpty) ...[
                SizedBox(height: 10.h),
                _ActionTile(
                  icon: LucideIcons.send,
                  title: 'تلگرام',
                  subtitle: SupportLauncher.telegramDisplayHandle,
                  onTap: () => _openTelegram(context),
                ),
              ],
              SizedBox(height: 24.h),
              Text(
                'نسخه ۱.۰.۰ · GymAI Pro',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppTheme.fontFamily,
                  fontSize: 12.sp,
                  color: context.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(14.r),
        child: Ink(
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: context.cardColor,
            borderRadius: BorderRadius.circular(14.r),
            border: Border.all(color: context.separatorColor),
          ),
          child: Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: context.actionFill.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Icon(icon, size: 20.sp, color: context.inkAccent),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontWeight: FontWeight.w700,
                        fontSize: 14.sp,
                        color: context.textColor,
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontFamily: AppTheme.fontFamily,
                        fontSize: 12.sp,
                        color: context.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                LucideIcons.chevronLeft,
                size: 16.sp,
                color: context.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
