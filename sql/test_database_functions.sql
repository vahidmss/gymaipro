-- تست توابع database برای تشخیص مشکلات authentication
-- این فایل برای تست توابع موجود و تشخیص مشکلات استفاده می‌شود

-- 1. تست تابع check_user_exists
SELECT 'Testing check_user_exists function' as test_name;
SELECT public.check_user_exists('09123456789') as result;

-- 2. تست تابع check_user_exists_by_phone
SELECT 'Testing check_user_exists_by_phone function' as test_name;
SELECT public.check_user_exists_by_phone('09123456789') as result;

-- 3. تست تابع create_user_profile با یک UUID تستی
-- (این query فقط برای تست است و باید با یک UUID واقعی اجرا شود)
SELECT 'Testing create_user_profile function' as test_name;
SELECT public.create_user_profile(
    '00000000-0000-0000-0000-000000000000'::uuid,
    'test_user_debug',
    '09123456789',
    'test_debug@example.com'
) as result;

-- 4. بررسی ساختار جدول profiles
SELECT 'Checking profiles table structure' as test_name;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'profiles' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. بررسی RLS policies
SELECT 'Checking RLS policies' as test_name;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd
FROM pg_policies 
WHERE tablename = 'profiles'
ORDER BY policyname;

-- 6. بررسی constraints
SELECT 'Checking constraints' as test_name;
SELECT 
    tc.constraint_name,
    tc.constraint_type,
    kcu.column_name
FROM information_schema.table_constraints AS tc 
LEFT JOIN information_schema.key_column_usage AS kcu
    ON tc.constraint_name = kcu.constraint_name
    AND tc.table_schema = kcu.table_schema
WHERE tc.table_name = 'profiles' 
    AND tc.table_schema = 'public'
ORDER BY tc.constraint_type, tc.constraint_name;

-- 7. تست دسترسی به جدول profiles
SELECT 'Testing profiles table access' as test_name;
SELECT COUNT(*) as profile_count FROM public.profiles;

-- 8. بررسی auth.users table
SELECT 'Checking auth.users table' as test_name;
SELECT COUNT(*) as user_count FROM auth.users;

-- 9. تست INSERT ساده (با rollback)
BEGIN;
INSERT INTO public.profiles (
    id,
    username,
    phone_number,
    role
) VALUES (
    '00000000-0000-0000-0000-000000000001'::uuid,
    'test_insert_user',
    '09999999999',
    'athlete'
);
SELECT 'Test insert successful' as result;
ROLLBACK;

-- 10. بررسی لاگ‌های خطا (اگر دسترسی admin دارید)
-- SELECT 'Checking error logs' as test_name;
-- SELECT 
--     log_time,
--     error_severity,
--     message
-- FROM pg_log 
-- WHERE message LIKE '%profiles%' 
--     OR message LIKE '%auth%'
-- ORDER BY log_time DESC 
-- LIMIT 5;
