-- =====================================================
-- اضافه کردن ستون‌های پیوست - GymAI Pro
-- =====================================================

-- اضافه کردن ستون‌های پیوست به جدول chat_messages
DO $$
BEGIN
    -- ستون attachment_url
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'attachment_url'
    ) THEN
        ALTER TABLE chat_messages ADD COLUMN attachment_url TEXT;
        RAISE NOTICE 'ستون attachment_url اضافه شد';
    ELSE
        RAISE NOTICE 'ستون attachment_url از قبل وجود دارد';
    END IF;
    
    -- ستون attachment_type
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'attachment_type'
    ) THEN
        ALTER TABLE chat_messages ADD COLUMN attachment_type VARCHAR(50);
        RAISE NOTICE 'ستون attachment_type اضافه شد';
    ELSE
        RAISE NOTICE 'ستون attachment_type از قبل وجود دارد';
    END IF;
    
    -- ستون attachment_name
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'attachment_name'
    ) THEN
        ALTER TABLE chat_messages ADD COLUMN attachment_name VARCHAR(255);
        RAISE NOTICE 'ستون attachment_name اضافه شد';
    ELSE
        RAISE NOTICE 'ستون attachment_name از قبل وجود دارد';
    END IF;
    
    -- ستون attachment_size
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'attachment_size'
    ) THEN
        ALTER TABLE chat_messages ADD COLUMN attachment_size INTEGER;
        RAISE NOTICE 'ستون attachment_size اضافه شد';
    ELSE
        RAISE NOTICE 'ستون attachment_size از قبل وجود دارد';
    END IF;
END $$;

-- به‌روزرسانی تابع update_chat_conversation برای پشتیبانی از پیوست‌ها
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

-- به‌روزرسانی تریگر
DROP TRIGGER IF EXISTS update_conversation_on_message ON chat_messages;
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'ستون‌های پیوست با موفقیت اضافه شدند!';
    RAISE NOTICE 'attachment_url, attachment_type, attachment_name, attachment_size';
    RAISE NOTICE 'تابع update_chat_conversation به‌روزرسانی شد';
    RAISE NOTICE 'حالا سیستم از پیوست‌ها پشتیبانی می‌کند';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل ستون‌های پیوست را اضافه می‌کند
-- 2. تابع update_chat_conversation را به‌روزرسانی می‌کند
-- 3. حالا سیستم از تصاویر، فایل‌ها و پیام‌های صوتی پشتیبانی می‌کند
-- ===================================================== 