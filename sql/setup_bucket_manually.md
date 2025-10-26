# راهنمای دستی تنظیم Bucket

## 🚨 **خطای دسترسی:**
```
ERROR: 42501: must be owner of table objects
```

## ✅ **راه‌حل: استفاده از Supabase Dashboard**

### **مرحله 1: ایجاد Bucket**
1. به **Supabase Dashboard** بروید
2. **Storage** > **Buckets** کلیک کنید
3. **New bucket** کلیک کنید
4. نام: `coach_certificates`
5. **Public bucket** را فعال کنید
6. **Create bucket** کلیک کنید

### **مرحله 2: تنظیم RLS Policies**
1. به **Authentication** > **Policies** بروید
2. جدول `storage.objects` را پیدا کنید
3. **New Policy** کلیک کنید

#### **Policy 1: آپلود (INSERT)**
- **Name**: `Trainers can upload certificates`
- **Operation**: `INSERT`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
(bucket_id = 'coach_certificates' AND auth.uid() IS NOT NULL AND (storage.foldername(name))[1] = auth.uid()::text AND EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'trainer'))
```

#### **Policy 2: مشاهده (SELECT)**
- **Name**: `Public can view certificates`
- **Operation**: `SELECT`
- **Target roles**: `public`
- **Policy definition**:
```sql
(bucket_id = 'coach_certificates')
```

#### **Policy 3: حذف (DELETE)**
- **Name**: `Trainers can delete their certificates`
- **Operation**: `DELETE`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
(bucket_id = 'coach_certificates' AND (auth.uid()::text = (storage.foldername(name))[1] OR EXISTS (SELECT 1 FROM public.profiles WHERE id = auth.uid() AND role = 'admin')))
```

#### **Policy 4: به‌روزرسانی (UPDATE)**
- **Name**: `Trainers can update their certificates`
- **Operation**: `UPDATE`
- **Target roles**: `authenticated`
- **Policy definition**:
```sql
(bucket_id = 'coach_certificates' AND auth.uid()::text = (storage.foldername(name))[1])
```

### **مرحله 3: تست**
1. اپلیکیشن را restart کنید
2. مدرک آپلود کنید
3. بررسی کنید که خطا برطرف شده

## 🔍 **بررسی دسترسی:**
اگر همچنان مشکل دارید، با ادمین Supabase تماس بگیرید تا دسترسی‌های لازم را دریافت کنید.

## 📝 **نکات مهم:**
- Bucket باید **public** باشد
- RLS policies باید دقیقاً مطابق بالا باشند
- کاربر باید نقش `trainer` داشته باشد
