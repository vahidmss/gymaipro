-- =====================================================
-- سیستم چت کامل - GymAI Pro
-- =====================================================

-- 1. جدول پیام‌های چت
CREATE TABLE IF NOT EXISTS chat_messages (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    sender_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    receiver_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    message TEXT NOT NULL,
    message_type VARCHAR(20) DEFAULT 'text' CHECK (message_type IN ('text', 'image', 'file', 'voice')),
    attachment_url TEXT,
    attachment_type VARCHAR(50),
    attachment_name VARCHAR(255),
    attachment_size INTEGER,
    is_read BOOLEAN DEFAULT FALSE,
    is_deleted BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. جدول گفتگوها (برای نمایش لیست گفتگوها)
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

-- 3. جدول اتاق‌های چت (برای چت گروهی آینده)
CREATE TABLE IF NOT EXISTS chat_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    room_type VARCHAR(20) DEFAULT 'direct' CHECK (room_type IN ('direct', 'group')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. جدول اعضای اتاق چت
CREATE TABLE IF NOT EXISTS chat_room_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    role VARCHAR(20) DEFAULT 'member' CHECK (role IN ('admin', 'moderator', 'member')),
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(room_id, user_id)
);

-- =====================================================
-- ایندکس‌ها برای بهبود عملکرد
-- =====================================================

-- ایندکس برای جستجوی سریع پیام‌ها
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver 
ON chat_messages(sender_id, receiver_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at 
ON chat_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_messages_is_deleted 
ON chat_messages(is_deleted) WHERE is_deleted = FALSE;

-- ایندکس برای گفتگوها
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id 
ON chat_conversations(user_id);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at 
ON chat_conversations(last_message_at DESC);

-- =====================================================
-- توابع برای مدیریت خودکار
-- =====================================================

-- تابع برای به‌روزرسانی خودکار updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- تابع برای علامت‌گذاری پیام‌ها به عنوان خوانده شده
CREATE OR REPLACE FUNCTION mark_messages_as_read(p_sender_id UUID)
RETURNS VOID AS $$
BEGIN
    UPDATE chat_messages 
    SET is_read = TRUE 
    WHERE receiver_id = auth.uid() 
    AND sender_id = p_sender_id 
    AND is_deleted = FALSE;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- تابع برای علامت‌گذاری گفتگو به عنوان خوانده شده
CREATE OR REPLACE FUNCTION mark_conversation_as_read(p_other_user_id UUID)
RETURNS VOID AS $$
BEGIN
    -- علامت‌گذاری پیام‌ها
    UPDATE chat_messages 
    SET is_read = TRUE 
    WHERE receiver_id = auth.uid() 
    AND sender_id = p_other_user_id 
    AND is_deleted = FALSE;
    
    -- به‌روزرسانی شمارش پیام‌های نخوانده
    UPDATE chat_conversations 
    SET unread_count = 0 
    WHERE user_id = auth.uid() 
    AND other_user_id = p_other_user_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- تابع برای دریافت تعداد پیام‌های نخوانده
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

-- =====================================================
-- تریگرها
-- =====================================================

-- تریگر برای به‌روزرسانی خودکار updated_at
CREATE TRIGGER update_chat_messages_updated_at 
    BEFORE UPDATE ON chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_conversations_updated_at 
    BEFORE UPDATE ON chat_conversations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rooms_updated_at 
    BEFORE UPDATE ON chat_rooms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- تریگر برای به‌روزرسانی خودکار گفتگوها
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- =====================================================
-- سیاست‌های امنیتی (RLS)
-- =====================================================

-- فعال‌سازی RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

-- سیاست‌های chat_messages
CREATE POLICY "Users can view messages they sent or received" ON chat_messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = sender_id);

CREATE POLICY "Users can delete their own messages" ON chat_messages
    FOR DELETE USING (auth.uid() = sender_id);

-- سیاست‌های chat_conversations
CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "System can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (true);

CREATE POLICY "System can update conversations" ON chat_conversations
    FOR UPDATE USING (true);

-- سیاست‌های chat_rooms
CREATE POLICY "Users can view rooms they are members of" ON chat_rooms
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_room_members 
            WHERE room_id = chat_rooms.id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Users can create rooms" ON chat_rooms
    FOR INSERT WITH CHECK (auth.uid() = created_by);

CREATE POLICY "Room creators can update rooms" ON chat_rooms
    FOR UPDATE USING (auth.uid() = created_by);

-- سیاست‌های chat_room_members
CREATE POLICY "Users can view room members" ON chat_room_members
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM chat_room_members 
            WHERE room_id = chat_room_members.room_id 
            AND user_id = auth.uid()
        )
    );

CREATE POLICY "Room admins can manage members" ON chat_room_members
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM chat_room_members 
            WHERE room_id = chat_room_members.room_id 
            AND user_id = auth.uid() 
            AND role IN ('admin', 'moderator')
        )
    );

-- =====================================================
-- داده‌های نمونه (اختیاری)
-- =====================================================

-- درج داده‌های نمونه برای تست (اختیاری)
-- INSERT INTO chat_rooms (name, description, created_by, room_type) 
-- VALUES ('گروه عمومی', 'گروه عمومی برای همه کاربران', 'user-id-here', 'group');

-- =====================================================
-- توضیحات و نکات
-- =====================================================

/*
نکات مهم:
1. تمام جداول از RLS استفاده می‌کنند
2. پیام‌ها به صورت نرم حذف می‌شوند (is_deleted)
3. گفتگوها به صورت خودکار به‌روزرسانی می‌شوند
4. شمارش پیام‌های نخوانده خودکار است
5. تمام عملیات از طریق توابع امن انجام می‌شود

برای استفاده:
1. این فایل را در Supabase اجرا کنید
2. مطمئن شوید که جدول profiles وجود دارد
3. تست کنید که همه چیز درست کار می‌کند
*/ 