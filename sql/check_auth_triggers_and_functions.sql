-- بررسی triggers و functions که ممکن است در هنگام ثبت نام مشکل ایجاد کنند
-- این فایل برای تشخیص triggers و functions مشکل‌دار استفاده می‌شود

-- 1. بررسی تمام triggers روی جدول auth.users
SELECT 'Checking triggers on auth.users' as step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'users'
    AND event_object_schema = 'auth'
ORDER BY trigger_name;

-- 2. بررسی triggers روی جدول profiles
SELECT 'Checking triggers on profiles' as step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'profiles'
    AND event_object_schema = 'public'
ORDER BY trigger_name;

-- 3. بررسی functions که ممکن است در هنگام ثبت نام اجرا شوند
SELECT 'Checking functions that might run during signup' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%user_notification_settings%' OR
        routine_definition LIKE '%profiles%' OR
        routine_definition LIKE '%auth.users%' OR
        routine_definition LIKE '%INSERT%' OR
        routine_definition LIKE '%CREATE%'
    )
ORDER BY routine_name;

-- 4. بررسی functions که ممکن است به user_notification_settings دسترسی داشته باشند
SELECT 'Checking functions accessing user_notification_settings' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_definition LIKE '%user_notification_settings%'
ORDER BY routine_name;

-- 5. بررسی functions که ممکن است در هنگام INSERT روی profiles اجرا شوند
SELECT 'Checking functions that might run on profiles INSERT' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_definition LIKE '%profiles%'
    AND routine_definition LIKE '%INSERT%'
ORDER BY routine_name;

-- 6. بررسی functions که ممکن است در هنگام INSERT روی auth.users اجرا شوند
SELECT 'Checking functions that might run on auth.users INSERT' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_definition LIKE '%auth.users%'
    AND routine_definition LIKE '%INSERT%'
ORDER BY routine_name;

-- 7. بررسی functions که ممکن است notification settings ایجاد کنند
SELECT 'Checking functions that create notification settings' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%notification%' OR
        routine_definition LIKE '%settings%'
    )
ORDER BY routine_name;

-- 8. بررسی functions که ممکن است default values ایجاد کنند
SELECT 'Checking functions that create default values' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%default%' OR
        routine_definition LIKE '%create%' OR
        routine_definition LIKE '%insert%'
    )
ORDER BY routine_name;

-- 9. بررسی functions که ممکن است در هنگام ثبت نام کاربر اجرا شوند
SELECT 'Checking functions that might run during user registration' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%signup%' OR
        routine_definition LIKE '%register%' OR
        routine_definition LIKE '%user%' OR
        routine_definition LIKE '%profile%'
    )
ORDER BY routine_name;

-- 10. بررسی functions که ممکن است در هنگام ایجاد پروفایل اجرا شوند
SELECT 'Checking functions that might run during profile creation' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%profile%' OR
        routine_definition LIKE '%user%' OR
        routine_definition LIKE '%create%'
    )
ORDER BY routine_name;
