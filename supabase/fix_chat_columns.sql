-- =====================================================
-- اصلاح ستون‌های جداول چت - GymAI Pro
-- =====================================================

-- بررسی ستون‌های موجود در chat_messages
DO $$
DECLARE
    has_receiver_id BOOLEAN;
    has_recipient_id BOOLEAN;
BEGIN
    -- بررسی وجود ستون receiver_id
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'receiver_id'
    ) INTO has_receiver_id;
    
    -- بررسی وجود ستون recipient_id
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'chat_messages' 
        AND column_name = 'recipient_id'
    ) INTO has_recipient_id;
    
    -- اگر receiver_id وجود ندارد ولی recipient_id وجود دارد
    IF NOT has_receiver_id AND has_recipient_id THEN
        -- تغییر نام ستون از recipient_id به receiver_id
        ALTER TABLE chat_messages RENAME COLUMN recipient_id TO receiver_id;
        RAISE NOTICE 'ستون recipient_id به receiver_id تغییر نام یافت';
    ELSIF NOT has_receiver_id AND NOT has_recipient_id THEN
        -- اضافه کردن ستون receiver_id
        ALTER TABLE chat_messages ADD COLUMN receiver_id UUID REFERENCES profiles(id) ON DELETE CASCADE;
        RAISE NOTICE 'ستون receiver_id اضافه شد';
    ELSE
        RAISE NOTICE 'ستون receiver_id از قبل وجود دارد';
    END IF;
END $$;

-- بررسی و اصلاح ایندکس‌ها
DO $$
BEGIN
    -- حذف ایندکس قدیمی اگر وجود دارد
    DROP INDEX IF EXISTS idx_chat_messages_sender_recipient;
    
    -- ایجاد ایندکس جدید
    CREATE INDEX IF NOT EXISTS idx_chat_messages_sender_receiver 
    ON chat_messages(sender_id, receiver_id);
    
    RAISE NOTICE 'ایندکس‌ها به‌روزرسانی شدند';
END $$;

-- بررسی و اصلاح توابع
DO $$
BEGIN
    -- به‌روزرسانی تابع mark_conversation_as_read
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
    
    RAISE NOTICE 'تابع mark_conversation_as_read به‌روزرسانی شد';
END $$;

-- بررسی و اصلاح سیاست‌های RLS
DO $$
BEGIN
    -- حذف سیاست‌های قدیمی
    DROP POLICY IF EXISTS "Users can view messages they sent or received" ON chat_messages;
    DROP POLICY IF EXISTS "Users can insert their own messages" ON chat_messages;
    DROP POLICY IF EXISTS "Users can update their own messages" ON chat_messages;
    
    -- ایجاد سیاست‌های جدید
    CREATE POLICY "Users can view messages they sent or received" ON chat_messages
        FOR SELECT USING (
            auth.uid() = sender_id OR auth.uid() = receiver_id
        );

    CREATE POLICY "Users can insert their own messages" ON chat_messages
        FOR INSERT WITH CHECK (auth.uid() = sender_id);

    CREATE POLICY "Users can update their own messages" ON chat_messages
        FOR UPDATE USING (auth.uid() = sender_id);
    
    RAISE NOTICE 'سیاست‌های RLS به‌روزرسانی شدند';
END $$;

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'اصلاح ستون‌های چت با موفقیت انجام شد!';
    RAISE NOTICE 'ستون receiver_id اکنون در جدول chat_messages موجود است';
    RAISE NOTICE 'ایندکس‌ها، توابع و سیاست‌ها به‌روزرسانی شدند';
END $$;

-- =====================================================
-- نکات:
-- 1. این فایل ستون receiver_id را اضافه یا اصلاح می‌کند
-- 2. ایندکس‌ها و توابع را به‌روزرسانی می‌کند
-- 3. سیاست‌های RLS را اصلاح می‌کند
-- ===================================================== 