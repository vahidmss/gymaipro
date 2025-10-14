-- ایجاد جدول notification settings مناسب با مقادیر پیش‌فرض
-- این فایل جدول user_notification_settings را با ساختار مناسب ایجاد می‌کند

-- 1. حذف جدول قدیمی (اگر وجود دارد)
DROP TABLE IF EXISTS public.user_notification_settings CASCADE;

-- 2. ایجاد جدول جدید با ساختار مناسب
CREATE TABLE public.user_notification_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    
    -- تنظیمات انواع اعلان‌ها
    chat_notifications BOOLEAN DEFAULT true,
    workout_notifications BOOLEAN DEFAULT true,
    friend_request_notifications BOOLEAN DEFAULT true,
    trainer_request_notifications BOOLEAN DEFAULT true,
    trainer_message_notifications BOOLEAN DEFAULT true,
    general_notifications BOOLEAN DEFAULT true,
    
    -- تنظیمات صدا و لرزش
    sound_enabled BOOLEAN DEFAULT true,
    vibration_enabled BOOLEAN DEFAULT true,
    
    -- تنظیمات زمان سکوت (اختیاری)
    quiet_start_time TIME,
    quiet_end_time TIME,
    
    -- timestamps
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    -- unique constraint
    UNIQUE(user_id)
);

-- 3. فعال کردن RLS
ALTER TABLE public.user_notification_settings ENABLE ROW LEVEL SECURITY;

-- 4. ایجاد RLS policies
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

-- 6. ایجاد function برای ایجاد default settings
CREATE OR REPLACE FUNCTION public.create_default_notification_settings()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    -- ایجاد تنظیمات پیش‌فرض برای کاربر جدید
    INSERT INTO public.user_notification_settings (
        user_id,
        chat_notifications,
        workout_notifications,
        friend_request_notifications,
        trainer_request_notifications,
        trainer_message_notifications,
        general_notifications,
        sound_enabled,
        vibration_enabled
    ) VALUES (
        NEW.id,
        true,  -- chat_notifications
        true,  -- workout_notifications
        true,  -- friend_request_notifications
        true,  -- trainer_request_notifications
        true,  -- trainer_message_notifications
        true,  -- general_notifications
        true,  -- sound_enabled
        true   -- vibration_enabled
    );
    
    RETURN NEW;
END;
$$;

-- 7. ایجاد trigger برای ایجاد default settings
CREATE TRIGGER create_default_notification_settings_trigger
    AFTER INSERT ON public.profiles
    FOR EACH ROW
    EXECUTE FUNCTION public.create_default_notification_settings();

-- 8. ایجاد function برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION public.update_notification_settings_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

-- 9. ایجاد trigger برای به‌روزرسانی updated_at
CREATE TRIGGER update_notification_settings_updated_at_trigger
    BEFORE UPDATE ON public.user_notification_settings
    FOR EACH ROW
    EXECUTE FUNCTION public.update_notification_settings_updated_at();

-- 10. ایجاد function برای دریافت تنظیمات کاربر
CREATE OR REPLACE FUNCTION public.get_user_notification_settings(p_user_id UUID)
RETURNS TABLE (
    id UUID,
    user_id UUID,
    chat_notifications BOOLEAN,
    workout_notifications BOOLEAN,
    friend_request_notifications BOOLEAN,
    trainer_request_notifications BOOLEAN,
    trainer_message_notifications BOOLEAN,
    general_notifications BOOLEAN,
    sound_enabled BOOLEAN,
    vibration_enabled BOOLEAN,
    quiet_start_time TIME,
    quiet_end_time TIME,
    created_at TIMESTAMP WITH TIME ZONE,
    updated_at TIMESTAMP WITH TIME ZONE
)
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        uns.id,
        uns.user_id,
        uns.chat_notifications,
        uns.workout_notifications,
        uns.friend_request_notifications,
        uns.trainer_request_notifications,
        uns.trainer_message_notifications,
        uns.general_notifications,
        uns.sound_enabled,
        uns.vibration_enabled,
        uns.quiet_start_time,
        uns.quiet_end_time,
        uns.created_at,
        uns.updated_at
    FROM public.user_notification_settings uns
    WHERE uns.user_id = p_user_id;
END;
$$;

-- 11. اعطای دسترسی به function
GRANT EXECUTE ON FUNCTION public.get_user_notification_settings(UUID) TO authenticated;
GRANT EXECUTE ON FUNCTION public.get_user_notification_settings(UUID) TO anon;

-- 12. ایجاد function برای به‌روزرسانی تنظیمات
CREATE OR REPLACE FUNCTION public.update_user_notification_settings(
    p_user_id UUID,
    p_chat_notifications BOOLEAN DEFAULT NULL,
    p_workout_notifications BOOLEAN DEFAULT NULL,
    p_friend_request_notifications BOOLEAN DEFAULT NULL,
    p_trainer_request_notifications BOOLEAN DEFAULT NULL,
    p_trainer_message_notifications BOOLEAN DEFAULT NULL,
    p_general_notifications BOOLEAN DEFAULT NULL,
    p_sound_enabled BOOLEAN DEFAULT NULL,
    p_vibration_enabled BOOLEAN DEFAULT NULL,
    p_quiet_start_time TIME DEFAULT NULL,
    p_quiet_end_time TIME DEFAULT NULL
)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
BEGIN
    UPDATE public.user_notification_settings
    SET 
        chat_notifications = COALESCE(p_chat_notifications, chat_notifications),
        workout_notifications = COALESCE(p_workout_notifications, workout_notifications),
        friend_request_notifications = COALESCE(p_friend_request_notifications, friend_request_notifications),
        trainer_request_notifications = COALESCE(p_trainer_request_notifications, trainer_request_notifications),
        trainer_message_notifications = COALESCE(p_trainer_message_notifications, trainer_message_notifications),
        general_notifications = COALESCE(p_general_notifications, general_notifications),
        sound_enabled = COALESCE(p_sound_enabled, sound_enabled),
        vibration_enabled = COALESCE(p_vibration_enabled, vibration_enabled),
        quiet_start_time = COALESCE(p_quiet_start_time, quiet_start_time),
        quiet_end_time = COALESCE(p_quiet_end_time, quiet_end_time),
        updated_at = NOW()
    WHERE user_id = p_user_id;
    
    RETURN FOUND;
END;
$$;

-- 13. اعطای دسترسی به function
GRANT EXECUTE ON FUNCTION public.update_user_notification_settings(UUID, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, TIME, TIME) TO authenticated;
GRANT EXECUTE ON FUNCTION public.update_user_notification_settings(UUID, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, BOOLEAN, TIME, TIME) TO anon;

-- 14. بررسی نهایی
SELECT 'Final verification' as step;
SELECT 
    table_name,
    table_schema
FROM information_schema.tables 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public';

-- 15. بررسی functions ایجاد شده
SELECT 'Checking created functions' as step;
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 16. بررسی triggers ایجاد شده
SELECT 'Checking created triggers' as step;
SELECT 
    trigger_name,
    event_object_table,
    event_manipulation,
    action_timing
FROM information_schema.triggers 
WHERE event_object_table = 'user_notification_settings'
ORDER BY trigger_name;

SELECT 'Proper notification settings table created successfully' as result;
