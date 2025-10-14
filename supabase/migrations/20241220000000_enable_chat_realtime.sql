-- فعال‌سازی Real-time برای جداول چت خصوصی
-- این فایل جداول چت خصوصی را ایجاد می‌کند و real-time را فعال می‌کند

-- ایجاد جدول chat_messages اگر وجود ندارد
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(50) DEFAULT 'text',
    attachment_url TEXT,
    attachment_type VARCHAR(50),
    attachment_name VARCHAR(255),
    attachment_size INTEGER,
    is_deleted BOOLEAN DEFAULT false,
    is_read BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    conversation_id VARCHAR(255)
);

-- ایجاد جدول chat_conversations اگر وجود ندارد
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

-- ایجاد ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver ON chat_messages(sender_id, receiver_id);
CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_chat_messages_conversation ON chat_messages(conversation_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);

-- فعال‌سازی RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- RLS Policies برای chat_messages
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;

CREATE POLICY "Users can view messages they sent or received" ON chat_messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = sender_id);

CREATE POLICY "Users can delete their own messages" ON chat_messages
    FOR DELETE USING (auth.uid() = sender_id);

-- RLS Policies برای chat_conversations
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

-- فعال‌سازی Real-time برای جداول چت
-- این دستورات real-time را برای جداول فعال می‌کنند
ALTER PUBLICATION supabase_realtime ADD TABLE chat_messages;
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- ایجاد توابع مورد نیاز برای real-time
CREATE OR REPLACE FUNCTION update_chat_conversation_on_message()
RETURNS TRIGGER AS $$
BEGIN
    -- به‌روزرسانی conversation برای sender
    INSERT INTO chat_conversations (user_id, other_user_id, other_user_name, last_message, last_message_at, unread_count)
    SELECT 
        NEW.sender_id,
        NEW.receiver_id,
        COALESCE(p.first_name || ' ' || p.last_name, p.username, 'کاربر ناشناس'),
        NEW.message,
        NEW.created_at,
        0
    FROM profiles p
    WHERE p.id = NEW.receiver_id
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message = NEW.message,
        last_message_at = NEW.created_at,
        updated_at = NOW();

    -- به‌روزرسانی conversation برای receiver
    INSERT INTO chat_conversations (user_id, other_user_id, other_user_name, last_message, last_message_at, unread_count)
    SELECT 
        NEW.receiver_id,
        NEW.sender_id,
        COALESCE(p.first_name || ' ' || p.last_name, p.username, 'کاربر ناشناس'),
        NEW.message,
        NEW.created_at,
        1
    FROM profiles p
    WHERE p.id = NEW.sender_id
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message = NEW.message,
        last_message_at = NEW.created_at,
        unread_count = chat_conversations.unread_count + 1,
        updated_at = NOW();

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- ایجاد تریگر برای به‌روزرسانی خودکار conversations
DROP TRIGGER IF EXISTS trigger_update_chat_conversation_on_message ON chat_messages;
CREATE TRIGGER trigger_update_chat_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_conversation_on_message();

-- تابع برای علامت‌گذاری پیام‌ها به عنوان خوانده شده
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

-- تابع برای علامت‌گذاری conversation به عنوان خوانده شده
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

-- تابع برای دریافت تعداد پیام‌های نخوانده
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

-- تابع برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی خودکار updated_at
DROP TRIGGER IF EXISTS trigger_update_chat_messages_updated_at ON chat_messages;
CREATE TRIGGER trigger_update_chat_messages_updated_at
    BEFORE UPDATE ON chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS trigger_update_chat_conversations_updated_at ON chat_conversations;
CREATE TRIGGER trigger_update_chat_conversations_updated_at
    BEFORE UPDATE ON chat_conversations
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
