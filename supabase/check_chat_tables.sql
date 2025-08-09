-- =====================================================
-- بررسی وضعیت جداول چت - GymAI Pro
-- =====================================================

-- بررسی جداول موجود
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name LIKE 'chat_%'
ORDER BY table_name;

-- بررسی ستون‌های جدول chat_messages
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'chat_messages' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- بررسی ستون‌های جدول chat_conversations
SELECT 
    column_name,
    data_type,
    is_nullable,
    column_default
FROM information_schema.columns 
WHERE table_name = 'chat_conversations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- بررسی توابع موجود
SELECT 
    routine_name,
    routine_type
FROM information_schema.routines 
WHERE routine_schema = 'public' 
AND routine_name LIKE '%chat%'
ORDER BY routine_name;

-- بررسی تریگرها
SELECT 
    trigger_name,
    event_manipulation,
    event_object_table
FROM information_schema.triggers 
WHERE trigger_schema = 'public' 
AND event_object_table LIKE 'chat_%'
ORDER BY trigger_name;

-- بررسی سیاست‌های RLS
SELECT 
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename LIKE 'chat_%'
ORDER BY tablename, policyname;

-- =====================================================
-- نکات:
-- 1. این فایل وضعیت فعلی جداول چت را بررسی می‌کند
-- 2. اگر ستون receiver_id وجود ندارد، باید آن را اضافه کنید
-- 3. یا نام ستون را در کد Flutter تغییر دهید
-- ===================================================== 