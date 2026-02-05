# راهنمای استفاده از Device Preview برای تست Overflow

## 🎯 چرا Device Preview؟

`device_preview_plus` یک ابزار فوق‌العاده برای تست overflow روی دستگاه‌های مختلف است:

✅ **بدون نیاز به دستگاه فیزیکی**: تست روی 100+ دستگاه مختلف  
✅ **تست سریع**: تغییر دستگاه در کمتر از 1 ثانیه  
✅ **تست Orientation**: Portrait و Landscape  
✅ **تست Text Scaling**: فونت‌های بزرگ و کوچک  
✅ **تست Dark Mode**: هر دو حالت  
✅ **حرفه‌ای**: دقیقاً مثل تست روی دستگاه واقعی  

## 📦 نصب

پکیج به `pubspec.yaml` اضافه شده است و نصب شده است! ✅

```bash
flutter pub get  # اگر نیاز بود دوباره اجرا کنید
```

## 🚀 راه‌اندازی

### روش 1: فقط در حالت Debug (توصیه می‌شود)

در `lib/main.dart`:

```dart
import 'package:device_preview_plus/device_preview_plus.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  AppErrorHandler.initialize();
  final initResult = await AppInitializer.initialize();

  runApp(
    DevicePreview(
      enabled: kDebugMode, // فقط در debug mode فعال می‌شود
      builder: (context) => LifecycleObserver(
        child: MyApp(
          initialRoute: initResult.initialRoute,
          supabaseService: initResult.supabaseService,
        ),
      ),
    ),
  );
}
```

### روش 2: همیشه فعال (برای تست بیشتر)

```dart
DevicePreview(
  enabled: true, // همیشه فعال
  builder: (context) => MyApp(...),
)
```

### تنظیم MaterialApp

در `MaterialApp` باید این تنظیمات را اضافه کنید:

```dart
MaterialApp(
  // این دو خط مهم هستند!
  useInheritedMediaQuery: true,
  locale: DevicePreview.locale(context),
  builder: DevicePreview.appBuilder, // این خط مهم است!
  
  // بقیه تنظیمات...
  title: 'GymAI Pro',
  // ...
)
```

## 📱 دستگاه‌های پیش‌فرض

Device Preview شامل این دستگاه‌هاست:

### 📱 گوشی‌های کوچک (برای تست overflow)
- iPhone SE (375x667)
- iPhone 12 mini (375x812)
- Samsung Galaxy S20 (360x800)

### 📱 گوشی‌های متوسط
- iPhone 13 (390x844)
- iPhone 14 Pro (393x852)
- Samsung Galaxy S23 (360x780)

### 📱 گوشی‌های بزرگ (مثل S23 Ultra)
- iPhone 14 Pro Max (430x932)
- Samsung Galaxy S23 Ultra (412x915)
- Pixel 7 Pro (412x915)

### 📱 تبلت‌ها
- iPad (810x1080)
- iPad Pro 12.9" (1024x1366)

## 🎮 نحوه استفاده

### 1. اجرای اپ

```bash
flutter run
```

### 2. باز کردن Device Preview

وقتی اپ اجرا شد، یک دکمه در گوشه صفحه می‌بینید که می‌توانید:
- دستگاه را تغییر دهید
- Orientation را تغییر دهید (Portrait/Landscape)
- Text Scaling را تغییر دهید
- Dark Mode را toggle کنید

### 3. تست Overflow

1. **گوشی کوچک انتخاب کنید** (مثل iPhone SE)
2. **Text Scaling را بزرگ کنید** (برای تست فونت‌های بزرگ)
3. **Orientation را تغییر دهید** (Portrait/Landscape)
4. **تمام اسکرین‌ها را چک کنید**

## 🔍 چک‌لیست تست Overflow

برای هر اسکرین:

- [ ] ✅ iPhone SE (کوچک) - Portrait
- [ ] ✅ iPhone SE (کوچک) - Landscape  
- [ ] ✅ iPhone 14 Pro Max (بزرگ) - Portrait
- [ ] ✅ iPhone 14 Pro Max (بزرگ) - Landscape
- [ ] ✅ Samsung Galaxy S23 Ultra (بزرگ) - Portrait
- [ ] ✅ iPad (تبلت) - Portrait
- [ ] ✅ Text Scaling بزرگ (1.5x)
- [ ] ✅ Dark Mode
- [ ] ✅ Light Mode

## 💡 نکات مهم

### 1. فقط در Debug Mode

برای production، Device Preview را غیرفعال کنید:

```dart
DevicePreview(
  enabled: kDebugMode, // فقط در debug
  // ...
)
```

### 2. استفاده با ScreenUtil

Device Preview با `flutter_screenutil` کاملاً سازگار است. فقط مطمئن شوید که:

```dart
ScreenUtilInit(
  useInheritedMediaQuery: true, // این خط مهم است!
  // ...
)
```

### 3. استفاده با Responsive Framework

Device Preview با `responsive_framework` هم کار می‌کند.

### 4. Performance

Device Preview در debug mode ممکن است کمی کند باشد. این طبیعی است.

## 🎯 مثال استفاده

### تست یک اسکرین خاص

1. اپ را اجرا کنید
2. به اسکرین مورد نظر بروید
3. در Device Preview:
   - دستگاه را به iPhone SE تغییر دهید
   - Text Scaling را به 1.5x افزایش دهید
   - Orientation را به Landscape تغییر دهید
4. چک کنید که overflow نداشته باشد

### تست سریع همه دستگاه‌ها

1. لیست دستگاه‌ها را باز کنید
2. یکی یکی دستگاه‌ها را انتخاب کنید
3. برای هر دستگاه، اسکرین‌ها را چک کنید

## 🐛 Troubleshooting

### مشکل: Device Preview نمایش داده نمی‌شود

**راه حل:**
- مطمئن شوید `enabled: true` یا `enabled: kDebugMode` است
- مطمئن شوید `builder: DevicePreview.appBuilder` در MaterialApp است
- اپ را restart کنید

### مشکل: Layout درست نمایش داده نمی‌شود

**راه حل:**
- مطمئن شوید `useInheritedMediaQuery: true` در MaterialApp است
- مطمئن شوید `useInheritedMediaQuery: true` در ScreenUtilInit است

### مشکل: Performance کند است

**راه حل:**
- فقط در debug mode استفاده کنید
- در release mode غیرفعال است

## 📚 منابع بیشتر

- [device_preview_plus on pub.dev](https://pub.dev/packages/device_preview_plus)
- [Documentation](https://pub.dev/packages/device_preview_plus/example)

## ✅ نتیجه

با Device Preview می‌توانید:
- ✅ روی 100+ دستگاه تست کنید
- ✅ Overflow را سریع پیدا کنید
- ✅ بدون نیاز به دستگاه فیزیکی تست کنید
- ✅ حرفه‌ای تست بگیرید

**این بهترین راه برای تست overflow است!** 🎉
