# 🔧 راهنمای رفع مشکلات فراخوانی اطلاعات

## 🚨 مشکل شناسایی شده:

**خطای فراخوانی اطلاعات** در بخش Trainer Users - احتمالاً مربوط به:
- جداول مفقود در دیتابیس
- RLS policies نادرست
- Foreign key constraints مشکل‌دار

## ✅ راه‌حل‌های فوری:

### مرحله 1: اجرای SQL در Supabase
1. **به Supabase Dashboard بروید**
2. **SQL Editor را باز کنید**
3. **فایل `supabase/fix_data_loading_issues.sql` را کپی کنید**
4. **کد را اجرا کنید**

### مرحله 2: بررسی وضعیت دیتابیس
1. **فایل `supabase/check_database_status.sql` را اجرا کنید**
2. **نتایج را بررسی کنید**

### مرحله 3: تست مجدد
1. **اپ را دوباره اجرا کنید**
2. **به بخش Trainer Users بروید**
3. **عملکرد را بررسی کنید**

## 📋 مراحل اجرا:

### 1. اجرای SQL در Supabase:
```sql
-- کد کامل در فایل fix_data_loading_issues.sql
-- این کد شامل:
-- - ایجاد جداول trainer_requests و trainer_clients
-- - تنظیم foreign key constraints
-- - ایجاد RLS policies
-- - Grant permissions
-- - ایجاد indexes
```

### 2. بررسی مشکلات احتمالی:

#### الف) جداول مفقود:
- `trainer_requests` - برای درخواست‌های مربی
- `trainer_clients` - برای روابط مربی-شاگرد

#### ب) RLS policies:
- دسترسی کاربران به داده‌های خود
- دسترسی مربیان به شاگردان

#### ج) Foreign keys:
- ارتباط صحیح با جدول `profiles`

### 3. تست عملکرد:
- ✅ بارگذاری صفحه Trainer Users
- ✅ نمایش آمار درخواست‌ها
- ✅ نمایش آمار روابط
- ✅ ارسال درخواست جدید

## 🎯 نتیجه نهایی:
- **جداول موجود** ✅
- **RLS policies صحیح** ✅
- **Foreign keys درست** ✅
- **دسترسی‌ها تنظیم شده** ✅

## 📞 در صورت مشکل:
اگر همچنان مشکلی وجود دارد:
1. **لاگ‌های جدید را ارسال کنید**
2. **نتایج `check_database_status.sql` را ارسال کنید**
3. **خطای دقیق را مشخص کنید**

## 🔍 عیب‌یابی پیشرفته:

### بررسی لاگ‌های Supabase:
1. **به Supabase Dashboard بروید**
2. **Logs > Database را بررسی کنید**
3. **خطاهای SQL را پیدا کنید**

### بررسی Network requests:
1. **Developer Tools را باز کنید**
2. **Network tab را بررسی کنید**
3. **درخواست‌های Supabase را بررسی کنید**

### تست مستقیم در SQL Editor:
```sql
-- تست دسترسی به trainer_requests
SELECT * FROM trainer_requests LIMIT 5;

-- تست دسترسی به trainer_clients  
SELECT * FROM trainer_clients LIMIT 5;

-- تست RLS policies
SELECT * FROM profiles WHERE id = auth.uid();
``` 