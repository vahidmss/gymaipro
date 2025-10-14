-- اصلاح مشکل دسترسی به جدول user_notification_settings
-- این فایل مشکل permission denied را حل می‌کند

-- 1. بررسی وجود جدول user_notification_settings
SELECT 'Checking user_notification_settings table' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

-- 2. بررسی RLS policies روی جدول user_notification_settings
SELECT 'Checking RLS policies on user_notification_settings' as step;
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'user_notification_settings'
ORDER BY policyname;

-- 3. بررسی دسترسی‌های کاربران به جدول user_notification_settings
SELECT 'Checking permissions on user_notification_settings' as step;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- 4. اصلاح دسترسی‌ها - اعطای دسترسی کامل به authenticated users
SELECT 'Fixing permissions on user_notification_settings' as step;

-- حذف RLS policies قدیمی (اگر وجود دارند)
DROP POLICY IF EXISTS "Users can view own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification settings" ON public.user_notification_settings;

-- ایجاد RLS policies جدید
CREATE POLICY "Enable read access for authenticated users" ON public.user_notification_settings
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Enable insert for authenticated users" ON public.user_notification_settings
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Enable update for authenticated users" ON public.user_notification_settings
    FOR UPDATE USING (auth.role() = 'authenticated');

CREATE POLICY "Enable delete for authenticated users" ON public.user_notification_settings
    FOR DELETE USING (auth.role() = 'authenticated');

-- 5. اعطای دسترسی‌های مستقیم
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO anon;

-- 6. بررسی triggers روی جدول user_notification_settings
SELECT 'Checking triggers on user_notification_settings' as step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'user_notification_settings'
ORDER BY trigger_name;

-- 7. بررسی functions که ممکن است به user_notification_settings دسترسی داشته باشند
SELECT 'Checking functions that might access user_notification_settings' as step;
SELECT 
    routine_name,
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
        CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
            FOR SELECT USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
            FOR INSERT WITH CHECK (auth.uid() = user_id);
            
        CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
            FOR UPDATE USING (auth.uid() = user_id);
            
        CREATE POLICY "Users can delete own notification settings" ON public.user_notification_settings
            FOR DELETE USING (auth.uid() = user_id);
        
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

SELECT 'User notification settings permissions fix completed' as result;
