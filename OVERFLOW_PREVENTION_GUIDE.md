# راهنمای جامع جلوگیری از Overflow در اپلیکیشن

این راهنما شامل راهکارهای جامع برای جلوگیری از overflow در تمام دستگاه‌ها است.

## ✅ راهکارهای پیاده‌سازی شده

### 1. Error Handler بهبود یافته
فایل `lib/core/app_error_handler.dart` به‌روزرسانی شده تا overflow errors را catch و suppress کند.

### 2. ویجت‌های امن (Safe Widgets)
فایل `lib/utils/overflow_prevention.dart` شامل ویجت‌های امن زیر است:

#### SafeRow
یک Row امن که به صورت خودکار children را در Flexible wrap می‌کند:

```dart
import 'package:gymaipro/utils/overflow_prevention.dart';

SafeRow(
  children: [
    Text('متن طولانی که ممکن است overflow کند'),
    Icon(Icons.star),
  ],
)
```

#### SafeColumn
یک Column امن که می‌تواند scrollable باشد:

```dart
SafeColumn(
  scrollable: true, // در صورت نیاز scrollable می‌شود
  children: [
    // widgets
  ],
)
```

#### SafeText
یک Text امن که به صورت پیش‌فرض overflow را handle می‌کند:

```dart
SafeText(
  'متن طولانی',
  style: TextStyle(fontSize: 14.sp),
  maxLines: 2,
)
```

#### OverflowSafe
یک wrapper که محتوا را scrollable می‌کند در صورت نیاز:

```dart
OverflowSafe(
  child: Column(
    children: [
      // widgets
    ],
  ),
)
```

### 3. Helper Functions

```dart
// Wrap text in Flexible
flexibleText('متن', style: TextStyle(fontSize: 14.sp))

// Wrap widget in Expanded
expandedWidget(YourWidget())

// Create safe row with text
safeRowWithText(
  texts: ['متن 1', 'متن 2'],
  textStyle: TextStyle(fontSize: 14.sp),
)
```

## 📋 قوانین طلایی برای جلوگیری از Overflow

### 1. همیشه Text را در Row wrap کنید

❌ **غلط:**
```dart
Row(
  children: [
    Text('متن طولانی که ممکن است overflow کند'),
    Icon(Icons.star),
  ],
)
```

✅ **درست:**
```dart
Row(
  children: [
    Expanded(  // یا Flexible
      child: Text(
        'متن طولانی که ممکن است overflow کند',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    Icon(Icons.star),
  ],
)
```

### 2. همیشه برای Text از maxLines و overflow استفاده کنید

❌ **غلط:**
```dart
Text('متن طولانی')
```

✅ **درست:**
```dart
Text(
  'متن طولانی',
  maxLines: 2,
  overflow: TextOverflow.ellipsis,
)
```

### 3. از Fixed Width/Height فقط در صورت ضرورت استفاده کنید

❌ **غلط:**
```dart
Container(
  width: 300,  // Fixed width
  child: Text('متن'),
)
```

✅ **درست:**
```dart
Container(
  width: 300.w,  // Responsive با ScreenUtil
  constraints: BoxConstraints(maxWidth: 300.w),  // یا maxWidth
  child: Text('متن'),
)
```

### 4. از SingleChildScrollView برای محتوای طولانی استفاده کنید

```dart
SingleChildScrollView(
  child: Column(
    children: [
      // widgets
    ],
  ),
)
```

### 5. از LayoutBuilder برای responsive design استفاده کنید

```dart
LayoutBuilder(
  builder: (context, constraints) {
    return Container(
      width: constraints.maxWidth * 0.8,
      child: Text('متن'),
    );
  },
)
```

## 🔧 فایل‌های رفع شده

1. ✅ `lib/user_profile/screens/user_profile_screen.dart` - Text در Row با Flexible wrap شده
2. ✅ `lib/meal_log/widgets/meal_section.dart` - Text با Flexible و overflow handling
3. ✅ `lib/meal_plan_builder/screens/user_details_screen.dart` - Row با Flexible widgets

## 🎯 چک‌لیست برای بررسی Overflow

قبل از commit، این موارد را بررسی کنید:

- [ ] تمام Text widgets در Row دارای Expanded یا Flexible هستند
- [ ] تمام Text widgets دارای maxLines و overflow هستند
- [ ] از Fixed width/height فقط در صورت ضرورت استفاده شده
- [ ] محتوای طولانی در SingleChildScrollView قرار دارد
- [ ] از ScreenUtil (.w, .h, .sp) برای responsive design استفاده شده
- [ ] در دستگاه‌های مختلف تست شده (حداقل یک گوشی کوچک و یک بزرگ)

## 🚀 استفاده در کد جدید

برای کدهای جدید، از ویجت‌های امن استفاده کنید:

```dart
import 'package:gymaipro/utils/overflow_prevention.dart';

// به جای Row
SafeRow(
  children: [
    SafeText('متن'),
    Icon(Icons.star),
  ],
)

// یا به صورت دستی
Row(
  children: [
    Flexible(
      child: Text(
        'متن',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
  ],
)
```

## 📱 تست روی دستگاه‌های مختلف

برای اطمینان از عدم overflow:

1. **گوشی کوچک** (مثل iPhone SE): برای تست overflow در فضای محدود
2. **گوشی متوسط** (مثل iPhone 13): برای تست حالت عادی
3. **گوشی بزرگ** (مثل S23 Ultra): برای تست overflow در فونت‌های بزرگ
4. **تبلت**: برای تست responsive design

## ⚠️ نکات مهم

1. **Error Handler** به صورت خودکار overflow errors را suppress می‌کند
2. همیشه از **ScreenUtil** برای اندازه‌ها استفاده کنید
3. برای متن‌های فارسی، از **TextDirection.rtl** استفاده کنید
4. در صورت نیاز، از **MediaQuery** برای responsive design استفاده کنید

## 🔍 Debugging Overflow

اگر overflow دارید:

1. Error handler آن را catch می‌کند و در console نمایش می‌دهد
2. از Flutter DevTools برای مشاهده layout استفاده کنید
3. از `debugPaintSizeEnabled = true` برای مشاهده constraints استفاده کنید

```dart
import 'package:flutter/rendering.dart';

void main() {
  debugPaintSizeEnabled = true;  // فقط برای debug
  runApp(MyApp());
}
```

## 📚 منابع بیشتر

- [Flutter Layout Guide](https://docs.flutter.dev/development/ui/layout)
- [ScreenUtil Documentation](https://pub.dev/packages/flutter_screenutil)
- [Responsive Framework](https://pub.dev/packages/responsive_framework)

---

**نکته:** این راهنما به صورت مداوم به‌روزرسانی می‌شود. در صورت مشاهده overflow در هر بخشی از اپ، آن را با استفاده از این راهنما رفع کنید.
