-- رفع سریع مشکل توابع چت
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. حذف تمام توابع قدیمی
DROP FUNCTION IF EXISTS mark_conversation_as_read(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_as_read(uuid) CASCADE;
DROP FUNCTION IF EXISTS mark_messages_as_read(uuid) CASCADE;
DROP FUNCTION IF EXISTS get_unread_message_count() CASCADE;
DROP FUNCTION IF EXISTS add_message_to_conversation(uuid, uuid, uuid, text, text) CASCADE;

-- 2. ایجاد تابع add_message_to_conversation
CREATE OR REPLACE FUNCTION add_message_to_conversation(
    p_user1_id UUID,
    p_user2_id UUID,
    p_sender_id UUID,
    p_message TEXT,
    p_message_type TEXT DEFAULT 'text'
) RETURNS UUID AS $$
DECLARE
    conversation_id UUID;
    new_message JSONB;
    message_id UUID;
BEGIN
    -- پیدا کردن یا ایجاد مکالمه
    SELECT id INTO conversation_id
    FROM chat_conversations
    WHERE (user1_id = p_user1_id AND user2_id = p_user2_id)
       OR (user1_id = p_user2_id AND user2_id = p_user1_id);
    
    -- اگر مکالمه وجود ندارد، ایجاد کن
    IF conversation_id IS NULL THEN
        INSERT INTO chat_conversations (user1_id, user2_id, user1_name, user2_name)
        VALUES (p_user1_id, p_user2_id, 
                (SELECT COALESCE(first_name || ' ' || last_name, username) FROM profiles WHERE id = p_user1_id),
                (SELECT COALESCE(first_name || ' ' || last_name, username) FROM profiles WHERE id = p_user2_id))
        RETURNING id INTO conversation_id;
    END IF;
    
    -- ایجاد پیام جدید
    message_id := gen_random_uuid();
    new_message := jsonb_build_object(
        'id', message_id,
        'sender_id', p_sender_id,
        'receiver_id', CASE WHEN p_sender_id = p_user1_id THEN p_user2_id ELSE p_user1_id END,
        'message', p_message,
        'message_type', p_message_type,
        'created_at', NOW(),
        'is_read', false
    );
    
    -- اضافه کردن پیام به JSON
    UPDATE chat_conversations
    SET messages = messages || new_message,
        message_count = message_count + 1,
        last_message = p_message,
        last_message_at = NOW(),
        last_message_sender_id = p_sender_id,
        updated_at = NOW(),
        -- افزایش unread_count برای کاربر دریافت‌کننده
        user1_unread_count = CASE 
            WHEN p_sender_id != user1_id THEN user1_unread_count + 1 
            ELSE user1_unread_count 
        END,
        user2_unread_count = CASE 
            WHEN p_sender_id != user2_id THEN user2_unread_count + 1 
            ELSE user2_unread_count 
        END
    WHERE id = conversation_id;
    
    RETURN message_id;
END;
$$ LANGUAGE plpgsql;

-- 3. ایجاد تابع mark_conversation_as_read
CREATE OR REPLACE FUNCTION mark_conversation_as_read(
    p_conversation_id UUID,
    p_user_id UUID
) RETURNS VOID AS $$
BEGIN
    UPDATE chat_conversations
    SET user1_unread_count = CASE 
            WHEN p_user_id = user1_id THEN 0 
            ELSE user1_unread_count 
        END,
        user2_unread_count = CASE 
            WHEN p_user_id = user2_id THEN 0 
            ELSE user2_unread_count 
        END,
        user1_last_read_at = CASE 
            WHEN p_user_id = user1_id THEN NOW() 
            ELSE user1_last_read_at 
        END,
        user2_last_read_at = CASE 
            WHEN p_user_id = user2_id THEN NOW() 
            ELSE user2_last_read_at 
        END,
        updated_at = NOW()
    WHERE id = p_conversation_id;
END;
$$ LANGUAGE plpgsql;

-- 4. ایجاد تابع get_unread_message_count
CREATE OR REPLACE FUNCTION get_unread_message_count(p_user_id UUID)
RETURNS INTEGER AS $$
BEGIN
    RETURN (
        SELECT COALESCE(SUM(
            CASE 
                WHEN p_user_id = user1_id THEN user1_unread_count
                WHEN p_user_id = user2_id THEN user2_unread_count
                ELSE 0
            END
        ), 0)
        FROM chat_conversations 
        WHERE user1_id = p_user_id OR user2_id = p_user_id
    );
END;
$$ LANGUAGE plpgsql;

-- 5. بررسی نتیجه
SELECT 'Functions created successfully' as status;
SELECT routine_name, routine_type 
FROM information_schema.routines 
WHERE routine_name IN ('add_message_to_conversation', 'mark_conversation_as_read', 'get_unread_message_count');
