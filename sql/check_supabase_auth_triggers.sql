-- بررسی triggers و functions در Supabase Auth system
-- این فایل triggers و functions که در auth schema هستند را بررسی می‌کند

-- 1. بررسی triggers در auth schema
SELECT 'Checking triggers in auth schema' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_schema = 'auth'
ORDER BY event_object_table, trigger_name;

-- 2. بررسی functions در auth schema
SELECT 'Checking functions in auth schema' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'auth'
    AND routine_definition LIKE '%user_notification_settings%'
ORDER BY routine_name;

-- 3. بررسی functions در public schema که ممکن است از auth فراخوانی شوند
SELECT 'Checking public functions that might be called from auth' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
    AND (
        routine_definition LIKE '%user_notification_settings%' OR
        routine_definition LIKE '%notification%' OR
        routine_definition LIKE '%INSERT%' OR
        routine_definition LIKE '%CREATE%'
    )
ORDER BY routine_name;

-- 4. بررسی functions که ممکن است در هنگام user signup اجرا شوند
SELECT 'Checking functions that might run during user signup' as step;
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

-- 5. بررسی functions که ممکن است default values ایجاد کنند
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

-- 6. بررسی functions که ممکن است در هنگام INSERT روی auth.users اجرا شوند
SELECT 'Checking functions that might run on auth.users INSERT' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
    AND routine_definition LIKE '%auth.users%'
ORDER BY routine_name;

-- 7. بررسی functions که ممکن است در هنگام INSERT روی profiles اجرا شوند
SELECT 'Checking functions that might run on profiles INSERT' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public'
    AND routine_definition LIKE '%profiles%'
ORDER BY routine_name;

-- 8. بررسی functions که ممکن است notification settings ایجاد کنند
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

-- 9. بررسی functions که ممکن است در هنگام ایجاد پروفایل اجرا شوند
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

-- 10. بررسی functions که ممکن است در هنگام ثبت نام کاربر اجرا شوند
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
