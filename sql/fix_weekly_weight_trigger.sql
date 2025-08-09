-- حذف تریگر مشکل‌ساز
DROP TRIGGER IF EXISTS check_weekly_weight_limit_trigger ON public.weekly_weight_records;

-- حذف تابع مشکل‌ساز
DROP FUNCTION IF EXISTS check_weekly_weight_limit();

-- بررسی تریگرهای موجود
SELECT 
    trigger_name,
    event_manipulation,
    action_statement
FROM information_schema.triggers 
WHERE event_object_table = 'weekly_weight_records'; 