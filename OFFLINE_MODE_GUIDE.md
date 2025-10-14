# راهنمای Offline Mode

## مشکل اصلی
اپلیکیشن وقتی اینترنت نداره کرش می‌کنه و خطای `AuthRetryableFetchException` می‌ده.

## راه‌حل پیاده‌سازی شده

### 1. **تغییرات در Supabase Initialization**
```dart
// چک کردن وضعیت اینترنت قبل از initialize کردن Supabase
final isOnline = await ConnectivityService.instance.checkNow();
if (isOnline) {
  await Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey);
} else {
  // Initialize در offline mode
  await Supabase.initialize(
    url: AppConfig.supabaseUrl,
    anonKey: AppConfig.supabaseAnonKey,
    authOptions: const FlutterAuthClientOptions(autoRefreshToken: false),
  );
}
```

### 2. **تغییرات در Auth Service**
- چک کردن وضعیت اینترنت قبل از عملیات auth
- Skip کردن profile verification در offline mode
- استفاده از cached session

### 3. **تغییرات در Route Service**
- استفاده از cached route در offline mode
- Fallback به welcome screen اگر cache موجود نباشه

### 4. **تغییرات در Connection Test**
- Skip کردن connection test در offline mode
- Retry mechanism فقط برای online mode

## ویژگی‌های جدید

### ✅ **Offline Mode Support**
- اپلیکیشن بدون اینترنت کرش نمی‌کنه
- Session های قبلی حفظ می‌شن
- Route های cached استفاده می‌شن

### ✅ **Smart Connectivity Detection**
- تشخیص خودکار وضعیت اینترنت
- تغییر رفتار بر اساس connectivity
- Retry mechanism برای online mode

### ✅ **Graceful Error Handling**
- Error handling بهتر برای network failures
- Logging مفصل برای debug
- Fallback strategies

## نحوه تست

### 1. **تست Offline Mode**
```bash
# قطع کردن اینترنت
# اجرای اپلیکیشن
# چک کردن console logs
```

### 2. **لاگ‌های مهم**
```
Offline mode: Skipping Supabase initialization
Offline mode: Skipping connection test
Offline mode: Skipping profile verification
Offline mode, using cached route
```

### 3. **تست Online/Offline Transition**
- قطع کردن اینترنت
- اجرای اپلیکیشن
- وصل کردن اینترنت
- چک کردن reconnection

## مزایای پیاده‌سازی

### 🚀 **Performance**
- سریع‌تر startup در offline mode
- کمتر network calls
- بهتر caching

### 🛡️ **Reliability**
- کرش نمی‌کنه بدون اینترنت
- بهتر error handling
- Graceful degradation

### 👤 **User Experience**
- بهتر UX در offline mode
- Offline banner نمایش داده می‌شه
- Smooth transitions

## نکات مهم

### ⚠️ **Limitations**
- بعضی features نیاز به اینترنت دارن
- Profile updates فقط online کار می‌کنه
- Real-time features در offline mode محدود هستن

### 🔧 **Configuration**
- `autoRefreshToken: false` در offline mode
- Connectivity service فعال
- Offline banner نمایش داده می‌شه

### 📱 **Testing**
- تست با airplane mode
- تست با WiFi/Mobile data
- تست transition بین online/offline

## نتیجه
حالا اپلیکیشن شما:
- ✅ بدون اینترنت کرش نمی‌کنه
- ✅ Session های قبلی حفظ می‌شن
- ✅ Offline banner نمایش داده می‌شه
- ✅ بهتر error handling داره
- ✅ Smooth user experience
