# راهنمای راه‌اندازی سیستم مربی-شاگرد

## 📋 مراحل اجرا

### 1. اجرای Migration
فایل `20241201000000_create_trainer_system_tables.sql` را در Supabase اجرا کنید:

```sql
-- این فایل را در SQL Editor اجرا کنید
-- یا از طریق CLI:
supabase db push
```

### 2. بررسی جداول ایجاد شده

#### جدول `trainer_requests`
```sql
-- مشاهده ساختار جدول
\d trainer_requests

-- مشاهده نمونه داده
SELECT * FROM trainer_requests LIMIT 5;
```

#### جدول `trainer_clients`
```sql
-- مشاهده ساختار جدول
\d trainer_clients

-- مشاهده نمونه داده
SELECT * FROM trainer_clients LIMIT 5;
```

### 3. تست RLS Policies

#### تست دسترسی مربی:
```sql
-- با کاربر مربی وارد شوید
-- سپس این کوئری را اجرا کنید
SELECT * FROM trainer_requests WHERE trainer_id = auth.uid();
```

#### تست دسترسی شاگرد:
```sql
-- با کاربر شاگرد وارد شوید
-- سپس این کوئری را اجرا کنید
SELECT * FROM trainer_requests 
WHERE client_username = (SELECT username FROM profiles WHERE user_id = auth.uid());
```

### 4. تست Trigger

#### ایجاد درخواست تست:
```sql
-- درخواست جدید ایجاد کنید
INSERT INTO trainer_requests (trainer_id, client_username, message)
VALUES ('TRAINER_USER_ID', 'CLIENT_USERNAME', 'پیام تست');

-- وضعیت را به accepted تغییر دهید
UPDATE trainer_requests 
SET status = 'accepted', response_date = NOW()
WHERE id = 'REQUEST_ID';

-- بررسی کنید که رابطه مربی-شاگرد ایجاد شده
SELECT * FROM trainer_clients WHERE trainer_id = 'TRAINER_USER_ID';
```

## 🔧 ویژگی‌های پیاده‌سازی شده

### ✅ جداول اصلی:
- `trainer_requests`: درخواست‌های مربی
- `trainer_clients`: روابط مربی-شاگرد

### ✅ امنیت:
- Row Level Security (RLS) فعال
- Policies برای کنترل دسترسی
- بررسی مالکیت داده‌ها

### ✅ عملکرد:
- Indexes برای بهبود سرعت
- Triggers برای خودکارسازی
- Constraints برای اعتبارسنجی

### ✅ خودکارسازی:
- ایجاد خودکار رابطه مربی-شاگرد هنگام تایید درخواست
- به‌روزرسانی خودکار `updated_at`

## 🧪 تست سیستم

### 1. تست ارسال درخواست:
```sql
-- مربی درخواست ارسال می‌کند
INSERT INTO trainer_requests (trainer_id, client_username, message)
VALUES ('trainer_uuid', 'client_username', 'سلام، می‌خواهم مربی شما باشم');
```

### 2. تست تایید درخواست:
```sql
-- شاگرد درخواست را تایید می‌کند
UPDATE trainer_requests 
SET status = 'accepted', response_date = NOW()
WHERE id = 'request_uuid';
```

### 3. تست مشاهده شاگردان:
```sql
-- مربی شاگردان خود را می‌بیند
SELECT 
    tc.*,
    p.username,
    p.full_name
FROM trainer_clients tc
JOIN profiles p ON tc.client_id = p.user_id
WHERE tc.trainer_id = 'trainer_uuid' AND tc.status = 'active';
```

## 🚨 نکات مهم

### 1. امنیت:
- تمام جداول RLS دارند
- کاربران فقط به داده‌های خود دسترسی دارند
- بررسی مالکیت در تمام عملیات

### 2. عملکرد:
- Indexes روی فیلدهای پرکاربرد
- Constraints برای جلوگیری از داده‌های نامعتبر
- Triggers برای خودکارسازی

### 3. قابلیت توسعه:
- ساختار قابل گسترش
- آماده برای ویژگی‌های آینده
- مستندسازی کامل

## 🔄 مراحل بعدی

1. **اضافه کردن به منو**: صفحه مدیریت شاگردان را به منوی اصلی اضافه کنید
2. **سیستم اعلان‌ها**: اعلان برای درخواست‌های جدید
3. **بخش پولی**: پیاده‌سازی ویژگی‌های پولی
4. **گزارش‌گیری**: آمار و گزارش‌های پیشرفته

## 📞 پشتیبانی

در صورت بروز مشکل:
1. لاگ‌های Supabase را بررسی کنید
2. RLS policies را تست کنید
3. Permissions کاربر را بررسی کنید
4. از فایل تست استفاده کنید 