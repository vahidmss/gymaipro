# راهنمای Debug مشکلات Authentication

## مشکل فعلی
خطای `AuthRetryableFetchException` با پیام `"Database error saving new user"` در هنگام ثبت نام کاربران.

## مراحل Debug

### 1. بررسی لاگ‌های مفصل
کدهای authentication و registration حالا لاگ‌های مفصل‌تری دارند که شامل:
- جزئیات هر مرحله از فرآیند ثبت نام
- بررسی اتصال دیتابیس
- تست توابع database
- جزئیات خطاها

### 2. فایل‌های Debug اضافه شده

#### `lib/debug/database_debug_service.dart`
سرویس کاملی برای تست database که شامل:
- تست اتصال پایه
- تست دسترسی به جدول profiles
- تست توابع database
- تست RLS policies
- تست ایجاد پروفایل

#### `sql/debug_auth_issues.sql`
فایل SQL برای بررسی مشکلات database شامل:
- بررسی توابع موجود
- بررسی RLS policies
- بررسی constraints
- بررسی دسترسی‌ها

#### `sql/test_database_functions.sql`
فایل SQL برای تست توابع database

#### `sql/fix_auth_database_issues.sql`
فایل SQL برای اصلاح احتمالی مشکلات database

### 3. نحوه استفاده

#### مرحله 1: اجرای اپلیکیشن
1. اپلیکیشن را اجرا کنید
2. به صفحه OTP verification بروید
3. کد OTP را وارد کنید
4. لاگ‌های debug را در console بررسی کنید

#### مرحله 2: بررسی لاگ‌ها
لاگ‌های مهم که باید بررسی شوند:
- `=== OTP VERIFICATION: Running database diagnostics ===`
- `=== DATABASE DEBUG: ... ===`
- `=== SIGNUP: ... ===`
- `=== REGISTER REAL USER: ... ===`
- `=== PROFILE: ... ===`

#### مرحله 3: اجرای SQL queries
اگر مشکل در database باشد، فایل‌های SQL زیر را اجرا کنید:
1. `sql/debug_auth_issues.sql` - برای تشخیص مشکل
2. `sql/test_database_functions.sql` - برای تست توابع
3. `sql/fix_auth_database_issues.sql` - برای اصلاح مشکلات

### 4. مشکلات احتمالی و راه‌حل‌ها

#### مشکل 1: RLS Policies خیلی محدودکننده
**علائم:** خطای دسترسی در هنگام INSERT
**راه‌حل:** اجرای `sql/fix_auth_database_issues.sql`

#### مشکل 2: توابع database وجود ندارند
**علائم:** خطای `function does not exist`
**راه‌حل:** اجرای `sql/fix_auth_database_issues.sql`

#### مشکل 3: Constraints مشکل‌دار
**علائم:** خطای `constraint violation`
**راه‌حل:** بررسی constraints در `sql/debug_auth_issues.sql`

#### مشکل 4: دسترسی‌های کاربر
**علائم:** خطای `permission denied`
**راه‌حل:** بررسی permissions در `sql/debug_auth_issues.sql`

### 5. مراحل بعدی

بعد از اجرای debug:
1. نتایج لاگ‌ها را بررسی کنید
2. اگر مشکل در database است، فایل‌های SQL مناسب را اجرا کنید
3. اگر مشکل در کد است، کدهای مربوطه را اصلاح کنید
4. تست کنید که مشکل حل شده باشد

### 6. فایل‌های مهم

- `lib/auth/services/supabase_service.dart` - کدهای authentication
- `lib/screens/otp_verification_screen.dart` - صفحه OTP verification
- `lib/debug/database_debug_service.dart` - سرویس debug
- `sql/` - فایل‌های SQL برای database

### 7. نکات مهم

1. **همیشه backup بگیرید** قبل از اجرای SQL queries
2. **لاگ‌ها را کامل بخوانید** تا مشکل دقیق را پیدا کنید
3. **مرحله به مرحله پیش بروید** و هر مرحله را تست کنید
4. **اگر مشکل حل نشد**، لاگ‌های کامل را برای بررسی بیشتر ارسال کنید
