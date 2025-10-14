-- فعال‌سازی Real-time برای جداول چت خصوصی
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- فعال‌سازی Real-time برای جداول چت
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- بررسی وضعیت real-time
SELECT schemaname, tablename, hasindexes, hasrules, hastriggers 
FROM pg_tables 
WHERE tablename IN ('chat_messages', 'chat_conversations');

-- بررسی publication
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime';
