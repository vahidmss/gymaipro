-- تست نمایش badge مالک باشگاه
-- این فایل برای تست عملکرد badge مالک باشگاه استفاده می‌شود

-- 1. بررسی ساختار جدول profiles
SELECT 'Checking profiles table structure' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
    AND column_name = 'is_gym_owner'
ORDER BY ordinal_position;

-- 2. بررسی مربیان موجود
SELECT 'Checking existing trainers' as step;
SELECT 
    id,
    username,
    first_name,
    last_name,
    role,
    is_gym_owner
FROM public.profiles 
WHERE role = 'trainer'
ORDER BY ranking ASC
LIMIT 5;

-- 3. تنظیم یک مربی به عنوان مالک باشگاه (برای تست)
-- توجه: این query فقط برای تست است و باید با ID واقعی اجرا شود
UPDATE public.profiles 
SET is_gym_owner = true,
    updated_at = NOW()
WHERE role = 'trainer' 
    AND username IS NOT NULL
LIMIT 1;

-- 4. بررسی مربیان با وضعیت مالک باشگاه
SELECT 'Checking gym owners' as step;
SELECT 
    id,
    username,
    first_name,
    last_name,
    is_gym_owner,
    ranking
FROM public.profiles 
WHERE role = 'trainer' 
    AND is_gym_owner = true
ORDER BY ranking ASC;
