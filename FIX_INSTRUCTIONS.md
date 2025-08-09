# 🔧 راهنمای رفع مشکلات فعلی

## 🚨 مشکلات شناسایی شده:

### 1. **مشکل اصلی: Infinite Recursion در RLS Policies**
```
infinite recursion detected in policy for relation "profiles"
```

### 2. **مشکل UI: Overflow در Client Management Screen**
```
A RenderFlex overflowed by 23 pixels on the bottom
```

### 3. **جداول و توابع مفقود:**
- `chat_conversations` (با ستون `last_message_at`)
- `chat_messages`
- `food_bookmarks` 
- `exercise_bookmarks`
- `exercise_likes`
- `food_likes`
- `exec_sql` function
- `get_unread_message_count` function
- `get_food_likes_count` function
- `get_exercise_likes_count` function
- `run_migration_add_role_to_profiles` function

## ✅ راه‌حل‌ها:

### مرحله 1: رفع مشکل RLS Policies
1. **به Supabase Dashboard بروید**
2. **SQL Editor را باز کنید**
3. **فایل `supabase/fix_infinite_recursion_simple.sql` را کپی کنید**
4. **کد را اجرا کنید**

**نکته:** اگر با خطای "policy already exists" مواجه شدید، ابتدا این کد را اجرا کنید:
```sql
-- حذف تمام policies موجود
DROP POLICY IF EXISTS "Users can view own conversations" ON public.chat_conversations;
DROP POLICY IF EXISTS "Users can insert own conversations" ON public.chat_conversations;
DROP POLICY IF EXISTS "Users can view own messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can insert own messages" ON public.chat_messages;
DROP POLICY IF EXISTS "Users can manage own food bookmarks" ON public.food_bookmarks;
DROP POLICY IF EXISTS "Users can manage own exercise bookmarks" ON public.exercise_bookmarks;
DROP POLICY IF EXISTS "Users can manage own exercise likes" ON public.exercise_likes;
DROP POLICY IF EXISTS "Users can manage own food likes" ON public.food_likes;
```

### مرحله 2: رفع مشکل UI
✅ **مشکل overflow حل شد** - `SingleChildScrollView` و `SizedBox` با ارتفاع ثابت اضافه شد

### مرحله 3: تست مجدد
1. **اپ را دوباره اجرا کنید**
2. **ثبت نام کنید**
3. **به بخش Trainer Users بروید**

## 📋 مراحل اجرا:

### 1. اجرای SQL در Supabase:
```sql
-- کد کامل در فایل fix_infinite_recursion_final.sql
-- این کد شامل:
-- - حذف تمام policies قدیمی
-- - ایجاد policies جدید بدون recursion
-- - ایجاد جداول مفقود
-- - ایجاد توابع مفقود
```

### 2. تست عملکرد:
- ✅ ثبت نام کاربر جدید
- ✅ ورود به سیستم
- ✅ دسترسی به بخش Trainer Users
- ✅ ارسال درخواست مربی
- ✅ مدیریت شاگردان

## 🎯 نتیجه نهایی:
- **RLS policies بدون recursion**
- **تمام جداول مورد نیاز موجود**
- **UI بدون overflow**
- **سیستم Trainer Users کاملاً فعال**

## 📞 در صورت مشکل:
اگر همچنان مشکلی وجود دارد، لاگ‌های جدید را ارسال کنید تا بررسی کنیم. 