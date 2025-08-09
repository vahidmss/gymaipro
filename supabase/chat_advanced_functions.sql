-- =====================================================
-- توابع پیشرفته سیستم چت - GymAI Pro
-- =====================================================

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

-- تریگر برای به‌روزرسانی خودکار گفتگوها
CREATE TRIGGER update_conversation_on_message
    AFTER INSERT ON chat_messages
    FOR EACH ROW EXECUTE FUNCTION update_chat_conversation();

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'تابع update_chat_conversation با موفقیت اضافه شد!';
    RAISE NOTICE 'تریگر update_conversation_on_message فعال شد';
    RAISE NOTICE 'حالا گفتگوها به صورت خودکار به‌روزرسانی می‌شوند';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل را بعد از اجرای chat_basic_setup.sql اجرا کنید
-- 2. این تابع گفتگوها را به صورت خودکار به‌روزرسانی می‌کند
-- 3. هر بار که پیام جدیدی ارسال شود، گفتگوها به‌روزرسانی می‌شوند
-- ===================================================== 