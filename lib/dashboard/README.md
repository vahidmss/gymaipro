# Dashboard Module

این ماژول شامل اسکرین‌ها و ویجت‌های اصلی داشبورد اپلیکیشن است.

## ساختار فایل‌ها

### Screens
- `dashboard_screen.dart` - اسکرین اصلی داشبورد

### Widgets
- `dashboard_app_bar.dart` - AppBar سفارشی داشبورد
- `dashboard_drawer.dart` - Drawer سفارشی داشبورد
- `dashboard_loading_screen.dart` - صفحه بارگیری
- `dashboard_welcome.dart` - کارت خوشامدگویی
- `dashboard_welcome_helpers.dart` - توابع کمکی خوشامدگویی
- `fitness_metrics.dart` - معیارهای فیزیکی (BMI، Body Fat، BMR، TDEE)
- `latest_items_section.dart` - بخش آخرین آیتم‌ها
- `quick_shortcuts_grid.dart` - گرید میانبرها
- `weight_chart.dart` - نمودار وزن

## ویژگی‌ها

- **مدولار**: هر ویجت در فایل جداگانه
- **تم یکپارچه**: استفاده از AppTheme برای رنگ‌ها
- **Responsive**: پشتیبانی از اندازه‌های مختلف صفحه
- **بهینه‌شده**: کدهای اضافی حذف شده
- **قابل نگهداری**: ساختار تمیز و منظم

## استفاده

```dart
import 'package:gymaipro/dashboard/screens/dashboard_screen.dart';

// استفاده از اسکرین اصلی
Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const DashboardScreen()),
);
```