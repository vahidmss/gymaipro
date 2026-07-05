import 'package:flutter/material.dart';
import 'package:gymaipro/guide/models/guide_sequence.dart';
import 'package:gymaipro/guide/models/guide_step.dart';
import 'package:gymaipro/theme/app_theme.dart';

/// محتوای راهنمای Dashboard
class DashboardGuideData {
  /// GlobalKeys برای المنت‌های داشبورد که باید highlight شوند
  static final Map<String, GlobalKey> keys = {
    'welcome_card': GlobalKey(),
    'fitness_metrics': GlobalKey(),
    'weight_chart': GlobalKey(),
    'quick_actions': GlobalKey(),
    'todays_program': GlobalKey(),
    'exercises_tabs': GlobalKey(),
    'drawer_menu': GlobalKey(),
  };

  static Map<String, GlobalKey> _resolveKeys(Map<String, GlobalKey>? overrides) {
    return overrides ?? keys;
  }

  /// راهنمای کامل داشبورد
  static GuideSequence getDashboardGuide({Map<String, GlobalKey>? keyOverrides}) {
    final resolvedKeys = _resolveKeys(keyOverrides);
    return GuideSequence(
      id: 'dashboard_main_tour',
      name: 'راهنمای داشبورد',
      description: 'آشنایی با امکانات اصلی داشبورد',
      steps: [
        // مرحله ۱: خوش آمدگویی
        const GuideStep(
          id: 'welcome_intro',
          title: '👋 به داشبورد خوش آمدید!',
          description:
              'این صفحه قلب تپنده اپلیکیشن شماست!\nاز اینجا می‌تونید به تمام امکانات دسترسی داشته باشید و پیشرفت‌تون رو ببینید.',
          icon: Icons.dashboard,
          primaryColor: AppTheme.goldColor,
          tooltipPosition: TooltipPosition.center,
        ),

        // مرحله ۲: کارت خوش‌آمدگویی
        GuideStep(
          id: 'welcome_card',
          title: 'اطلاعات شخصی شما',
          description:
              'اینجا اطلاعات پروفایل و پیام‌های انگیزشی روزانه نمایش داده می‌شود.\nروی کارت کلیک کنید تا به پروفایل برید.',
          icon: Icons.person,
          primaryColor: AppTheme.goldColor,
          targetKey: resolvedKeys['welcome_card'],
        ),

        // مرحله ۳: معیارهای فیزیکی
        GuideStep(
          id: 'fitness_metrics',
          title: '📊 معیارهای فیتنس',
          description:
              'BMI، کالری مورد نیاز روزانه و وضعیت فیزیکی شما.\nاین اطلاعات بر اساس پروفایل شما محاسبه می‌شود.',
          icon: Icons.assessment,
          primaryColor: const Color(0xFF26C281),
          targetKey: resolvedKeys['fitness_metrics'],
        ),

        // مرحله ۴: نمودار وزن
        GuideStep(
          id: 'weight_chart',
          title: '📈 نمودار وزن',
          description:
              'پیگیری تغییرات وزن شما در طول زمان.\nبا ضربه روی نمودار می‌تونید وزن جدید اضافه کنید.',
          icon: Icons.show_chart,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: resolvedKeys['weight_chart'],
        ),

        // مرحله ۵: دکمه‌های سریع
        GuideStep(
          id: 'quick_actions',
          title: '⚡ دکمه‌های سریع',
          description:
              'دسترسی سریع به مهم‌ترین بخش‌ها:\n• ساخت برنامه تمرینی\n• مربیان حرفه‌ای\n• دستاوردهای شما',
          icon: Icons.bolt,
          primaryColor: const Color(0xFFFF6B6B),
          targetKey: resolvedKeys['quick_actions'],
        ),

        // مرحله ۶: برنامه امروز
        GuideStep(
          id: 'todays_program',
          title: '💪 برنامه امروز',
          description:
              'برنامه تمرینی امروز شما اینجا نمایش داده می‌شود.\nروی هر تمرین ضربه بزنید تا اطلاعات بیشتر ببینید.',
          icon: Icons.today,
          primaryColor: AppTheme.goldColor,
          targetKey: resolvedKeys['todays_program'],
        ),

        // مرحله ۷: تب‌های تمرینات و تغذیه
        GuideStep(
          id: 'exercises_tabs',
          title: '🏋️ تمرینات و تغذیه',
          description:
              'از اینجا می‌تونید تمرینات و غذاهای مختلف رو ببینید.\nبه لیست علاقه‌مندی‌ها اضافه کنید و جزئیات هر کدوم رو بخونید.',
          icon: Icons.restaurant_menu,
          primaryColor: const Color(0xFFF39C12),
          targetKey: resolvedKeys['exercises_tabs'],
          tooltipPosition: TooltipPosition.top,
        ),

        // مرحله ۸: منوی کشویی
        GuideStep(
          id: 'drawer_menu',
          title: '📱 منوی اصلی',
          description:
              'با کلیک روی این دکمه (یا کشیدن از سمت راست صفحه)، منوی اصلی باز می‌شود.\nاز اونجا به تمام بخش‌های اپ دسترسی دارید:\n• پروفایل\n• برنامه‌های من\n• کیف پول\n• چت و اجتماعی\n• تنظیمات\nو...',
          icon: Icons.menu,
          primaryColor: AppTheme.goldColor,
          targetKey: resolvedKeys['drawer_menu'], // Key به دکمه menu در AppBar
          tooltipPosition: TooltipPosition.right,
        ),

        // مرحله آخر: تمام شد!
        const GuideStep(
          id: 'tour_complete',
          title: '🎉 آفرین! همه چیز رو یاد گرفتید',
          description:
              'حالا می‌تونید از تمام امکانات اپ استفاده کنید!\n\nاگر بعدا نیاز به راهنمایی داشتید، از منو > راهنما می‌تونید دوباره این تور رو ببینید.\n\nموفق باشید! 💪',
          icon: Icons.check_circle,
          primaryColor: Color(0xFF26C281),
          tooltipPosition: TooltipPosition.center,
          usePulseAnimation: false,
        ),
      ],
    );
  }

