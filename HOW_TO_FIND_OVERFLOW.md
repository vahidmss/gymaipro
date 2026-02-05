# 🔍 چگونه Overflow را پیدا کنیم؟

## مشکل: Overflow در لاگ نمایش داده نمی‌شود

اگر overflow دارید اما در لاگ نمی‌بینید، این راهنما کمک می‌کند.

## ✅ راه‌حل 1: بررسی Error Handler

Error Handler به‌روزرسانی شده تا overflow errors را به صورت واضح نمایش دهد.

### در Debug Mode:
وقتی overflow اتفاق می‌افتد، باید این را ببینید:

```
╔═══════════════════════════════════════════════════════════╗
║  ⚠️  OVERFLOW ERROR DETECTED! ⚠️                        ║
╠═══════════════════════════════════════════════════════════╣
║ Error: RenderFlex overflowed by 42 pixels
║ Stack Trace: ...
║ 💡 Fix: Use SafeRow, SafeColumn, or wrap Text in Flexible
╚═══════════════════════════════════════════════════════════╝
```

## ✅ راه‌حل 2: استفاده از Flutter DevTools

### 1. اجرای اپ با DevTools:

```bash
flutter run
```

### 2. باز کردن DevTools:

در terminal می‌بینید:
```
The Flutter DevTools debugger and profiler on Chrome is available at:
http://127.0.0.1:9100?uri=...
```

روی لینک کلیک کنید یا در browser باز کنید.

### 3. استفاده از Layout Explorer:

1. در DevTools، به **"Widget Inspector"** بروید
2. روی widget که overflow دارد کلیک کنید
3. **Layout Explorer** را باز کنید
4. Overflow را می‌بینید

## ✅ راه‌حل 3: استفاده از debugPaintSizeEnabled

در `main.dart` اضافه کنید:

```dart
import 'package:flutter/rendering.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // فقط برای debug - نمایش constraints
  debugPaintSizeEnabled = kDebugMode;
  
  // ...
}
```

این کار باعث می‌شود:
- Constraints و sizes در UI نمایش داده شوند
- Overflow را به صورت بصری ببینید

## ✅ راه‌حل 4: استفاده از Device Preview

### 1. اجرای اپ:

```bash
flutter run
```

### 2. باز کردن Device Preview:

- روی دکمه Device Preview کلیک کنید
- دستگاه را به **Samsung Galaxy S25** یا **S23 Ultra** تغییر دهید
- **Text Scaling** را به **1.5x** یا **2.0x** افزایش دهید

### 3. چک کردن Overflow:

- Overflow را به صورت بصری می‌بینید
- خطوط قرمز روی widget‌های overflow شده

## ✅ راه‌حل 5: جستجوی دستی در کد

### الگوهای مشکوک:

1. **Row با Text بدون Flexible:**
```dart
// ❌ مشکوک
Row(
  children: [
    Text('متن طولانی'),
    Icon(Icons.star),
  ],
)
```

2. **Text بدون maxLines:**
```dart
// ❌ مشکوک
Text('متن طولانی')
```

3. **Fixed width/height:**
```dart
// ❌ مشکوک
Container(width: 300, height: 200)
```

## 🎯 چک‌لیست برای پیدا کردن Overflow

- [ ] ✅ Error Handler را چک کنید (باید overflow error را log کند)
- [ ] ✅ Flutter DevTools را باز کنید
- [ ] ✅ Device Preview را استفاده کنید
- [ ] ✅ debugPaintSizeEnabled را فعال کنید
- [ ] ✅ کد را برای الگوهای مشکوک بررسی کنید

## 💡 نکات مهم

1. **Error Handler** در debug mode overflow errors را log می‌کند
2. **Flutter DevTools** بهترین راه برای دیدن overflow است
3. **Device Preview** برای تست روی دستگاه‌های مختلف عالی است
4. **debugPaintSizeEnabled** برای دیدن constraints مفید است

## 🔧 اگر هنوز overflow را نمی‌بینید

### بررسی کنید:

1. **مطمئن شوید در debug mode هستید:**
   - `flutter run` (نه `flutter run --release`)

2. **مطمئن شوید error handler فعال است:**
   - در `main.dart` باید `AppErrorHandler.initialize()` باشد

3. **مطمئن شوید overflow واقعاً اتفاق می‌افتد:**
   - در Device Preview چک کنید
   - Text Scaling را افزایش دهید

## 📱 تست روی S25

برای تست روی S25:

1. **Device Preview را باز کنید**
2. **دستگاه را به Samsung Galaxy S25 تغییر دهید**
3. **Text Scaling را به 1.5x افزایش دهید**
4. **تمام اسکرین‌ها را چک کنید**

اگر overflow دیدید:
- Error Handler باید آن را log کند
- در console می‌بینید: `⚠️ OVERFLOW ERROR DETECTED!`

---

**نکته:** اگر overflow دارید اما در لاگ نمی‌بینید، احتمالاً error handler آن را suppress کرده است. با به‌روزرسانی جدید، باید overflow errors را به صورت واضح ببینید.
