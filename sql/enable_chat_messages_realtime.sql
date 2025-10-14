-- فعال‌سازی Real-time برای جدول chat_messages موجود
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- فعال‌سازی Real-time برای جدول chat_messages
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- بررسی وضعیت real-time
SELECT 'Real-time enabled for chat_messages' as status;
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename = 'chat_messages';
