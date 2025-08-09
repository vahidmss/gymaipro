-- =====================================================
-- نصب کامل سیستم چت - GymAI Pro
-- =====================================================

-- مرحله 1: حذف کامل جداول قدیمی
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP TABLE IF EXISTS chat_rooms CASCADE;
DROP TABLE IF EXISTS chat_room_members CASCADE;

-- مرحله 2: حذف توابع قدیمی
DROP FUNCTION IF EXISTS update_updated_at_column() CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_as_read(UUID) CASCADE;
DROP FUNCTION IF EXISTS get_unread_message_count() CASCADE;
DROP FUNCTION IF EXISTS update_chat_conversation() CASCADE;

-- مرحله 3: حذف تریگرها
DROP TRIGGER IF EXISTS update_chat_messages_updated_at ON chat_messages;
DROP TRIGGER IF EXISTS update_chat_conversations_updated_at ON chat_conversations;
DROP TRIGGER IF EXISTS update_conversation_on_message ON chat_messages;

-- مرحله 4: حذف سیاست‌های RLS
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can delete their own messages" ON chat_messages;

DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can insert conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can update conversations" ON chat_conversations;

-- مرحله 5: ایجاد جداول جدید مطابق با کد Flutter

-- 1. جدول پیام‌های چت
CREATE TABLE chat_messages (
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

-- 2. جدول گفتگوها
CREATE TABLE chat_conversations (
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

-- 3. جدول اتاق‌های چت (برای آینده)
CREATE TABLE chat_rooms (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    created_by UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    room_type VARCHAR(20) DEFAULT 'direct' CHECK (room_type IN ('direct', 'group')),
    is_active BOOLEAN DEFAULT TRUE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. جدول اعضای اتاق‌های چت
CREATE TABLE chat_room_members (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    room_id UUID NOT NULL REFERENCES chat_rooms(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    joined_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_admin BOOLEAN DEFAULT FALSE,
    is_muted BOOLEAN DEFAULT FALSE,
    UNIQUE(room_id, user_id)
);

-- مرحله 6: ایجاد ایندکس‌ها
CREATE INDEX idx_chat_messages_sender_receiver ON chat_messages(sender_id, receiver_id);
CREATE INDEX idx_chat_messages_created_at ON chat_messages(created_at DESC);
CREATE INDEX idx_chat_messages_is_deleted ON chat_messages(is_deleted);
CREATE INDEX idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);
CREATE INDEX idx_chat_rooms_created_by ON chat_rooms(created_by);
CREATE INDEX idx_chat_room_members_room_id ON chat_room_members(room_id);
CREATE INDEX idx_chat_room_members_user_id ON chat_room_members(user_id);

-- مرحله 7: ایجاد توابع
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
    message_preview TEXT;
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
    
    -- ایجاد پیش‌نمایش پیام
    IF NEW.attachment_url IS NOT NULL THEN
        CASE NEW.attachment_type
            WHEN 'image' THEN message_preview := '📷 تصویر';
            WHEN 'file' THEN message_preview := '📎 فایل';
            WHEN 'voice' THEN message_preview := '🎤 پیام صوتی';
            ELSE message_preview := '📎 پیوست';
        END CASE;
    ELSE
        message_preview := NEW.message;
    END IF;
    
    -- به‌روزرسانی گفتگوی فرستنده
    INSERT INTO chat_conversations (
        user_id, other_user_id, other_user_name, other_user_avatar, 
        other_user_role, last_message_at, last_message_text, 
        last_message_type, unread_count, is_sent_by_me
    ) VALUES (
        NEW.sender_id, NEW.receiver_id, receiver_name, receiver_avatar,
        receiver_role, NEW.created_at, message_preview, NEW.message_type,
        0, TRUE
    )
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message_at = NEW.created_at,
        last_message_text = message_preview,
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
        sender_role, NEW.created_at, message_preview, NEW.message_type,
        1, FALSE
    )
    ON CONFLICT (user_id, other_user_id) 
    DO UPDATE SET
        last_message_at = NEW.created_at,
        last_message_text = message_preview,
        last_message_type = NEW.message_type,
        unread_count = chat_conversations.unread_count + 1,
        is_sent_by_me = FALSE,
        updated_at = NOW();
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- مرحله 8: ایجاد تریگرها
CREATE TRIGGER update_chat_messages_updated_at 
    BEFORE UPDATE ON chat_messages 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_conversations_updated_at 
    BEFORE UPDATE ON chat_conversations 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_chat_rooms_updated_at 
    BEFORE UPDATE ON chat_rooms 
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- مرحله 9: فعال‌سازی RLS
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_rooms ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_room_members ENABLE ROW LEVEL SECURITY;

-- مرحله 10: ایجاد سیاست‌های RLS
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
    FOR UPDATE USING (auth.uid() = sender_id);

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
            AND is_admin = TRUE
        )
    );

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'سیستم چت کامل با موفقیت نصب شد!';
    RAISE NOTICE 'جداول: chat_messages, chat_conversations, chat_rooms, chat_room_members';
    RAISE NOTICE 'توابع: update_updated_at_column, mark_conversation_as_read, get_unread_message_count, update_chat_conversation';
    RAISE NOTICE 'تریگرها: update_chat_messages_updated_at, update_chat_conversations_updated_at, update_chat_rooms_updated_at, update_conversation_on_message';
    RAISE NOTICE 'RLS: فعال شده با سیاست‌های امنیتی';
    RAISE NOTICE 'حالا سیستم چت کاملاً با کد Flutter هماهنگ است!';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل سیستم چت را کاملاً بازسازی می‌کند
-- 2. تمام ستون‌ها مطابق با کد Flutter هستند
-- 3. تمام توابع و تریگرها فعال هستند
-- 4. RLS با سیاست‌های امنیتی فعال است
-- 5. Real-time را در Supabase Dashboard فعال کنید
-- ===================================================== 