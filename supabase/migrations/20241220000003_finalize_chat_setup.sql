-- تنظیم نهایی چت خصوصی
-- فعال‌سازی Real-time و ایجاد جداول مورد نیاز

-- فعال‌سازی Real-time برای جدول chat_messages موجود
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;

-- ایجاد جدول chat_conversations
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

-- ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);

-- RLS
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations" ON chat_conversations
    FOR DELETE USING (auth.uid() = user_id);

-- Real-time برای chat_conversations
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- توابع مورد نیاز
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_sender_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_messages 
    SET is_read = true 
    WHERE sender_id = p_sender_id 
    AND receiver_id = auth.uid()
    AND is_read = false;
    
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
