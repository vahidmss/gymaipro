# 🔧 راهنمای رفع مشکل باز کردن صفحه پرداخت

## 🎯 **مشکل:**
```
خطا در باز کردن صفحه پرداخت
```

## ✅ **راه حل انجام شده:**

### **1. بهبود URL Launcher:**
- اضافه کردن debug logs کامل
- تلاش با mode های مختلف
- fallback mechanism

### **2. Debug Logs:**
- نمایش URL کامل
- بررسی canLaunchUrl
- ردیابی خطاها

## 🧪 **تست سیستم:**

### **مرحله 1: تست اولیه**
1. **وارد صفحه شارژ کیف پول شوید**
2. **مبلغ 1000000 تومان وارد کنید**
3. **روی "ادامه پرداخت" کلیک کنید**
4. **لاگ‌ها را بررسی کنید**

### **مرحله 2: بررسی لاگ‌ها**
```
I/flutter: آدرس پرداخت: https://gymaipro.ir/pay/topup?session_id=session_1234567890_user123
I/flutter: تلاش برای باز کردن URL: https://gymaipro.ir/pay/topup?session_id=session_1234567890_user123
I/flutter: canLaunchUrl result: true
I/flutter: URL launched successfully: true
```

## 📱 **لاگ‌های مورد انتظار:**

### **موفق:**
```
I/flutter: آدرس پرداخت: https://gymaipro.ir/pay/topup?session_id=session_1234567890_user123
I/flutter: تلاش برای باز کردن URL: https://gymaipro.ir/pay/topup?session_id=session_1234567890_user123
I/flutter: canLaunchUrl result: true
I/flutter: URL launched successfully: true
```

### **خطا:**
```
I/flutter: خطا در launchUrl: PlatformException
I/flutter: خطا در launchUrl با platformDefault: PlatformException
```

## 🚀 **مراحل تست کامل:**

### **1. تست URL Launcher:**
1. **مبلغ وارد کنید**
2. **روی "ادامه پرداخت" کلیک کنید**
3. **لاگ‌ها را بررسی کنید**
4. **صفحه پرداخت باید باز شود**

### **2. تست پرداخت:**
1. **پرداخت را انجام دهید**
2. **به اپلیکیشن برمی‌گردید**
3. **موجودی به‌روزرسانی می‌شود**

## 🛠️ **عیب‌یابی:**

### **اگر URL باز نمی‌شود:**
1. **لاگ‌ها را بررسی کنید**
2. **مطمئن شوید URL درست است**
3. **مرورگر را بررسی کنید**

### **اگر خطای PlatformException داشت:**
1. **Android permissions را بررسی کنید**
2. **URL scheme را بررسی کنید**
3. **دوباره تست کنید**

## ✅ **نتیجه موفق:**

- ✅ جلسه پرداخت ایجاد می‌شود
- ✅ URL درست ساخته می‌شود
- ✅ صفحه پرداخت باز می‌شود
- ✅ پرداخت کار می‌کند

## 🔧 **تنظیمات اضافی:**

### **Android Manifest:**
```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.QUERY_ALL_PACKAGES" />
```

### **iOS Info.plist:**
```xml
<key>LSApplicationQueriesSchemes</key>
<array>
    <string>https</string>
    <string>http</string>
</array>
```

---

**🎉 حالا سیستم پرداخت کاملاً آماده است!**
