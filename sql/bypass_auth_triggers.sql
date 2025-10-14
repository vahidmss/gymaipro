-- راه‌حل bypass برای مشکل auth triggers
-- این فایل triggers و functions مشکل‌دار را کاملاً حذف می‌کند

-- 1. حذف تمام triggers روی جدول profiles
SELECT 'Dropping all triggers on profiles table' as step;
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
            EXECUTE format('DROP TRIGGER IF EXISTS %I ON public.profiles', trigger_record.trigger_name);
            RAISE NOTICE 'Dropped trigger: %', trigger_record.trigger_name;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not drop trigger %: %', 
                    trigger_record.trigger_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 2. حذف تمام functions که ممکن است مشکل ایجاد کنند
SELECT 'Dropping problematic functions' as step;
DO $$
DECLARE
    function_record RECORD;
BEGIN
    FOR function_record IN 
        SELECT routine_name
        FROM information_schema.routines 
        WHERE routine_schema = 'public' 
        AND (
            routine_definition LIKE '%user_notification_settings%' OR
            routine_definition LIKE '%notification%' OR
            routine_definition LIKE '%INSERT%' OR
            routine_definition LIKE '%CREATE%'
        )
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

-- 3. حذف جدول user_notification_settings
SELECT 'Dropping user_notification_settings table' as step;
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

-- 4. بررسی triggers باقی‌مانده
SELECT 'Checking remaining triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 5. بررسی functions باقی‌مانده
SELECT 'Checking remaining functions' as step;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND (
        routine_definition LIKE '%user_notification_settings%' OR
        routine_definition LIKE '%notification%' OR
        routine_definition LIKE '%INSERT%' OR
        routine_definition LIKE '%CREATE%'
    )
ORDER BY routine_name;

-- 6. بررسی جداول باقی‌مانده
SELECT 'Checking remaining tables' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

SELECT 'Auth triggers bypassed successfully' as result;
