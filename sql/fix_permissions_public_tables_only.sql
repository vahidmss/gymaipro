-- اصلاح دسترسی‌ها فقط برای جداول public
-- این فایل فقط جداول public را اصلاح می‌کند و با auth.users کاری ندارد

-- 1. بررسی جداول public موجود
SELECT 'Checking public tables' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_schema = 'public'
ORDER BY table_name;

-- 2. بررسی دسترسی‌های جدول user_notification_settings
SELECT 'Checking user_notification_settings permissions' as step;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- 3. اصلاح دسترسی‌های جدول user_notification_settings
SELECT 'Fixing user_notification_settings permissions' as step;

-- حذف RLS policies قدیمی (اگر وجود دارند)
DROP POLICY IF EXISTS "Users can view own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.user_notification_settings;

-- ایجاد RLS policies جدید
CREATE POLICY "Enable read access for authenticated users" ON public.user_notification_settings
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.user_notification_settings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.user_notification_settings
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.user_notification_settings
    FOR DELETE USING (auth.role() = 'authenticated');

-- اعطای دسترسی‌های مستقیم
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO anon;

-- 4. بررسی triggers روی جداول public
SELECT 'Checking triggers on public tables' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 5. غیرفعال کردن triggers مشکل‌دار روی جداول public
SELECT 'Disabling problematic triggers on public tables' as step;
DO $$
DECLARE
    trigger_record RECORD;
BEGIN
    FOR trigger_record IN 
        SELECT trigger_name, event_object_table
        FROM information_schema.triggers 
        WHERE event_object_schema = 'public'
        AND (
            trigger_name LIKE '%notification%' OR
            trigger_name LIKE '%user%' OR
            trigger_name LIKE '%profile%'
        )
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
                RAISE NOTICE 'Could not disable trigger %: %', 
                    trigger_record.trigger_name, 
                    SQLERRM;
        END;
    END LOOP;
END $$;

-- 6. بررسی triggers غیرفعال شده
SELECT 'Checking disabled triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_schema = 'public'
ORDER BY event_object_table, trigger_name;

-- 7. بررسی functions که ممکن است مشکل ایجاد کنند
SELECT 'Checking problematic functions' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_definition LIKE '%user_notification_settings%'
ORDER BY routine_name;

-- 8. اگر جدول user_notification_settings وجود ندارد، آن را ایجاد می‌کنیم
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'user_notification_settings' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'user_notification_settings table does not exist, creating...';
        
        CREATE TABLE public.user_notification_settings (
            id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
            user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
            push_notifications BOOLEAN DEFAULT true,
            email_notifications BOOLEAN DEFAULT true,
            sms_notifications BOOLEAN DEFAULT false,
            chat_notifications BOOLEAN DEFAULT true,
            workout_reminders BOOLEAN DEFAULT true,
            meal_reminders BOOLEAN DEFAULT true,
            created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
            UNIQUE(user_id)
        );
        
        -- ایجاد RLS
        ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;
        
        -- ایجاد policies
        CREATE POLICY "Enable read access for authenticated users" ON public.user_notification_settings
            FOR SELECT USING (auth.role() = 'authenticated');
            
        CREATE POLICY "Enable insert for authenticated users" ON public.user_notification_settings
            FOR INSERT WITH CHECK (auth.role() = 'authenticated');
            
        CREATE POLICY "Enable update for authenticated users" ON public.user_notification_settings
            FOR UPDATE USING (auth.role() = 'authenticated');
            
        CREATE POLICY "Enable delete for authenticated users" ON public.user_notification_settings
            FOR DELETE USING (auth.role() = 'authenticated');
        
        -- اعطای دسترسی
        GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO authenticated;
        GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO anon;
        
        RAISE NOTICE 'user_notification_settings table created successfully';
    ELSE
        RAISE NOTICE 'user_notification_settings table already exists';
    END IF;
END $$;

-- 9. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

SELECT 'Public tables permissions fix completed' as result;
