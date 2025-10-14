-- بررسی ساختار جدول chat_conversations موجود
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- بررسی ساختار جدول chat_conversations
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'chat_conversations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- بررسی ایندکس‌ها
SELECT indexname, indexdef 
FROM pg_indexes 
WHERE tablename = 'chat_conversations';

-- بررسی RLS policies
SELECT policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'chat_conversations';
