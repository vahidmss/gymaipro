-- تنظیم کامل چت خصوصی
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. فعال‌سازی Real-time برای جدول chat_messages موجود
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- 2. ایجاد جدول chat_conversations اگر وجود ندارد
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    other_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    other_user_name VARCHAR(255),
    other_user_avatar TEXT,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    unread_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, other_user_id)
);

-- 3. ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);

-- 4. فعال‌سازی RLS برای chat_conversations
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies برای chat_conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can insert conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can update their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Users can delete their own conversations" ON chat_conversations;

CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations" ON chat_conversations
    FOR DELETE USING (auth.uid() = user_id);

-- 6. فعال‌سازی Real-time برای chat_conversations
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- 7. ایجاد توابع مورد نیاز
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_sender_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_messages 
    SET is_read = true 
    WHERE sender_id = p_sender_id 
    AND receiver_id = auth.uid()
    AND is_read = false;
    
    -- به‌روزرسانی unread_count در conversations
    UPDATE chat_conversations 
    SET unread_count = 0,
        updated_at = NOW()
    WHERE user_id = auth.uid() 
    AND other_user_id = p_sender_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION mark_conversation_as_read(p_other_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_messages 
    SET is_read = true 
    WHERE sender_id = p_other_user_id 
    AND receiver_id = auth.uid()
    AND is_read = false;
    
    -- به‌روزرسانی unread_count در conversations
    UPDATE chat_conversations 
    SET unread_count = 0,
        updated_at = NOW()
    WHERE user_id = auth.uid() 
    AND other_user_id = p_other_user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION get_unread_message_count()
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(unread_count), 0)
        FROM chat_conversations 
        WHERE user_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql;

-- 8. بررسی وضعیت
SELECT 'Chat setup completed successfully' as status;
SELECT tablename FROM pg_tables WHERE tablename IN ('chat_messages', 'chat_conversations');
SELECT * FROM pg_publication_tables WHERE pubname = 'supabase_realtime' AND tablename IN ('chat_messages', 'chat_conversations');
