-- راه‌حل ساده برای مشکل user_notification_settings
-- این فایل فقط دسترسی‌های لازم را اصلاح می‌کند

-- 1. بررسی وجود جدول user_notification_settings
SELECT 'Checking if user_notification_settings table exists' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

-- 2. اگر جدول وجود ندارد، آن را ایجاد می‌کنیم
DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.tables 
        WHERE table_name = 'user_notification_settings' 
        AND table_schema = 'public'
    ) THEN
        RAISE NOTICE 'Creating user_notification_settings table...';
        
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
        
        RAISE NOTICE 'user_notification_settings table created successfully';
    ELSE
        RAISE NOTICE 'user_notification_settings table already exists';
    END IF;
END $$;

-- 3. حذف تمام RLS policies قدیمی
DROP POLICY IF EXISTS "Users can view own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can insert own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can update own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Users can delete own notification settings" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable read access for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable update for authenticated users" ON public.user_notification_settings;
DROP POLICY IF EXISTS "Enable delete for authenticated users" ON public.user_notification_settings;

-- 4. ایجاد RLS policies جدید
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

-- 6. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

SELECT 'User notification settings permissions fixed successfully' as result;
