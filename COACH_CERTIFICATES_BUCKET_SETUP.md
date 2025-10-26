# راهنمای تنظیم Bucket برای مدارک مربیان

## 📦 **تنظیمات Storage Bucket**

### 1. **ایجاد Bucket**
```sql
-- در Supabase Dashboard > Storage
-- نام bucket: coach_certificates
-- عمومی: بله (برای دسترسی عمومی به تصاویر)
```

### 2. **تنظیمات RLS Policy**
```sql
-- Policy برای آپلود (فقط مربیان)
CREATE POLICY "Trainers can upload certificates" ON storage.objects
FOR INSERT WITH CHECK (
  bucket_id = 'coach_certificates' AND
  auth.uid()::text = (storage.foldername(name))[1]
);

-- Policy برای مشاهده (همه کاربران)
CREATE POLICY "Public can view certificates" ON storage.objects
FOR SELECT USING (bucket_id = 'coach_certificates');

-- Policy برای حذف (فقط صاحب فایل)
CREATE POLICY "Trainers can delete their certificates" ON storage.objects
FOR DELETE USING (
  bucket_id = 'coach_certificates' AND
  auth.uid()::text = (storage.foldername(name))[1]
);
```

### 3. **ساختار فایل‌ها**
```
coach_certificates/
├── {trainer_id}/
│   ├── certificate_1234567890.jpg
│   ├── certificate_1234567891.jpg
│   └── ...
```

### 4. **تنظیمات CORS (اختیاری)**
```json
{
  "allowedOrigins": ["*"],
  "allowedMethods": ["GET", "POST", "PUT", "DELETE"],
  "allowedHeaders": ["*"],
  "maxAge": 3600
}
```

## 🔧 **تست عملکرد**

### 1. **تست آپلود**
- مربی وارد میز کار می‌شود
- روی "افزودن مدرک" کلیک می‌کند
- تصویر انتخاب می‌کند
- فرم را پر می‌کند و آپلود می‌کند

### 2. **تست نمایش**
- در بخش رتبه‌بندی مربیان
- مدارک تایید شده نمایش داده می‌شوند
- تصاویر به درستی لود می‌شوند

### 3. **تست امنیت**
- فقط مربیان می‌توانند آپلود کنند
- فقط ادمین‌ها می‌توانند تایید/رد کنند
- کاربران عمومی فقط مدارک تایید شده را می‌بینند

## 📊 **نظارت و آمار**

### 1. **آمار Storage**
```sql
-- تعداد فایل‌های آپلود شده
SELECT COUNT(*) FROM storage.objects 
WHERE bucket_id = 'coach_certificates';

-- حجم استفاده شده
SELECT SUM(metadata->>'size')::bigint as total_size
FROM storage.objects 
WHERE bucket_id = 'coach_certificates';
```

### 2. **آمار مدارک**
```sql
-- تعداد مدارک در انتظار تایید
SELECT COUNT(*) FROM certificates 
WHERE status = 'pending';

-- تعداد مدارک تایید شده
SELECT COUNT(*) FROM certificates 
WHERE status = 'approved';
```

## 🚨 **نکات مهم**

1. **حجم Storage**: مراقب حجم استفاده شده باشید
2. **فرمت فایل**: فقط JPG/PNG مجاز است
3. **اندازه فایل**: حداکثر 5MB
4. **امنیت**: RLS policies را بررسی کنید
5. **پشتیبان‌گیری**: تصاویر مهم را بک‌آپ کنید

## 🔄 **به‌روزرسانی‌های آینده**

- اضافه کردن فشرده‌سازی خودکار تصاویر
- اضافه کردن واترمارک
- اضافه کردن OCR برای خواندن متن مدارک
- اضافه کردن سیستم تایید خودکار
