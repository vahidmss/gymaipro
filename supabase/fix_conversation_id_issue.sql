-- =====================================================
-- حل مشکل conversation_id - GymAI Pro
-- =====================================================

-- بررسی وجود ستون conversation_id
DO $$
DECLARE
    has_conversation_id BOOLEAN;
BEGIN
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'conversation_id'
    ) INTO has_conversation_id;
    
    IF has_conversation_id THEN
        -- اگر ستون وجود دارد، آن را حذف کنیم چون از ساختار جدید استفاده می‌کنیم
        ALTER TABLE chat_messages DROP COLUMN conversation_id;
        RAISE NOTICE 'ستون conversation_id حذف شد (از ساختار جدید استفاده می‌کنیم)';
    ELSE
        RAISE NOTICE 'ستون conversation_id وجود نداشت';
    END IF;
END $$;

-- بررسی و حذف constraint های مربوط به conversation_id
DO $$
BEGIN
    -- حذف constraint های قدیمی اگر وجود دارند
    ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_conversation_id_fkey;
    ALTER TABLE chat_messages DROP CONSTRAINT IF EXISTS chat_messages_conversation_id_not_null;
    
    RAISE NOTICE 'Constraint های قدیمی conversation_id حذف شدند';
END $$;

-- به‌روزرسانی سیاست‌های RLS برای اطمینان
DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
DROP POLICY IF EXISTS "Users can insert their own messages" ON chat_messages;
DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;

CREATE POLICY "Users can view messages they sent or received" ON chat_messages
    FOR SELECT USING (
        auth.uid() = sender_id OR auth.uid() = receiver_id
    );

CREATE POLICY "Users can insert their own messages" ON chat_messages
    FOR INSERT WITH CHECK (auth.uid() = sender_id);

CREATE POLICY "Users can update their own messages" ON chat_messages
    FOR UPDATE USING (auth.uid() = sender_id);

-- بررسی ساختار نهایی جدول
DO $$
BEGIN
    RAISE NOTICE 'ساختار نهایی جدول chat_messages:';
    RAISE NOTICE 'id, sender_id, receiver_id, message, message_type, attachment_url, attachment_type, attachment_name, attachment_size, is_read, is_deleted, created_at, updated_at';
    RAISE NOTICE 'مشکل conversation_id حل شد!';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل ستون conversation_id را حذف می‌کند
-- 2. از ساختار جدید با sender_id و receiver_id استفاده می‌کنیم
-- 3. constraint های قدیمی حذف می‌شوند
-- 4. سیاست‌های RLS به‌روزرسانی می‌شوند
-- ===================================================== 