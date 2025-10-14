# راهنمای حل مشکل Permission Denied

## مشکل شناسایی شده
خطای `permission denied for table user_notification_settings` در هنگام ثبت نام کاربران.

## علت مشکل
یک trigger یا function در هنگام ثبت نام کاربر سعی می‌کند به جدول `user_notification_settings` دسترسی پیدا کند اما دسترسی ندارد.

## مراحل حل مشکل

### مرحله 1: بررسی مشکل
فایل `sql/check_auth_triggers_and_functions.sql` را اجرا کنید تا triggers و functions مشکل‌دار را شناسایی کنید.

### مرحله 2: اصلاح دسترسی‌ها
فایل `sql/fix_user_notification_settings_permissions.sql` را اجرا کنید تا دسترسی‌های لازم را اصلاح کنید.

### مرحله 3: تست بدون triggers (اختیاری)
اگر مشکل ادامه داشت، فایل `sql/disable_problematic_triggers.sql` را اجرا کنید تا triggers مشکل‌دار را موقتاً غیرفعال کنید.

### مرحله 4: فعال کردن مجدد triggers
بعد از حل مشکل، فایل `sql/enable_triggers_after_fix.sql` را اجرا کنید تا triggers را دوباره فعال کنید.

## فایل‌های SQL موجود

1. **`sql/check_auth_triggers_and_functions.sql`**
   - بررسی triggers و functions مشکل‌دار
   - شناسایی functions که به user_notification_settings دسترسی دارند

2. **`sql/fix_user_notification_settings_permissions.sql`**
   - اصلاح دسترسی‌های جدول user_notification_settings
   - ایجاد RLS policies مناسب
   - اعطای دسترسی‌های لازم

3. **`sql/disable_problematic_triggers.sql`**
   - غیرفعال کردن موقت triggers مشکل‌دار
   - برای تست بدون triggers

4. **`sql/enable_triggers_after_fix.sql`**
   - فعال کردن مجدد triggers بعد از حل مشکل

## مراحل اجرا

### مرحله 1: اجرای فایل اصلاح دسترسی‌ها
```sql
-- اجرای فایل fix_user_notification_settings_permissions.sql
```

### مرحله 2: تست ثبت نام
1. اپلیکیشن را اجرا کنید
2. به صفحه ثبت نام بروید
3. اطلاعات را وارد کنید
4. کد OTP را وارد کنید
5. بررسی کنید که خطا حل شده باشد

### مرحله 3: اگر مشکل ادامه داشت
1. فایل `disable_problematic_triggers.sql` را اجرا کنید
2. دوباره تست کنید
3. اگر کار کرد، فایل `enable_triggers_after_fix.sql` را اجرا کنید

## نکات مهم

1. **همیشه backup بگیرید** قبل از اجرای SQL queries
2. **مرحله به مرحله پیش بروید** و هر مرحله را تست کنید
3. **اگر مشکل حل نشد**، لاگ‌های کامل را برای بررسی بیشتر ارسال کنید

## فایل‌های debug موجود

- `lib/debug/database_debug_service.dart` - سرویس debug کامل
- `sql/debug_auth_issues.sql` - بررسی مشکلات database
- `sql/test_database_functions.sql` - تست توابع database
- `sql/fix_auth_database_issues.sql` - اصلاح مشکلات database

## نتیجه مورد انتظار

بعد از اجرای فایل‌های SQL، مشکل `permission denied for table user_notification_settings` باید حل شود و ثبت نام کاربران بدون خطا انجام شود.
