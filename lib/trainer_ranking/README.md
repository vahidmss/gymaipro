# سیستم رتبه‌بندی مربیان (Trainer Ranking System)

این فولدر حاوی تمام کامپوننت‌های سیستم رتبه‌بندی و نمایش مربیان است. این سیستم به صورت ماژولار طراحی شده و شامل تمام ویژگی‌های مورد نیاز برای رتبه‌بندی هوشمند مربیان می‌باشد.

## ساختار فولدر

```
trainer_ranking/
├── models/                     # مدل‌های داده
│   └── trainer_ranking.dart    # مدل رتبه‌بندی مربیان
├── services/                   # سرویس‌ها و منطق کسب‌وکار
│   └── trainer_ranking_service.dart  # سرویس اصلی رتبه‌بندی
├── screens/                    # صفحات و رابط کاربری
│   └── enhanced_trainers_list_screen.dart  # صفحه لیست مربیان
├── widgets/                    # ویجت‌های قابل استفاده مجدد
│   ├── trainer_card_enhanced.dart         # کارت پیشرفته مربی
│   ├── trainer_search_filter_bar.dart     # نوار جستجو و فیلتر
│   └── trainer_ranking_demo.dart          # دمو سیستم
└── README.md                   # این فایل
```

## ویژگی‌های اصلی

### 🎯 الگوریتم رتبه‌بندی پیشرفته
- **امتیاز کلی (Overall Score)**: میانگین وزنی تمام معیارها
- **امتیاز نظرات (Rating Score)**: بر اساس ستاره‌ها و تعداد نظرات
- **امتیاز تجربه (Experience Score)**: بر اساس سابقه کاری
- **امتیاز مشتریان (Client Score)**: بر اساس تعداد مشتریان فعال
- **امتیاز فعالیت (Activity Score)**: بر اساس آخرین فعالیت
- **امتیاز پروفایل (Profile Score)**: بر اساس کامل بودن اطلاعات

### 🔍 سیستم جستجو و فیلتر
- جستجوی متنی پیشرفته
- فیلتر بر اساس تخصص
- فیلتر بر اساس امتیاز حداقل (1-5 ستاره)
- فیلتر بر اساس تجربه کاری
- فیلتر بر اساس محدوده قیمت

### 📊 گزینه‌های مرتب‌سازی
- رتبه کلی (پیش‌فرض)
- بالاترین امتیاز
- بیشترین تجربه
- بیشترین نظر
- بیشترین مشتری
- جدیدترین
- کمترین/بیشترین قیمت
- فعال‌ترین

## نحوه استفاده

### 1. نمایش لیست مربیان رتبه‌بندی شده
```dart
import 'package:gymaipro/trainer_ranking/screens/enhanced_trainers_list_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const EnhancedTrainersListScreen(),
  ),
);
```

### 2. استفاده از سرویس رتبه‌بندی
```dart
import 'package:gymaipro/trainer_ranking/services/trainer_ranking_service.dart';

final rankingService = TrainerRankingService();

final trainers = await rankingService.getRankedTrainers(
  sortBy: TrainerSortOption.overallScore,
  specialty: 'بدنسازی',
  minRating: 4.0,
  minExperience: 3,
  maxPrice: 200000,
);
```

### 3. نمایش کارت مربی پیشرفته
```dart
import 'package:gymaipro/trainer_ranking/widgets/trainer_card_enhanced.dart';

TrainerCardEnhanced(
  trainerProfile: trainerData['profile'],
  trainerRanking: TrainerRanking.fromJson(trainerData['ranking']),
  onTap: () => navigateToTrainerProfile(),
);
```

### 4. نمایش دمو سیستم
```dart
import 'package:gymaipro/trainer_ranking/widgets/trainer_ranking_demo.dart';

Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => const TrainerRankingDemo(),
  ),
);
```

## وابستگی‌ها

این ماژول به کتابخانه‌های زیر وابسته است:
- `supabase_flutter` برای ارتباط با دیتابیس
- `cached_network_image` برای نمایش تصاویر
- `flutter/material.dart` برای رابط کاربری

## نکات مهم

1. **بهینه‌سازی عملکرد**: سیستم از cache و pagination استفاده می‌کند
2. **امنیت**: تمام query‌ها از طریق Supabase انجام می‌شود
3. **قابل گسترش**: امکان اضافه کردن معیارهای جدید به راحتی
4. **UI/UX**: طراحی واکنش‌گرا و کاربرپسند
5. **پشتیبانی فارسی**: تمام متون به زبان فارسی

## دیتابیس

برای کارکرد صحیح سیستم، جداول زیر باید در Supabase وجود داشته باشند:
- `profiles` (مربیان)
- `trainer_details` (جزئیات مربیان)
- `trainer_reviews` (نظرات)
- `trainer_clients` (رابطه مربی-مشتری)

## توسعه و گسترش

### اضافه کردن معیار رتبه‌بندی جدید
1. در `TrainerRanking` فیلد جدید اضافه کنید
2. در `calculateOverallScore` محاسبه آن را اضافه کنید
3. در `_calculateTrainerRanking` منطق محاسبه را پیاده‌سازی کنید

### اضافه کردن گزینه مرتب‌سازی جدید
1. `TrainerSortOption` را گسترش دهید
2. در `_applySorting` منطق مرتب‌سازی را اضافه کنید

### سفارشی‌سازی ظاهر
- برای تغییر ظاهر کارت‌ها: `trainer_card_enhanced.dart`
- برای تغییر نوار جستجو: `trainer_search_filter_bar.dart`
- برای تغییر صفحه اصلی: `enhanced_trainers_list_screen.dart`

## عیب‌یابی

### مشکل: خطای اتصال به دیتابیس
**راه‌حل**: تنظیمات Supabase config را بررسی کنید

### مشکل: نمایش رتبه‌های اشتباه
**راه‌حل**: مطمئن شوید جداول دیتابیس به درستی ایجاد شده‌اند

### مشکل: عملکرد کند
**راه‌حل**: از pagination استفاده کنید و limit را کاهش دهید

## پشتیبانی

برای سوالات و مشکلات، لطفاً issue در repository پروژه ایجاد کنید یا با تیم توسعه تماس بگیرید.
