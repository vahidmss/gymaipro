-- فعال‌سازی Real-time برای جداول موجود
-- این migration فقط real-time را برای جداول چت فعال می‌کند

-- فعال‌سازی Real-time برای جداول چت
-- این دستورات real-time را برای جداول فعال می‌کنند
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;
