# راهنمای حل مشکل Permission Denied - نسخه اصلاح شده

## مشکل شناسایی شده
خطای `permission denied for table user_notification_settings` در هنگام ثبت نام کاربران.

## علت مشکل
یک trigger یا function در هنگام ثبت نام کاربر سعی می‌کند به جدول `user_notification_settings` دسترسی پیدا کند اما دسترسی ندارد.

## ⚠️ نکته مهم
**جدول `auth.users` متعلق به Supabase Auth است و نمی‌توان triggers آن را تغییر داد.**

## راه‌حل اصلاح شده

### مرحله 1: اصلاح دسترسی‌های جداول public
فایل `sql/fix_permissions_public_tables_only.sql` را اجرا کنید:

```sql
-- این فایل فقط جداول public را اصلاح می‌کند
-- و با auth.users کاری ندارد
```

**این فایل شامل:**
- ✅ اصلاح دسترسی‌های جدول `user_notification_settings`
- ✅ ایجاد RLS policies مناسب
- ✅ غیرفعال کردن triggers مشکل‌دار روی جداول public
- ✅ ایجاد جدول `user_notification_settings` اگر وجود ندارد

### مرحله 2: تست ثبت نام
1. اپلیکیشن را اجرا کنید
2. به صفحه ثبت نام بروید
3. اطلاعات را وارد کنید
4. کد OTP را وارد کنید
5. بررسی کنید که خطا حل شده باشد

### مرحله 3: اگر مشکل حل شد
فایل `sql/enable_public_triggers_after_fix.sql` را اجرا کنید تا triggers جداول public را دوباره فعال کنید.

## فایل‌های SQL جدید

### ✅ `sql/fix_permissions_public_tables_only.sql`
- اصلاح دسترسی‌های جداول public
- غیرفعال کردن triggers مشکل‌دار
- ایجاد جدول user_notification_settings

### ✅ `sql/enable_public_triggers_after_fix.sql`
- فعال کردن مجدد triggers جداول public
- بدون دسترسی به auth.users

## فایل‌های قدیمی (استفاده نکنید)
- ❌ `sql/disable_problematic_triggers.sql` - مشکل دارد
- ❌ `sql/enable_triggers_after_fix.sql` - مشکل دارد

## مراحل اجرا

### مرحله 1: اجرای فایل اصلاح دسترسی‌ها
```sql
-- اجرای فایل fix_permissions_public_tables_only.sql
```

### مرحله 2: تست ثبت نام
1. اپلیکیشن را اجرا کنید
2. به صفحه ثبت نام بروید
3. اطلاعات را وارد کنید
4. کد OTP را وارد کنید
5. بررسی کنید که خطا حل شده باشد

### مرحله 3: اگر مشکل حل شد
```sql
-- اجرای فایل enable_public_triggers_after_fix.sql
```

## تفاوت با نسخه قبلی

| نسخه قبلی | نسخه جدید |
|-----------|-----------|
| سعی در تغییر auth.users | فقط جداول public |
| خطای permission denied | بدون خطا |
| نیاز به دسترسی admin | دسترسی عادی |

## نتیجه مورد انتظار

بعد از اجرای فایل `sql/fix_permissions_public_tables_only.sql`:
- ✅ مشکل `permission denied for table user_notification_settings` حل شود
- ✅ ثبت نام کاربران بدون خطا انجام شود
- ✅ triggers جداول public غیرفعال شوند (موقت)

بعد از اجرای فایل `sql/enable_public_triggers_after_fix.sql`:
- ✅ triggers جداول public دوباره فعال شوند
- ✅ عملکرد عادی اپلیکیشن حفظ شود

## نکات مهم

1. **فقط فایل‌های جدید را استفاده کنید**
2. **فایل‌های قدیمی را اجرا نکنید**
3. **مرحله به مرحله پیش بروید**
4. **هر مرحله را تست کنید**

## فایل‌های debug موجود

- `lib/debug/database_debug_service.dart` - سرویس debug کامل
- `sql/debug_auth_issues.sql` - بررسی مشکلات database
- `sql/test_database_functions.sql` - تست توابع database
- `sql/fix_auth_database_issues.sql` - اصلاح مشکلات database
