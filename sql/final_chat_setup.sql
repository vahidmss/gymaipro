-- تنظیم نهایی چت خصوصی
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. حذف جداول و توابع قدیمی
DROP TABLE IF EXISTS chat_messages CASCADE;
DROP TABLE IF EXISTS chat_conversations CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_as_read(uuid, uuid) CASCADE;
DROP FUNCTION IF EXISTS mark_conversation_as_read(uuid) CASCADE;
DROP FUNCTION IF EXISTS mark_messages_as_read(uuid) CASCADE;
DROP FUNCTION IF EXISTS get_unread_message_count() CASCADE;
DROP FUNCTION IF EXISTS get_unread_message_count(uuid) CASCADE;
DROP FUNCTION IF EXISTS add_message_to_conversation(uuid, uuid, uuid, text, text) CASCADE;

-- 2. ایجاد جدول chat_conversations جدید
CREATE TABLE chat_conversations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user1_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user2_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    user1_name VARCHAR(255),
    user2_name VARCHAR(255),
    user1_avatar TEXT,
    user2_avatar TEXT,
    messages JSONB DEFAULT '[]'::jsonb,
    message_count INTEGER DEFAULT 0,
    last_message TEXT,
    last_message_at TIMESTAMP WITH TIME ZONE,
    last_message_sender_id UUID,
    user1_unread_count INTEGER DEFAULT 0,
    user2_unread_count INTEGER DEFAULT 0,
    user1_last_read_at TIMESTAMP WITH TIME ZONE,
    user2_last_read_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user1_id, user2_id)
);

-- 3. ایندکس‌ها
CREATE INDEX idx_chat_conversations_user1 ON chat_conversations(user1_id, updated_at DESC);
CREATE INDEX idx_chat_conversations_user2 ON chat_conversations(user2_id, updated_at DESC);
CREATE INDEX idx_chat_conversations_last_message ON chat_conversations(last_message_at DESC);
CREATE INDEX idx_chat_conversations_messages ON chat_conversations USING GIN (messages);

-- 4. RLS
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Users can view their conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can update their conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

CREATE POLICY "Users can delete their conversations" ON chat_conversations
    FOR DELETE USING (auth.uid() = user1_id OR auth.uid() = user2_id);

-- 6. Real-time
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- 7. توابع
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
    SELECT id INTO conversation_id
    FROM chat_conversations
    WHERE (user1_id = p_user1_id AND user2_id = p_user2_id)
       OR (user1_id = p_user2_id AND user2_id = p_user1_id);
    
    IF conversation_id IS NULL THEN
        INSERT INTO chat_conversations (user1_id, user2_id, user1_name, user2_name)
        VALUES (p_user1_id, p_user2_id, 
                (SELECT COALESCE(first_name || ' ' || last_name, username) FROM profiles WHERE id = p_user1_id),
                (SELECT COALESCE(first_name || ' ' || last_name, username) FROM profiles WHERE id = p_user2_id))
        RETURNING id INTO conversation_id;
    END IF;
    
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
    
    UPDATE chat_conversations
    SET messages = messages || new_message,
        message_count = message_count + 1,
        last_message = p_message,
        last_message_at = NOW(),
        last_message_sender_id = p_sender_id,
        updated_at = NOW(),
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

-- 8. ایجاد توابع اضافی برای حذف و ویرایش پیام
CREATE OR REPLACE FUNCTION delete_message_from_conversation(
    p_message_id UUID,
    p_user_id UUID
) RETURNS VOID AS $$
BEGIN
    UPDATE chat_conversations
    SET messages = (
        SELECT jsonb_agg(
            CASE 
                WHEN (msg->>'id')::uuid = p_message_id 
                THEN msg || '{"is_deleted": true}'::jsonb
                ELSE msg
            END
        )
        FROM jsonb_array_elements(messages) AS msg
    ),
    updated_at = NOW()
    WHERE (user1_id = p_user_id OR user2_id = p_user_id)
    AND messages @> jsonb_build_array(jsonb_build_object('id', p_message_id));
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION edit_message_in_conversation(
    p_message_id UUID,
    p_user_id UUID,
    p_new_text TEXT
) RETURNS VOID AS $$
BEGIN
    UPDATE chat_conversations
    SET messages = (
        SELECT jsonb_agg(
            CASE 
                WHEN (msg->>'id')::uuid = p_message_id 
                THEN msg || jsonb_build_object('message', p_new_text, 'updated_at', NOW())
                ELSE msg
            END
        )
        FROM jsonb_array_elements(messages) AS msg
    ),
    updated_at = NOW()
    WHERE (user1_id = p_user_id OR user2_id = p_user_id)
    AND messages @> jsonb_build_array(jsonb_build_object('id', p_message_id));
END;
$$ LANGUAGE plpgsql;

-- 9. بررسی نتیجه
SELECT 'Chat setup completed successfully' as status;
