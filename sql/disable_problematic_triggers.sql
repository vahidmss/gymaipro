-- غیرفعال کردن موقت triggers مشکل‌دار
-- این فایل triggers که ممکن است مشکل ایجاد کنند را غیرفعال می‌کند

-- 1. بررسی triggers موجود
SELECT 'Checking existing triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_object_schema,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema IN ('public', 'auth')
ORDER BY event_object_schema, event_object_table, trigger_name;

-- 2. غیرفعال کردن triggers روی جدول auth.users
SELECT 'Disabling triggers on auth.users' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'users' 
        AND event_object_schema = 'auth'
    LOOP
        EXECUTE format('ALTER TABLE auth.users DISABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Disabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 3. غیرفعال کردن triggers روی جدول profiles
SELECT 'Disabling triggers on profiles' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'profiles' 
        AND event_object_schema = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.profiles DISABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Disabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 4. غیرفعال کردن triggers روی جدول user_notification_settings
SELECT 'Disabling triggers on user_notification_settings' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name 
        FROM information_schema.triggers 
        WHERE event_object_table = 'user_notification_settings' 
        AND event_object_schema = 'public'
    LOOP
        EXECUTE format('ALTER TABLE public.user_notification_settings DISABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Disabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 5. بررسی triggers غیرفعال شده
SELECT 'Checking disabled triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_object_schema,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema IN ('public', 'auth')
ORDER BY event_object_schema, event_object_table, trigger_name;

-- 6. تست ثبت نام کاربر (اختیاری)
-- این query فقط برای تست است و باید با یک UUID واقعی اجرا شود
-- SELECT 'Testing user registration without triggers' as step;
-- SELECT public.create_user_profile(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     'test_user_no_triggers',
--     '09123456789',
--     'test_no_triggers@example.com'
-- );

SELECT 'Problematic triggers disabled successfully' as result;
