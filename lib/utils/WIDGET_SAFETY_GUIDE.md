# راهنمای استفاده از Widget Safety Utils

این فایل راهنما نحوه استفاده از `WidgetSafetyUtils` را برای جلوگیری از خطاهای "widget unmounted" توضیح می‌دهد.

## مشکل

وقتی یک async operation انجام می‌دهید و بعد از آن از `setState`، `context`، `Navigator` یا `ScaffoldMessenger` استفاده می‌کنید، ممکن است widget unmount شده باشد و خطا رخ دهد.

## راه حل

از `WidgetSafetyUtils` استفاده کنید که همه عملیات را با بررسی `mounted` انجام می‌دهد.

## مثال‌های استفاده

### 1. Safe setState

```dart
// ❌ بد - ممکن است خطا بدهد
await someAsyncOperation();
setState(() {
  _value = newValue;
});

// ✅ خوب
await someAsyncOperation();
WidgetSafetyUtils.safeSetState(this, () {
  _value = newValue;
});
```

### 2. Safe Navigation

```dart
// ❌ بد
await someAsyncOperation();
Navigator.push(context, MaterialPageRoute(...));

// ✅ خوب
await someAsyncOperation();
WidgetSafetyUtils.safeNavigate(context, () => NextScreen());
```

### 3. Safe SnackBar

```dart
// ❌ بد
await someAsyncOperation();
ScaffoldMessenger.of(context).showSnackBar(...);

// ✅ خوب
await someAsyncOperation();
WidgetSafetyUtils.safeShowSnackBar(context, 'پیام موفقیت');
```

### 4. Safe Dialog

```dart
// ❌ بد
await someAsyncOperation();
showDialog(context: context, builder: ...);

// ✅ خوب
await someAsyncOperation();
WidgetSafetyUtils.safeShowDialog(
  context: context,
  builder: (ctx) => MyDialog(),
);
```

### 5. Safe Pop

```dart
// ❌ بد
await someAsyncOperation();
Navigator.pop(context);

// ✅ خوب
await someAsyncOperation();
WidgetSafetyUtils.safePop(context);
```

## نکات مهم

1. **همیشه بعد از await از safe functions استفاده کنید**
2. **برای setState از `WidgetSafetyUtils.safeSetState` استفاده کنید**
3. **برای context operations از safe methods استفاده کنید**
4. **اگر context nullable است، به صورت مستقیم پاس دهید (null check داخل function انجام می‌شود)**

## Migration Guide

برای تبدیل کدهای قدیمی:

1. `setState(() {...})` → `WidgetSafetyUtils.safeSetState(this, () {...})`
2. `ScaffoldMessenger.of(context).showSnackBar(...)` → `WidgetSafetyUtils.safeShowSnackBar(context, message)`
3. `Navigator.push(...)` → `WidgetSafetyUtils.safeNavigate(context, () => Screen())`
4. `showDialog(...)` → `WidgetSafetyUtils.safeShowDialog(context: context, builder: ...)`

## Import

```dart
import 'package:gymaipro/utils/widget_safety_utils.dart';
```

