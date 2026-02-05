# راهنمای جامع تست Overflow

این راهنما شامل تمام ابزارها و روش‌های تست overflow در اپلیکیشن است.

## 📦 ابزارهای ایجاد شده

### 1. Overflow Detector (`lib/utils/overflow_detector.dart`)
یک کلاس جامع برای تشخیص overflow در ویجت‌ها:
- `detectOverflow()` - تشخیص overflow در یک widget
- `checkTextOverflow()` - بررسی overflow در Text
- `checkRowOverflow()` - بررسی overflow در Row
- `checkColumnOverflow()` - بررسی overflow در Column

### 2. Overflow Scanner (`lib/utils/overflow_scanner.dart`)
یک اسکنر برای بررسی خودکار overflow در کد:
- `scanFile()` - اسکن یک فایل
- `scanDirectory()` - اسکن یک دایرکتوری
- `printReport()` - چاپ گزارش

### 3. تست‌های Overflow
- `test/overflow_test.dart` - تست‌های پایه overflow
- `test/overflow_integration_test.dart` - تست‌های integration

## 🚀 نحوه استفاده

### اجرای تست‌های Overflow

#### در Windows (PowerShell):
```powershell
.\scripts\check_overflow.ps1
```

#### در Linux/Mac (Bash):
```bash
chmod +x scripts/check_overflow.sh
./scripts/check_overflow.sh
```

#### اجرای دستی:
```bash
# تست‌های پایه
flutter test test/overflow_test.dart

# تست‌های integration
flutter test test/overflow_integration_test.dart

# تحلیل کد
flutter analyze
```

### استفاده از Overflow Detector در کد

```dart
import 'package:gymaipro/utils/overflow_detector.dart';

// بررسی Text overflow
final hasOverflow = OverflowDetector.checkTextOverflow(
  text: 'متن طولانی',
  style: TextStyle(fontSize: 16),
  maxWidth: 100,
);

// بررسی یک widget tree
final issues = await OverflowDetector.checkWidgetTree(
  MyWidget(),
  screenSizes: [
    Size(320, 568),
    Size(375, 812),
  ],
);
```

### استفاده از Overflow Scanner

```dart
import 'package:gymaipro/utils/overflow_scanner.dart';

// اسکن یک فایل
final warnings = await OverflowScanner.scanFile('lib/screens/my_screen.dart');

// اسکن یک دایرکتوری
final results = await OverflowScanner.scanDirectory('lib/screens');

// چاپ گزارش
OverflowScanner.printReport(results);
```

## 📋 چک‌لیست Overflow

قبل از commit، این موارد را بررسی کنید:

### ✅ Text Widgets
- [ ] تمام Text widgets دارای `maxLines` هستند
- [ ] تمام Text widgets دارای `overflow` هستند
- [ ] Text در Row با `Flexible` یا `Expanded` wrap شده

### ✅ Row Widgets
- [ ] تمام Text در Row با `Flexible` یا `Expanded` wrap شده
- [ ] از `SafeRow` استفاده شده (در صورت نیاز)
- [ ] از `LayoutBuilder` برای responsive design استفاده شده

### ✅ Column Widgets
- [ ] Column با محتوای زیاد در `SingleChildScrollView` قرار دارد
- [ ] از `SafeColumn` استفاده شده (در صورت نیاز)
- [ ] از `ListView` برای لیست‌های طولانی استفاده شده

### ✅ Container Widgets
- [ ] از fixed width/height فقط در صورت ضرورت استفاده شده
- [ ] از `ScreenUtil` (`.w`, `.h`) برای responsive sizing استفاده شده
- [ ] از `LayoutBuilder` برای constraints استفاده شده

### ✅ ListView Widgets
- [ ] ListView برای لیست‌های طولانی استفاده شده
- [ ] از `shrinkWrap: true` فقط در صورت ضرورت استفاده شده
- [ ] از `physics: NeverScrollableScrollPhysics()` فقط در صورت ضرورت استفاده شده

## 🔍 تشخیص Overflow در Debug Mode

Flutter به صورت خودکار overflow را در debug mode نشان می‌دهد:
- خطوط زرد/سیاه در اطراف widget های overflow شده
- پیام‌های خطا در console

برای فعال‌سازی:
```dart
// در main.dart
void main() {
  // این به صورت پیش‌فرض فعال است در debug mode
  runApp(MyApp());
}
```

## 🛠️ ابزارهای اضافی

### Device Preview
برای تست overflow روی دستگاه‌های مختلف:
```dart
// در main.dart (قبلاً اضافه شده)
DevicePreview(
  enabled: kDebugMode,
  builder: (context) => MyApp(),
)
```

### Flutter Analyze
برای بررسی مشکلات کد:
```bash
flutter analyze
```

### Golden Tests
برای تست UI با اندازه‌های مختلف:
```dart
testWidgets('MyWidget golden test', (tester) async {
  await tester.binding.setSurfaceSize(Size(375, 812));
  await tester.pumpWidget(MyWidget());
  await expectLater(find.byType(MyWidget), matchesGoldenFile('my_widget.png'));
});
```

## 📊 گزارش Overflow

بعد از اجرای تست‌ها، گزارش زیر نمایش داده می‌شود:

```
🔍 شروع بررسی overflow در پروژه...
📝 اجرای تست‌های overflow...
✅ همه تست‌ها پاس شدند
📝 اجرای تست‌های integration overflow...
✅ همه تست‌ها پاس شدند
🔍 اجرای flutter analyze...
✅ هیچ مشکل overflow پیدا نشد
✅ بررسی overflow کامل شد!
```

## 🐛 رفع مشکلات Overflow

### مشکل: Text overflow در Row
**راه حل:**
```dart
// ❌ غلط
Row(
  children: [
    Text('متن طولانی'),
    Icon(Icons.star),
  ],
)

// ✅ درست
Row(
  children: [
    Flexible(
      child: Text(
        'متن طولانی',
        overflow: TextOverflow.ellipsis,
        maxLines: 1,
      ),
    ),
    Icon(Icons.star),
  ],
)
```

### مشکل: Column overflow
**راه حل:**
```dart
// ❌ غلط
Column(
  children: [/* many widgets */],
)

// ✅ درست
SingleChildScrollView(
  child: Column(
    children: [/* many widgets */],
  ),
)
```

### مشکل: Container با عرض ثابت
**راه حل:**
```dart
// ❌ غلط
Container(
  width: 300,
  child: Text('متن'),
)

// ✅ درست
Container(
  width: 300.w, // با ScreenUtil
  constraints: BoxConstraints(maxWidth: 300.w),
  child: Text('متن'),
)
```

## 📚 منابع بیشتر

- [Flutter Layout Guide](https://docs.flutter.dev/development/ui/layout)
- [Flutter Overflow Guide](https://docs.flutter.dev/development/ui/layout/constraints)
- [Very Good Analysis](https://pub.dev/packages/very_good_analysis)

## ✅ نتیجه

با استفاده از این ابزارها و راهنماها، می‌توانید مطمئن شوید که هیچ مشکل overflow در اپلیکیشن باقی نمانده است.