  /// راهنمای کوتاه برای ساخت برنامه
  static GuideSequence getProgramBuilderGuide() {
    return const GuideSequence(
      id: 'program_builder_guide',
      name: 'راهنمای ساخت برنامه',
      description: 'نحوه ساخت برنامه تمرینی یا غذایی',
      steps: [
        GuideStep(
          id: 'choose_program_type',
          title: '🏋️ نوع برنامه را انتخاب کنید',
          description:
              'ابتدا مشخص کنید که می‌خواهید برنامه تمرینی بسازید یا برنامه غذایی.\n\nهر کدوم مراحل خاص خودش رو داره.',
          icon: Icons.category,
          primaryColor: AppTheme.goldColor,
          tooltipPosition: TooltipPosition.center,
        ),

        GuideStep(
          id: 'answer_questions',
          title: '📝 به سوالات پاسخ دهید',
          description:
              'هوش مصنوعی چند سوال درباره اهداف، تجربه و شرایط فیزیکی شما می‌پرسه.\n\nهر چی دقیق‌تر جواب بدید، برنامه بهتری دریافت می‌کنید!',
          icon: Icons.quiz,
          primaryColor: Color(0xFF6C63FF),
          tooltipPosition: TooltipPosition.center,
        ),

        GuideStep(
          id: 'ai_generates',
          title: '🤖 ساخت برنامه با هوش مصنوعی',
          description:
              'هوش مصنوعی بر اساس پاسخ‌های شما، یک برنامه کاملا شخصی‌سازی شده می‌سازه.\n\nممکنه چند لحظه طول بکشه، صبور باشید!',
          icon: Icons.auto_awesome,
          primaryColor: Color(0xFFFF6B6B),
          tooltipPosition: TooltipPosition.center,
        ),

        GuideStep(
          id: 'review_program',
          title: '✅ بررسی و تایید',
          description:
              'برنامه ساخته شده رو بررسی کنید.\nاگر نیاز به تغییر داشت، می‌تونید ویرایش کنید یا دوباره بسازید.\n\nوقتی راضی بودید، برنامه رو فعال کنید!',
          icon: Icons.check_circle,
          primaryColor: Color(0xFF26C281),
          tooltipPosition: TooltipPosition.center,
        ),
      ],
    );
  }

  /// راهنمای کوتاه برای ثبت وزن
  static GuideSequence getWeightTrackingGuide({Map<String, GlobalKey>? keyOverrides}) {
    final resolvedKeys = _resolveKeys(keyOverrides);
    return GuideSequence(
      id: 'weight_tracking_guide',
      name: 'راهنمای ثبت وزن',
      description: 'نحوه ثبت و پیگیری وزن',
      showOnce: false, // این راهنما می‌تونه چند بار نمایش داده بشه
      steps: [
        GuideStep(
          id: 'tap_chart',
          title: '📊 روی نمودار ضربه بزنید',
          description:
              'برای افزودن وزن جدید، روی نمودار وزن ضربه بزنید.',
          icon: Icons.touch_app,
          primaryColor: const Color(0xFF6C63FF),
          targetKey: resolvedKeys['weight_chart'],
        ),

        const GuideStep(
          id: 'enter_weight',
          title: '⚖️ وزن خود را وارد کنید',
          description:
              'وزن فعلی خود را به کیلوگرم وارد کنید.\n\nبهتر است همیشه در یک زمان ثابت (مثلا صبح قبل از صبحانه) وزن کنید.',
          icon: Icons.edit,
          primaryColor: AppTheme.goldColor,
          tooltipPosition: TooltipPosition.center,
        ),

        const GuideStep(
          id: 'track_progress',
          title: '📈 پیشرفت را ببینید',
          description:
              'وزن‌های ثبت شده در نمودار نمایش داده می‌شود.\n\nمی‌تونید روند تغییرات وزنتون رو در طول زمان ببینید.',
          icon: Icons.trending_up,
          primaryColor: Color(0xFF26C281),
          tooltipPosition: TooltipPosition.center,
        ),
      ],
    );
  }
}

