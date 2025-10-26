# Dashboard Module

این ماژول شامل تمام کامپوننت‌ها و صفحات مربوط به داشبورد اصلی اپلیکیشن است.

## ساختار فایل‌ها

```
lib/dashboard/
├── screens/           # صفحات اصلی داشبورد
│   └── dashboard_screen.dart
├── widgets/           # کامپوننت‌های قابل استفاده مجدد
│   ├── dashboard_analytics.dart
│   ├── dashboard_nav.dart
│   ├── dashboard_profile.dart
│   ├── dashboard_welcome.dart
│   ├── dashboard_workout.dart
│   ├── fitness_metrics.dart
│   ├── latest_items_section.dart
│   ├── meal_planning_section.dart
│   ├── quick_actions_section.dart
│   ├── stats_grid.dart
│   └── weight_height_display.dart
├── services/          # سرویس‌های مربوط به داشبورد
│   ├── analytics_service.dart
│   └── achievement_service.dart
├── models/           # مدل‌های داده
├── utils/            # توابع کمکی
└── README.md         # این فایل
```

## کامپوننت‌های اصلی

### Screens
- **dashboard_screen.dart**: صفحه اصلی داشبورد با تب‌های مختلف

### Widgets
- **achievements_section.dart**: بخش دستاوردها
- **dashboard_analytics.dart**: بخش آنالیز و آمار
- **dashboard_nav.dart**: ناوبری پایین صفحه
- **dashboard_profile.dart**: بخش پروفایل کاربر
- **dashboard_welcome.dart**: کارت خوش‌آمدگویی
- **dashboard_workout.dart**: بخش تمرینات
- **fitness_metrics.dart**: متریک‌های تناسب اندام
- **latest_items_section.dart**: آخرین آیتم‌ها
- **meal_planning_section.dart**: بخش برنامه غذایی
- **quick_actions_section.dart**: اقدامات سریع
- **stats_grid.dart**: شبکه آمار
- **weight_height_display.dart**: نمایش وزن و قد

### Services
- **analytics_service.dart**: سرویس آنالیز و آمار تمرینات
- **achievement_service.dart**: سرویس مدیریت دستاوردها

## نحوه استفاده

```dart
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';

// استفاده در route
MaterialPageRoute(
  builder: (context) => const DashboardScreen(),
)
```

## ویژگی‌ها

- **انیمیشن‌های نرم**: انیمیشن‌های fade و slide
- **تب‌های مختلف**: خانه، تمرینات، آنالیز، پروفایل
- **Pull to Refresh**: امکان به‌روزرسانی داده‌ها
- **Responsive Design**: طراحی واکنش‌گرا
- **Safe State Management**: مدیریت امن state با SafeSetState

## وابستگی‌ها

- `package:flutter/material.dart`
- `package:lucide_icons/lucide_icons.dart`
- `package:supabase_flutter/supabase_flutter.dart`
- `package:gymaipro/services/supabase_service.dart`
- `package:gymaipro/theme/app_theme.dart`
- `package:gymaipro/utils/safe_set_state.dart` 