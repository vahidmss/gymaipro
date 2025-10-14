-- بررسی مشکلات authentication و registration
-- این فایل برای تشخیص مشکلات database functions و RLS policies استفاده می‌شود

-- 1. بررسی وجود توابع مورد نیاز
SELECT 
    routine_name,
    routine_type,
    data_type as return_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name IN ('create_user_profile', 'check_user_exists', 'check_user_exists_by_phone')
ORDER BY routine_name;

-- 2. بررسی RLS policies روی جدول profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- 3. بررسی ساختار جدول profiles
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default,
    character_maximum_length
FROM information_schema.columns 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 4. بررسی constraints روی جدول profiles
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name,
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name
FROM information_schema.table_constraints AS tc 
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
LEFT JOIN information_schema.constraint_column_usage AS ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.table_name = 'profiles' 
    AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 5. بررسی دسترسی‌های کاربران
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- 6. تست تابع create_user_profile با یک UUID تستی
-- (این query فقط برای تست است و باید با یک UUID واقعی اجرا شود)
-- SELECT public.create_user_profile(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     'test_user',
--     '09123456789',
--     'test@example.com'
-- );

-- 7. بررسی لاگ‌های خطا در PostgreSQL
-- (این query نیاز به دسترسی admin دارد)
-- SELECT 
--     log_time,
--     error_severity,
--     message
-- FROM pg_log 
-- WHERE message LIKE '%profiles%' 
--     OR message LIKE '%auth%'
-- ORDER BY log_time DESC 
-- LIMIT 10;
