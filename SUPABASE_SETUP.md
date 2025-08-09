# راهنمای تنظیم Supabase

## مشکل اتصال به Supabase

اگر اپلیکیشن در خانه کار می‌کنه ولی جای دیگه وصل نمی‌شه، مشکل از IP محلی هست.

## راه حل‌ها

### 1. استفاده از localhost (توصیه شده)
```dart
// در lib/config/supabase_config.dart
static const String supabaseUrl = 'http://localhost:54321';
```

### 2. استفاده از IP مخصوص امولاتور
```dart
// برای Android Emulator
static const String supabaseUrl = 'http://10.0.2.2:54321';

// برای iOS Simulator  
static const String supabaseUrl = 'http://localhost:54321';
```

### 3. استفاده از IP محلی (فقط در شبکه خانگی)
```dart
// IP کامپیوتر شما در شبکه محلی
static const String supabaseUrl = 'http://192.168.1.3:54321';
```

## تنظیمات مختلف

### برای توسعه محلی:
- **Web**: `http://localhost:54321`
- **Android Emulator**: `http://10.0.2.2:54321`
- **iOS Simulator**: `http://localhost:54321`
- **Physical Device**: IP کامپیوتر در شبکه محلی

### برای تولید:
- از Supabase Cloud استفاده کنید
- URL: `https://your-project.supabase.co`

## عیب‌یابی

1. **چک کردن Supabase Status**:
   ```bash
   supabase status
   ```

2. **Restart کردن Supabase**:
   ```bash
   supabase stop
   supabase start
   ```

3. **چک کردن پورت**:
   ```bash
   netstat -an | grep 54321
   ```

4. **تست اتصال**:
   - مرورگر: `http://localhost:54321`
   - باید صفحه Supabase Dashboard باز بشه

## نکات مهم

- **localhost** فقط روی همون کامپیوتر کار می‌کنه
- **IP محلی** فقط در شبکه خانگی کار می‌کنه
- **امولاتور** IP مخصوص خودش رو داره
- **دستگاه فیزیکی** نیاز به IP واقعی داره

## تنظیم خودکار

اپلیکیشن حالا به صورت خودکار تشخیص می‌ده که روی چه پلتفرمی اجرا می‌شه و URL مناسب رو انتخاب می‌کنه. 