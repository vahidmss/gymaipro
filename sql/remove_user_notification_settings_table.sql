-- حذف کامل جدول user_notification_settings
-- این فایل جدول user_notification_settings را کاملاً حذف می‌کند

-- 1. بررسی وجود جدول user_notification_settings
SELECT 'Checking if user_notification_settings table exists' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

-- 2. حذف تمام RLS policies روی جدول user_notification_settings
SELECT 'Dropping RLS policies on user_notification_settings' as step;
DROP POLICY IF EXISTS "Users can view own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.user_notification_settings;

-- 3. حذف تمام triggers روی جدول user_notification_settings
SELECT 'Dropping triggers on user_notification_settings' as step;
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
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.user_notification_settings', trigger_record.trigger_name);
            RAISE NOTICE 'Dropped trigger: %', trigger_record.trigger_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop trigger %: %', 
                    trigger_record.trigger_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 4. حذف تمام functions که به user_notification_settings دسترسی دارند
SELECT 'Dropping functions that access user_notification_settings' as step;
DO $$
DECLARE
    function_record RECORD;
BEGIN
    FOR function_record IN 
        SELECT routine_name
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND routine_definition LIKE '%user_notification_settings%'
    LOOP
        BEGIN
            EXECUTE format('DROP FUNCTION IF EXISTS public.%I CASCADE', function_record.routine_name);
            RAISE NOTICE 'Dropped function: %', function_record.routine_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop function %: %', 
                    function_record.routine_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 5. حذف کامل جدول user_notification_settings
SELECT 'Dropping user_notification_settings table' as step;
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

-- 6. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

-- 7. بررسی functions باقی‌مانده
SELECT 'Checking remaining functions' as step;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_definition LIKE '%user_notification_settings%'
ORDER BY routine_name;

SELECT 'User notification settings table removed successfully' as result;
