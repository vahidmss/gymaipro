import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/guide_sequence.dart';
import 'package:gymaipro/guide/models/guide_step.dart';

/// محتوای راهنمای Meal Log (کالری‌شمار)
class MealLogGuideData {
  /// GlobalKeys برای المنت‌های meal log که باید highlight شوند
  static final Map<String, GlobalKey> keys = {
    'calorie_summary': GlobalKey(),
    'date_picker': GlobalKey(),
    'breakfast_section': GlobalKey(),
  };

  /// راهنمای کامل کالری‌شمار
  static GuideSequence getMealLogGuide() {
    return GuideSequence(
      id: 'meal_log_tour',
      name: 'راهنمای کالری‌شمار',
      description: 'آشنایی با امکانات کالری‌شمار',
      showOnce: true,
      steps: [
        // مرحله ۱: خلاصه کالری
        GuideStep(
          id: 'calorie_summary',
          title: '📊 خلاصه کالری روزانه',
          description:
              'اینجا می‌بینید که چند کالری مصرف کرده‌اید و چند درصد از هدف روزانه شما رو پوشش داده.\nنمودار دایره‌ای پیشرفت شما رو نشون می‌ده.\n\nکالری باقیمانده هم نمایش داده می‌شه تا بدونید چقدر دیگه می‌تونید بخورید!',
          icon: Icons.pie_chart,
          primaryColor: const Color(0xFF26C281),
          targetKey: keys['calorie_summary'],
          tooltipPosition: TooltipPosition.bottom,
          usePulseAnimation: true,
        ),

        // مرحله ۲: انتخاب تاریخ
        GuideStep(
          id: 'date_picker',
          title: '📅 انتخاب تاریخ',
          description:
              'با کلیک روی این آیکون، می‌تونید تاریخ‌های مختلف رو انتخاب کنید.\n\nمی‌تونید کالری روزهای گذشته رو ببینید یا برای آینده برنامه ریزی کنید.\n\nتاریخ‌هایی که کالری ثبت شده با رنگ مشخص می‌شن.',
          icon: Icons.calendar_today,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: keys['date_picker'],
          tooltipPosition: TooltipPosition.left,
          usePulseAnimation: true,
        ),

        // مرحله ۳: بخش وعده‌های غذایی
        GuideStep(
          id: 'breakfast_section',
          title: '🍽️ وعده‌های غذایی',
          description:
              'هر وعده یک محدوده کالری پیشنهادی داره (مثلاً 200 تا 400 کالری).\n\nاین محدوده بر اساس کالری مجاز روزانه شما محاسبه می‌شه و به شما کمک می‌کنه تا تغذیه متعادل داشته باشید.\n\nبرای ثبت غذا، روی دکمه + در کنار هر وعده کلیک کنید.',
          icon: Icons.restaurant,
          primaryColor: const Color(0xFFF39C12),
          targetKey: keys['breakfast_section'],
          tooltipPosition: TooltipPosition.bottom,
          usePulseAnimation: true,
        ),
      ],
    );
  }
}

