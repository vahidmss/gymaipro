import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/onboarding_page.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// محتوای صفحات Onboarding
class OnboardingData {
  static List<OnboardingPage> getPages() {
    return [
      // صفحه ۱: خوش آمدگویی
      OnboardingPage(
        id: 'welcome',
        title: 'به جیم‌ای‌آی پرو خوش آمدید!',
        description:
            'دستیار هوشمند شما برای دستیابی به بهترین فرم فیزیکی.\nبرنامه‌های تمرینی و تغذیه‌ای شخصی‌سازی شده با هوش مصنوعی.',
        icon: Icons.fitness_center,
        primaryColor: AppTheme.goldColor,
        gradientStartColor: const Color(0xFF1a1a2e),
        gradientEndColor: const Color(0xFF16213e),
      ),

      // صفحه ۲: برنامه‌سازی هوشمند
      OnboardingPage(
        id: 'ai_programs',
        title: 'برنامه‌های هوشمند',
        description:
            'با هوش مصنوعی، برنامه تمرینی و رژیم غذایی کاملا متناسب با شرایط و اهداف شما طراحی می‌شود.\nفقط کافیست چند سوال ساده جواب دهید!',
        icon: Icons.auto_awesome,
        primaryColor: const Color(0xFF6C63FF),
        gradientStartColor: const Color(0xFF667eea),
        gradientEndColor: const Color(0xFF764ba2),
      ),

      // صفحه ۳: پیگیری پیشرفت
      OnboardingPage(
        id: 'progress_tracking',
        title: 'پیگیری دقیق پیشرفت',
        description:
            'وزن، اندازه‌ها، کالری و تمام پیشرفت‌های خود را ثبت کنید.\nنمودارها و آمارهای دقیق به شما کمک می‌کند همیشه در مسیر درست باشید.',
        icon: Icons.trending_up,
        primaryColor: const Color(0xFF26C281),
        gradientStartColor: const Color(0xFF11998e),
        gradientEndColor: const Color(0xFF38ef7d),
      ),

      // صفحه ۴: مربیان حرفه‌ای
      OnboardingPage(
        id: 'trainers',
        title: 'مربیان حرفه‌ای',
        description:
            'دسترسی به بهترین مربیان فیتنس و تغذیه.\nچت خصوصی، مشاوره آنلاین و برنامه‌های اختصاصی.',
        icon: Icons.groups,
        primaryColor: const Color(0xFFFF6B6B),
        gradientStartColor: const Color(0xFFee0979),
        gradientEndColor: const Color(0xFFff6a00),
      ),

      // صفحه ۵: آکادمی و آموزش
      OnboardingPage(
        id: 'academy',
        title: 'آکادمی آموزشی',
        description:
            'دسترسی به صدها ویدیو آموزشی تکنیک تمرینات و تغذیه ورزشی.\nهمه چیز که برای موفقیت نیاز دارید!',
        icon: Icons.school,
        primaryColor: const Color(0xFFF39C12),
        gradientStartColor: const Color(0xFFf2994a),
        gradientEndColor: const Color(0xFFf2c94c),
      ),

      // صفحه ۶: شروع کنیم
      OnboardingPage(
        id: 'ready',
        title: 'آماده‌اید؟',
        description:
            'همه چیز برای شروع سفر تناسب اندام شما آماده است!\nبیایید با هم بهترین نسخه از خودتان را بسازیم! 💪',
        icon: Icons.rocket_launch,
        primaryColor: AppTheme.goldColor,
        gradientStartColor: const Color(0xFFda22ff),
        gradientEndColor: const Color(0xFF9733ee),
      ),
    ];
  }
}

