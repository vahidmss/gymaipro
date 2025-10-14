-- ایجاد جدول notification settings ساده
-- این فایل یک جدول ساده برای notification settings ایجاد می‌کند

-- 1. حذف جدول قدیمی (اگر وجود دارد)
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

-- 2. ایجاد جدول جدید با ساختار ساده
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

-- 3. فعال کردن RLS
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 4. ایجاد RLS policies ساده
CREATE POLICY "Users can view own notification settings" ON public.user_notification_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own notification settings" ON public.user_notification_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own notification settings" ON public.user_notification_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete own notification settings" ON public.user_notification_settings
    FOR DELETE USING (auth.uid() = user_id);

-- 5. اعطای دسترسی‌های مستقیم
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.user_notification_settings TO anon;

-- 6. ایجاد function ساده برای ایجاد default settings
CREATE OR REPLACE FUNCTION public.create_default_notification_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    INSERT INTO public.user_notification_settings (
        user_id,
        push_notifications,
        email_notifications,
        sms_notifications,
        chat_notifications,
        workout_reminders,
        meal_reminders
    ) VALUES (
        NEW.id,
        true,
        true,
        false,
        true,
        true,
        true
    );
    RETURN NEW;
END;
$$;

-- 7. ایجاد trigger ساده
CREATE TRIGGER create_default_notification_settings_trigger
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.create_default_notification_settings();

-- 8. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

SELECT 'Simple notification settings table created successfully' as result;
