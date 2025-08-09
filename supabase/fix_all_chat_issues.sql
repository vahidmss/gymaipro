-- =====================================================
-- اصلاح کامل سیستم چت - GymAI Pro
-- =====================================================

-- مرحله 1: اصلاح جدول chat_messages
DO $$
BEGIN
    -- تغییر نام ستون recipient_id به receiver_id
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'recipient_id'
    ) THEN
        ALTER TABLE chat_messages RENAME COLUMN recipient_id TO receiver_id;
        RAISE NOTICE 'ستون recipient_id به receiver_id تغییر نام یافت';
    ELSE
        RAISE NOTICE 'ستون recipient_id وجود نداشت';
    END IF;
END $$;

-- مرحله 2: اصلاح جدول chat_conversations
DO $$
BEGIN
    -- تغییر نام ستون‌ها
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'user1_id'
    ) THEN
        ALTER TABLE chat_conversations RENAME COLUMN user1_id TO user_id;
        RAISE NOTICE 'ستون user1_id به user_id تغییر نام یافت';
    END IF;
    
    IF EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'user2_id'
    ) THEN
        ALTER TABLE chat_conversations RENAME COLUMN user2_id TO other_user_id;
        RAISE NOTICE 'ستون user2_id به other_user_id تغییر نام یافت';
    END IF;
    
    -- اضافه کردن ستون‌های ضروری اگر وجود ندارند
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'other_user_name'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_name VARCHAR(255);
        RAISE NOTICE 'ستون other_user_name اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'other_user_avatar'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_avatar TEXT;
        RAISE NOTICE 'ستون other_user_avatar اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'other_user_role'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_role VARCHAR(20);
        RAISE NOTICE 'ستون other_user_role اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'last_message_at'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        RAISE NOTICE 'ستون last_message_at اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'last_message_text'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN last_message_text TEXT;
        RAISE NOTICE 'ستون last_message_text اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'last_message_type'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN last_message_type VARCHAR(20);
        RAISE NOTICE 'ستون last_message_type اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'unread_count'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN unread_count INTEGER DEFAULT 0;
        RAISE NOTICE 'ستون unread_count اضافه شد';
    END IF;
    
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_conversations' 
        AND column_name = 'is_sent_by_me'
    ) THEN
        ALTER TABLE chat_conversations ADD COLUMN is_sent_by_me BOOLEAN DEFAULT FALSE;
        RAISE NOTICE 'ستون is_sent_by_me اضافه شد';
    END IF;
END $$;

-- مرحله 3: حذف سیاست‌های قدیمی
DROP POLICY IF EXISTS "chat_messages_select_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_insert_policy" ON chat_messages;
DROP POLICY IF EXISTS "chat_messages_update_policy" ON chat_messages;

DROP POLICY IF EXISTS "chat_conversations_select_policy" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_insert_policy" ON chat_conversations;
DROP POLICY IF EXISTS "chat_conversations_update_policy" ON chat_conversations;

-- مرحله 4: ایجاد سیاست‌های جدید
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

-- مرحله 5: به‌روزرسانی توابع
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

-- مرحله 6: به‌روزرسانی ایندکس‌ها
DROP INDEX IF EXISTS idx_chat_messages_sender_recipient;
CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver 
ON chat_messages(sender_id, receiver_id);

CREATE INDEX IF NOT EXISTS idx_chat_messages_created_at 
ON chat_messages(created_at DESC);

CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id 
ON chat_conversations(user_id);

-- مرحله 7: اضافه کردن تابع به‌روزرسانی خودکار گفتگوها
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

-- مرحله 8: ایجاد تریگر
DROP TRIGGER IF EXISTS update_conversation_on_message ON chat_messages;
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'اصلاح کامل سیستم چت با موفقیت انجام شد!';
    RAISE NOTICE 'ستون‌ها: recipient_id -> receiver_id, user1_id/user2_id -> user_id/other_user_id';
    RAISE NOTICE 'سیاست‌های RLS به‌روزرسانی شدند';
    RAISE NOTICE 'توابع و تریگرها اصلاح شدند';
    RAISE NOTICE 'حالا سیستم چت با کد Flutter هماهنگ است';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل تمام مشکلات ستون‌ها را حل می‌کند
-- 2. سیاست‌های RLS را به‌روزرسانی می‌کند
-- 3. توابع و تریگرها را اصلاح می‌کند
-- 4. حالا سیستم با کد Flutter کاملاً هماهنگ است
-- ===================================================== 