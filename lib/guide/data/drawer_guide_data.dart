import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/guide_sequence.dart';
import 'package:gymaipro/guide/models/guide_step.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// راهنمای Drawer
class DrawerGuideData {
  /// GlobalKeys برای المنت‌های drawer
  static final Map<String, GlobalKey> keys = {
    'drawer_header': GlobalKey(),
    'menu_home': GlobalKey(),
    'menu_my_club': GlobalKey(),
    'menu_trainer_dashboard': GlobalKey(),
    'menu_notifications': GlobalKey(),
    'menu_settings': GlobalKey(),
    'menu_referral': GlobalKey(),
    'menu_help': GlobalKey(),
    'menu_guide_tour': GlobalKey(),
    'menu_logout': GlobalKey(),
  };

  /// راهنمای کامل برای Drawer
  static GuideSequence getDrawerGuide() {
    return GuideSequence(
      id: 'drawer_guide',
      name: 'راهنمای منو',
      description: 'آشنایی با منوی اصلی',
      steps: [
        // مرحله ۱: معرفی
        const GuideStep(
          id: 'drawer_intro',
          title: '📱 منوی اصلی',
          description:
              'به منوی اصلی خوش آمدید!\nاز اینجا می‌تونید به تمام بخش‌های اپ دسترسی داشته باشید.',
          icon: Icons.menu,
          primaryColor: AppTheme.goldColor,
          tooltipPosition: TooltipPosition.center,
          usePulseAnimation: false,
        ),

        // مرحله ۲: هدر (پروفایل و کیف پول)
        GuideStep(
          id: 'drawer_header',
          title: '👤 پروفایل و کیف پول',
          description:
              'اینجا اطلاعات پروفایل و موجودی کیف پول شما نمایش داده می‌شود.\nروی کیف پول کلیک کنید تا به صفحه کیف پول برید.',
          icon: Icons.account_circle,
          primaryColor: AppTheme.goldColor,
          targetKey: keys['drawer_header'],
        ),

        // مرحله ۳: خانه
        GuideStep(
          id: 'menu_home',
          title: '🏠 خانه',
          description:
              'بازگشت به صفحه اصلی داشبورد.\nاز اینجا می‌تونید به تمام بخش‌های اصلی دسترسی داشته باشید.',
          icon: Icons.home,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: keys['menu_home'],
          tooltipPosition: TooltipPosition.right,
        ),

        // مرحله ۴: باشگاه من
        GuideStep(
          id: 'menu_my_club',
          title: '👥 باشگاه من',
          description:
              'برنامه‌های تمرینی و غذایی شما، مربیان و دوستان.\nهمه چیز مربوط به باشگاه شما اینجاست!',
          icon: Icons.group,
          primaryColor: const Color(0xFF26C281),
          targetKey: keys['menu_my_club'],
          tooltipPosition: TooltipPosition.right,
        ),

        // مرحله ۵: میز کار مربی (اگر مربی باشد)
        GuideStep(
          id: 'menu_trainer_dashboard',
          title: '💼 میز کار مربی',
          description:
              'اگر مربی هستید، از اینجا می‌تونید به میز کار مربی دسترسی داشته باشید.\nمدیریت شاگردان، برنامه‌ها و درآمد.',
          icon: Icons.work,
          primaryColor: const Color(0xFFFF6B6B),
          targetKey: keys['menu_trainer_dashboard'],
          tooltipPosition: TooltipPosition.right,
        ),

        // مرحله ۶: تنظیمات اعلان‌ها
        GuideStep(
          id: 'menu_notifications',
          title: '🔔 تنظیمات اعلان‌ها',
          description:
              'مدیریت اعلان‌های اپ.\nمشخص کنید چه نوع اعلان‌هایی دریافت کنید.',
          icon: Icons.notifications,
          primaryColor: const Color(0xFFF39C12),
          targetKey: keys['menu_notifications'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۷: تنظیمات عمومی
        GuideStep(
          id: 'menu_settings',
          title: '⚙️ تنظیمات عمومی',
          description:
              'تنظیمات کلی اپ، تم، زبان و سایر گزینه‌ها.\nهر چیزی که می‌خواید تغییر بدید اینجاست!',
          icon: Icons.settings,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: keys['menu_settings'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۸: دعوت دوستان
        GuideStep(
          id: 'menu_referral',
          title: '🎁 دعوت دوستان',
          description:
              'دوستانتون رو دعوت کنید و پاداش بگیرید!\nبا هر دعوت موفق، امتیاز و جایزه دریافت می‌کنید.',
          icon: Icons.card_giftcard,
          primaryColor: const Color(0xFF26C281),
          targetKey: keys['menu_referral'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۹: راهنما
        GuideStep(
          id: 'menu_help',
          title: '❓ راهنما',
          description:
              'سوالی دارید؟ اینجا جواب پیدا می‌کنید!\nراهنمای کامل استفاده از اپ.',
          icon: Icons.help_outline,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: keys['menu_help'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۱۰: تور راهنما
        GuideStep(
          id: 'menu_guide_tour',
          title: '🗺️ تور راهنمای داشبورد',
          description:
              'می‌خواید دوباره راهنمای داشبورد رو ببینید؟\nاز اینجا می‌تونید تور راهنما رو دوباره شروع کنید.',
          icon: Icons.route,
          primaryColor: AppTheme.goldColor,
          targetKey: keys['menu_guide_tour'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۱۱: خروج
        GuideStep(
          id: 'menu_logout',
          title: '🚪 خروج از حساب',
          description:
              'برای خروج از حساب کاربری از این گزینه استفاده کنید.\nهمه اطلاعات شما امن باقی می‌مونه!',
          icon: Icons.logout,
          primaryColor: const Color(0xFFFF6B6B),
          targetKey: keys['menu_logout'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله آخر
        const GuideStep(
          id: 'drawer_complete',
          title: '✅ تمام شد!',
          description:
              'حالا با منوی اصلی آشنا شدید!\nهر وقت نیاز داشتید، از سمت راست صفحه بکشید تا منو باز بشه.',
          icon: Icons.check_circle,
          primaryColor: Color(0xFF26C281),
          tooltipPosition: TooltipPosition.center,
          usePulseAnimation: false,
        ),
      ],
    );
  }
}

