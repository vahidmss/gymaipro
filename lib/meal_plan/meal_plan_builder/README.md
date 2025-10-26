# Meal Plan Builder Module

ماژول Meal Plan Builder برای ساخت، ویرایش و مدیریت برنامه‌های غذایی (Meal Plan) توسط کاربر یا مربی طراحی شده است.

---

## ساختار پوشه‌ها

```
lib/meal_plan/meal_plan_builder/
├── dialogs/      # دیالوگ‌های مربوط به ساخت برنامه غذایی
├── models/       # مدل‌های داده‌ای (در صورت نیاز)
├── screens/      # صفحه اصلی ساخت برنامه غذایی
├── services/     # سرویس‌های business logic و ارتباط با دیتابیس
├── utils/        # توابع کمکی (محاسبات، فرمت‌بندی و ...)
├── widgets/      # ویجت‌های UI (کارت‌ها، نمودارها، سوییچ‌ها و ...)
└── README.md     # این فایل
```

---

## اجزای اصلی

### Dialogs
- `add_food_dialog.dart` - دیالوگ افزودن غذا به وعده
- `edit_food_dialog.dart` - ویرایش مقدار غذا
- `add_supplement_dialog.dart` - افزودن مکمل/دارو
- `food_alternatives_dialog.dart` - انتخاب جایگزین برای غذا
- `copy_day_dialog.dart` - کپی کردن یک روز به روزهای دیگر
- `meal_note_dialog.dart` - افزودن یادداشت به وعده

### Screens
- `meal_plan_builder_screen.dart` - صفحه اصلی ساخت و ویرایش برنامه غذایی

### Services
- `meal_plan_service.dart` - سرویس اصلی عملیات meal plan (ثبت، ویرایش، حذف و ...)

### Utils
- `meal_plan_utils.dart` - توابع کمکی (محاسبات تغذیه‌ای، فرمت تاریخ و ...)

### Widgets
- `meal_card.dart` - کارت نمایش و ویرایش وعده غذایی
- `supplement_card.dart` - کارت مکمل/دارو
- `app_bar.dart` - AppBar سفارشی برای meal plan builder
- `saved_plans_drawer.dart` - کشوی نمایش برنامه‌های ذخیره شده
- `meal_type_selector_overlay.dart` - انتخاب نوع وعده
- `meal_type_card.dart` - کارت نوع وعده
- `menu_option.dart` - گزینه‌های منو
- `macro_card.dart` - کارت نمایش ماکروها
- `daily_nutrition_bar.dart` - نمودار میله‌ای تغذیه روزانه
- `nutrition_tag.dart` - تگ تغذیه‌ای
- `widgets.dart` - export همه ویجت‌ها

---

## نحوه استفاده

### Import کردن
```dart
import 'package:your_app/meal_plan/meal_plan_builder/widgets/widgets.dart';
import 'package:your_app/meal_plan/meal_plan_builder/services/meal_plan_service.dart';
import 'package:your_app/meal_plan/meal_plan_builder/utils/meal_plan_utils.dart';
```

### استفاده از صفحه اصلی
```dart
import 'package:your_app/meal_plan/meal_plan_builder/screens/meal_plan_builder_screen.dart';

Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => MealPlanBuilderScreen()),
);
```

---

## ویژگی‌ها

- ساخت و ویرایش برنامه غذایی با رابط کاربری drag & drop یا دکمه‌های جابجایی
- افزودن، حذف و ویرایش وعده‌ها و مکمل‌ها
- کپی کردن روزها به یک یا چند روز دیگر
- مدیریت غذاهای جایگزین
- نمایش نمودار تغذیه‌ای و ماکروها
- ذخیره و بارگذاری برنامه‌های غذایی
- ساختار ماژولار و قابل نگهداری

---

## نکات مهم

- هر بخش (dialogs, widgets, ...) کاملاً جدا و مستقل است.
- هیچ کدی بین meal_plan_builder و meal_log به اشتراک گذاشته نمی‌شود.
- برای توسعه یا افزودن قابلیت جدید، فقط کافیست فایل مربوطه را در پوشه مناسب قرار دهید. 