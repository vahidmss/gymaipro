-- تست جدول notification settings
-- این فایل جدول user_notification_settings را تست می‌کند

-- 1. بررسی ساختار جدول
SELECT 'Checking table structure' as step;
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. بررسی RLS policies
SELECT 'Checking RLS policies' as step;
SELECT 
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies 
WHERE tablename = 'user_notification_settings'
ORDER BY policyname;

-- 3. بررسی triggers
SELECT 'Checking triggers' as step;
SELECT 
    trigger_name,
    event_manipulation,
    action_timing,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'user_notification_settings'
ORDER BY trigger_name;

-- 4. بررسی functions
SELECT 'Checking functions' as step;
SELECT 
    routine_name,
    routine_type,
    routine_definition
FROM information_schema.routines 
WHERE routine_schema = 'public' 
    AND routine_name LIKE '%notification%'
ORDER BY routine_name;

-- 5. تست function get_user_notification_settings
SELECT 'Testing get_user_notification_settings function' as step;
-- این query فقط برای تست است و باید با یک UUID واقعی اجرا شود
-- SELECT * FROM public.get_user_notification_settings('00000000-0000-0000-0000-000000000000'::uuid);

-- 6. تست function update_user_notification_settings
SELECT 'Testing update_user_notification_settings function' as step;
-- این query فقط برای تست است و باید با یک UUID واقعی اجرا شود
-- SELECT public.update_user_notification_settings(
--     '00000000-0000-0000-0000-000000000000'::uuid,
--     true,  -- chat_notifications
--     false, -- workout_notifications
--     true,  -- friend_request_notifications
--     false, -- trainer_request_notifications
--     true,  -- trainer_message_notifications
--     true,  -- general_notifications
--     true,  -- sound_enabled
--     false, -- vibration_enabled
--     '22:00:00'::time, -- quiet_start_time
--     '08:00:00'::time  -- quiet_end_time
-- );

-- 7. بررسی دسترسی‌ها
SELECT 'Checking permissions' as step;
SELECT 
    grantee,
    privilege_type,
    is_grantable
FROM information_schema.table_privileges 
WHERE table_name = 'user_notification_settings' 
    AND table_schema = 'public'
ORDER BY grantee, privilege_type;

-- 8. تست INSERT ساده (با rollback)
SELECT 'Testing INSERT operation' as step;
BEGIN;
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
    '00000000-0000-0000-0000-000000000001'::uuid,
    true,
    true,
    true,
    true,
    true,
    true,
    true,
    true
);
SELECT 'Test insert successful' as result;
ROLLBACK;

-- 9. تست UPDATE ساده (با rollback)
SELECT 'Testing UPDATE operation' as step;
BEGIN;
INSERT INTO public.user_notification_settings (
    user_id,
    chat_notifications,
    workout_notifications
) VALUES (
    '00000000-0000-0000-0000-000000000002'::uuid,
    true,
    true
);
UPDATE public.user_notification_settings
SET chat_notifications = false
WHERE user_id = '00000000-0000-0000-0000-000000000002'::uuid;
SELECT 'Test update successful' as result;
ROLLBACK;

-- 10. تست DELETE ساده (با rollback)
SELECT 'Testing DELETE operation' as step;
BEGIN;
INSERT INTO public.user_notification_settings (
    user_id,
    chat_notifications
) VALUES (
    '00000000-0000-0000-0000-000000000003'::uuid,
    true
);
DELETE FROM public.user_notification_settings
WHERE user_id = '00000000-0000-0000-0000-000000000003'::uuid;
SELECT 'Test delete successful' as result;
ROLLBACK;

SELECT 'Notification settings table test completed successfully' as result;
