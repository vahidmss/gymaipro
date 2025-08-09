-- =====================================================
-- سیستم چت ساده - GymAI Pro (برای تست)
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

-- توابع ساده
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

-- تابع برای به‌روزرسانی خودکار گفتگوها
CREATE OR REPLACE FUNCTION update_chat_conversation()
RETURNS TRIGGER AS $$
DECLARE
    sender_name VARCHAR(255);
    sender_avatar TEXT;
    sender_role VARCHAR(20);
    receiver_name VARCHAR(255);
    receiver_avatar TEXT;
    receiver_role VARCHAR(20);
BEGIN
    -- دریافت اطلاعات فرستنده
    SELECT 
        COALESCE(first_name || ' ' || last_name, username) as name,
        avatar_url,
        role
    INTO sender_name, sender_avatar, sender_role
    FROM profiles 
    WHERE id = NEW.sender_id;
    
    -- دریافت اطلاعات گیرنده
    SELECT 
        COALESCE(first_name || ' ' || last_name, username) as name,
        avatar_url,
        role
    INTO receiver_name, receiver_avatar, receiver_role
    FROM profiles 
    WHERE id = NEW.receiver_id;
    
    -- به‌روزرسانی گفتگوی فرستنده
    INSERT INTO chat_conversations (
        user_id, other_user_id, other_user_name, other_user_avatar, 
        other_user_role, last_message_at, last_message_text, 
        last_message_type, unread_count, is_sent_by_me
    ) VALUES (
        NEW.sender_id, NEW.receiver_id, receiver_name, receiver_avatar,
        receiver_role, NEW.created_at, NEW.message, NEW.message_type,
        0, TRUE
    )
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message_at = NEW.created_at,
        last_message_text = NEW.message,
        last_message_type = NEW.message_type,
        unread_count = 0,
        is_sent_by_me = TRUE,
        updated_at = NOW();
    
    -- به‌روزرسانی گفتگوی گیرنده
    INSERT INTO chat_conversations (
        user_id, other_user_id, other_user_name, other_user_avatar, 
        other_user_role, last_message_at, last_message_text, 
        last_message_type, unread_count, is_sent_by_me
    ) VALUES (
        NEW.receiver_id, NEW.sender_id, sender_name, sender_avatar,
        sender_role, NEW.created_at, NEW.message, NEW.message_type,
        1, FALSE
    )
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message_at = NEW.created_at,
        last_message_text = NEW.message,
        last_message_type = NEW.message_type,
        unread_count = chat_conversations.unread_count + 1,
        is_sent_by_me = FALSE,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگرها
CREATE TRIGGER update_chat_messages_updated_at 
    BEFORE UPDATE ON chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_conversations_updated_at 
    BEFORE UPDATE ON chat_conversations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- تریگر برای به‌روزرسانی خودکار گفتگوها
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- سیاست‌های ساده
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

-- داده‌های نمونه (اختیاری)
-- INSERT INTO chat_messages (sender_id, receiver_id, message) 
-- VALUES ('user1-id', 'user2-id', 'سلام!');

-- =====================================================
-- نکات:
-- 1. این فایل برای تست سریع طراحی شده
-- 2. برای production از فایل کامل استفاده کنید
-- 3. مطمئن شوید که جدول profiles وجود دارد
-- ===================================================== 