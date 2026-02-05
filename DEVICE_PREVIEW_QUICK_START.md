# 🚀 راهنمای سریع تست Device Preview

## 📱 مرحله 1: اجرای اپ

```bash
flutter run
```

یا اگر می‌خواهید روی دستگاه خاصی اجرا کنید:

```bash
flutter run -d chrome  # برای وب
flutter run -d windows # برای ویندوز
```

## 🎯 مرحله 2: باز کردن Device Preview

بعد از اجرای اپ:

1. **در گوشه صفحه** یک دکمه کوچک Device Preview می‌بینید
2. **کلیک کنید** روی آن دکمه
3. **پنل Device Preview** باز می‌شود

## 🎮 مرحله 3: تغییر دستگاه

در پنل Device Preview:

### 📱 انتخاب دستگاه:
- روی **"Devices"** کلیک کنید
- لیست دستگاه‌ها را ببینید:
  - ✅ iPhone SE (375x667) - برای تست overflow در گوشی کوچک
  - ✅ iPhone 13 (390x844) - گوشی متوسط
  - ✅ iPhone 14 Pro Max (430x932) - گوشی بزرگ
  - ✅ Samsung Galaxy S23 Ultra (412x915) - گوشی بزرگ اندروید
  - ✅ iPad (810x1080) - تبلت

### 🔄 تغییر Orientation:
- روی **"Orientation"** کلیک کنید
- بین **Portrait** و **Landscape** جابه‌جا شوید

### 📏 تغییر Text Scaling:
- روی **"Text Scaling"** کلیک کنید
- مقدار را به **1.5x** یا **2.0x** افزایش دهید
- این برای تست overflow در فونت‌های بزرگ است

### 🌓 تغییر Theme:
- روی **"Theme"** کلیک کنید
- بین **Light** و **Dark** جابه‌جا شوید

## ✅ چک‌لیست تست Overflow

برای هر اسکرین، این موارد را چک کنید:

### 1. گوشی کوچک (iPhone SE)
- [ ] Portrait - چک کنید overflow نداشته باشد
- [ ] Landscape - چک کنید overflow نداشته باشد
- [ ] Text Scaling 1.5x - چک کنید overflow نداشته باشد

### 2. گوشی بزرگ (S23 Ultra)
- [ ] Portrait - چک کنید overflow نداشته باشد
- [ ] Landscape - چک کنید overflow نداشته باشد
- [ ] Text Scaling 2.0x - چک کنید overflow نداشته باشد

### 3. تبلت (iPad)
- [ ] Portrait - چک کنید layout درست باشد
- [ ] Landscape - چک کنید layout درست باشد

## 🎯 مثال عملی

### تست یک اسکرین خاص:

1. **اپ را اجرا کنید**: `flutter run`
2. **به اسکرین مورد نظر بروید** (مثلاً Dashboard)
3. **Device Preview را باز کنید**
4. **دستگاه را به iPhone SE تغییر دهید**
5. **Text Scaling را به 1.5x افزایش دهید**
6. **Orientation را به Landscape تغییر دهید**
7. **چک کنید که overflow نداشته باشد**

### تست سریع همه دستگاه‌ها:

1. **Device Preview را باز کنید**
2. **لیست دستگاه‌ها را باز کنید**
3. **یکی یکی دستگاه‌ها را انتخاب کنید**
4. **برای هر دستگاه، اسکرین‌ها را چک کنید**

## 🐛 اگر Device Preview نمایش داده نمی‌شود

### مشکل 1: دکمه Device Preview دیده نمی‌شود

**راه حل:**
- مطمئن شوید که در **debug mode** هستید
- اپ را **restart** کنید
- مطمئن شوید که `enabled: kDebugMode` در `main.dart` است

### مشکل 2: Layout درست نمایش داده نمی‌شود

**راه حل:**
- مطمئن شوید که `useInheritedMediaQuery: true` در `MaterialApp` است
- مطمئن شوید که `useInheritedMediaQuery: true` در `ScreenUtilInit` است

### مشکل 3: Performance کند است

**راه حل:**
- این طبیعی است در debug mode
- در release mode Device Preview غیرفعال است

## 💡 نکات مهم

1. **Device Preview فقط در debug mode فعال است**
   - در release mode خودکار غیرفعال می‌شود
   - نیازی به تغییر کد برای production نیست

2. **با ScreenUtil سازگار است**
   - Device Preview با `flutter_screenutil` کاملاً کار می‌کند
   - فقط مطمئن شوید که `useInheritedMediaQuery: true` است

3. **با Responsive Framework سازگار است**
   - Device Preview با `responsive_framework` هم کار می‌کند

## 🎉 نتیجه

با Device Preview می‌توانید:
- ✅ روی 100+ دستگاه تست کنید
- ✅ Overflow را سریع پیدا کنید
- ✅ بدون نیاز به دستگاه فیزیکی تست کنید
- ✅ حرفه‌ای تست بگیرید

**این بهترین راه برای تست overflow است!** 🚀
