-- =====================================================
-- نصب پایه سیستم چت - GymAI Pro
-- =====================================================

-- 1. جدول پیام‌های چت
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text',
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. جدول گفتگوها
CREATE TABLE IF NOT EXISTS chat_conversations (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    other_user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    other_user_name VARCHAR(255) NOT NULL,
    other_user_avatar TEXT,
    other_user_role VARCHAR(20),
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    last_message_text TEXT,
    last_message_type VARCHAR(20),
    unread_count INTEGER DEFAULT 0,
    is_sent_by_me BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, other_user_id)
);

-- ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver 
ON chat_messages(sender_id, receiver_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at 
ON chat_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id 
ON chat_conversations(user_id);

-- توابع پایه
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE OR REPLACE FUNCTION mark_conversation_as_read(p_other_user_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_messages 
    SET is_read = TRUE 
    WHERE receiver_id = auth.uid() 
    AND sender_id = p_other_user_id 
    AND is_deleted = FALSE;
    
    UPDATE chat_conversations 
    SET unread_count = 0 
    WHERE user_id = auth.uid() 
    AND other_user_id = p_other_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE OR REPLACE FUNCTION get_unread_message_count()
RETURNS INTEGER AS $$
DECLARE
    count INTEGER;
BEGIN
    SELECT COALESCE(SUM(unread_count), 0) INTO count
    FROM chat_conversations 
    WHERE user_id = auth.uid();
    
    RETURN count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- تریگرها
CREATE TRIGGER update_chat_messages_updated_at 
    BEFORE UPDATE ON chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_conversations_updated_at 
    BEFORE UPDATE ON chat_conversations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- سیاست‌های RLS
CREATE POLICY "Users can view messages they sent or received" ON chat_messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = sender_id);

CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "System can update conversations" ON chat_conversations
    FOR UPDATE USING (true);

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'سیستم چت پایه با موفقیت نصب شد!';
    RAISE NOTICE 'جداول: chat_messages, chat_conversations';
    RAISE NOTICE 'توابع: update_updated_at_column, mark_conversation_as_read, get_unread_message_count';
    RAISE NOTICE 'تریگرها: update_chat_messages_updated_at, update_chat_conversations_updated_at';
    RAISE NOTICE 'RLS: فعال شده با سیاست‌های امنیتی';
    RAISE NOTICE 'نکته: برای به‌روزرسانی خودکار گفتگوها، تابع update_chat_conversation را جداگانه اضافه کنید';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل سیستم چت پایه را نصب می‌کند
-- 2. تابع update_chat_conversation برای به‌روزرسانی خودکار گفتگوها جداگانه اضافه می‌شود
-- 3. Real-time را در Supabase Dashboard فعال کنید
-- ===================================================== 