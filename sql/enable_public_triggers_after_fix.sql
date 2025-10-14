-- فعال کردن مجدد triggers فقط روی جداول public
-- این فایل فقط triggers جداول public را فعال می‌کند

-- 1. بررسی triggers غیرفعال روی جداول public
SELECT 'Checking disabled triggers on public tables' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 2. فعال کردن triggers روی جدول profiles
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
        BEGIN
            EXECUTE format('ALTER TABLE public.profiles ENABLE TRIGGER %I', trigger_record.trigger_name);
            RAISE NOTICE 'Enabled trigger: %', trigger_record.trigger_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not enable trigger %: %', 
                    trigger_record.trigger_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. فعال کردن triggers روی جدول user_notification_settings
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
        BEGIN
            EXECUTE format('ALTER TABLE public.user_notification_settings ENABLE TRIGGER %I', trigger_record.trigger_name);
            RAISE NOTICE 'Enabled trigger: %', trigger_record.trigger_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not enable trigger %: %', 
                    trigger_record.trigger_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 4. فعال کردن سایر triggers روی جداول public
SELECT 'Enabling other triggers on public tables' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers 
        WHERE event_object_schema = 'public'
        AND event_object_table NOT IN ('profiles', 'user_notification_settings')
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I ENABLE TRIGGER %I', 
                trigger_record.event_object_table, 
                trigger_record.trigger_name);
            RAISE NOTICE 'Enabled trigger: % on table: %', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not enable trigger % on table %: %', 
                    trigger_record.trigger_name, 
                    trigger_record.event_object_table,
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 5. بررسی triggers فعال شده
SELECT 'Checking enabled triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 6. تست ثبت نام کاربر (اختیاری)
-- این query فقط برای تست است و باید با یک UUID واقعی اجرا شود
-- SELECT 'Testing user registration with public triggers' as step;
-- SELECT public.create_user_profile(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     'test_user_with_public_triggers',
--     '09123456789',
--     'test_with_public_triggers@example.com'
-- );

SELECT 'Public triggers enabled successfully' as result;
