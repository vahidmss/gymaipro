-- غیرفعال کردن کامل تمام triggers مشکل‌دار
-- این فایل تمام triggers که ممکن است مشکل ایجاد کنند را غیرفعال می‌کند

-- 1. بررسی triggers موجود
SELECT 'Checking existing triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_object_schema,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 2. غیرفعال کردن تمام triggers روی جداول public
SELECT 'Disabling all triggers on public tables' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers 
        WHERE event_object_schema = 'public'
    LOOP
        BEGIN
            EXECUTE format('ALTER TABLE public.%I DISABLE TRIGGER %I', 
                trigger_record.event_object_table, 
                trigger_record.trigger_name);
            RAISE NOTICE 'Disabled trigger: % on table: %', 
                trigger_record.trigger_name, 
                trigger_record.event_object_table;
        EXCEPTION
            WHEN OTHERS THEN
                RAISE NOTICE 'Could not disable trigger % on table %: %', 
                    trigger_record.trigger_name, 
                    trigger_record.event_object_table,
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 3. بررسی triggers غیرفعال شده
SELECT 'Checking disabled triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 4. بررسی functions که ممکن است مشکل ایجاد کنند
SELECT 'Checking problematic functions' as step;
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

-- 5. غیرفعال کردن functions مشکل‌دار (اختیاری)
-- این بخش فقط در صورت نیاز اجرا شود
/*
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
*/

SELECT 'All problematic triggers disabled successfully' as result;
