-- فعال کردن مجدد triggers بعد از اصلاح مشکل
-- این فایل triggers را دوباره فعال می‌کند

-- 1. بررسی triggers غیرفعال
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

-- 2. فعال کردن triggers روی جدول auth.users
SELECT 'Enabling triggers on auth.users' as step;
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
        EXECUTE format('ALTER TABLE auth.users ENABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Enabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 3. فعال کردن triggers روی جدول profiles
SELECT 'Enabling triggers on profiles' as step;
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
        EXECUTE format('ALTER TABLE public.profiles ENABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Enabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 4. فعال کردن triggers روی جدول user_notification_settings
SELECT 'Enabling triggers on user_notification_settings' as step;
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
        EXECUTE format('ALTER TABLE public.user_notification_settings ENABLE TRIGGER %I', trigger_record.trigger_name);
        RAISE NOTICE 'Enabled trigger: %', trigger_record.trigger_name;
    END LOOP;
END $$;

-- 5. بررسی triggers فعال شده
SELECT 'Checking enabled triggers' as step;
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
-- SELECT 'Testing user registration with triggers' as step;
-- SELECT public.create_user_profile(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     'test_user_with_triggers',
--     '09123456789',
--     'test_with_triggers@example.com'
-- );

SELECT 'Triggers enabled successfully' as result;
