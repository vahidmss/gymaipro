-- رفع مشکل ساختار جدول chat_conversations
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. بررسی ساختار جدول موجود
SELECT 'Current table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'chat_conversations' 
AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. اگر جدول وجود ندارد، آن را ایجاد کن
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

-- 3. اگر ستون‌ها وجود ندارند، آنها را اضافه کن
DO $$
BEGIN
    -- اضافه کردن user_id اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'user_id') THEN
        ALTER TABLE chat_conversations ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- اضافه کردن other_user_id اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'other_user_id') THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    
    -- اضافه کردن other_user_name اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'other_user_name') THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_name VARCHAR(255);
    END IF;
    
    -- اضافه کردن other_user_avatar اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'other_user_avatar') THEN
        ALTER TABLE chat_conversations ADD COLUMN other_user_avatar TEXT;
    END IF;
    
    -- اضافه کردن last_message اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'last_message') THEN
        ALTER TABLE chat_conversations ADD COLUMN last_message TEXT;
    END IF;
    
    -- اضافه کردن last_message_at اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'last_message_at') THEN
        ALTER TABLE chat_conversations ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE;
    END IF;
    
    -- اضافه کردن unread_count اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'unread_count') THEN
        ALTER TABLE chat_conversations ADD COLUMN unread_count INTEGER DEFAULT 0;
    END IF;
    
    -- اضافه کردن created_at اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'created_at') THEN
        ALTER TABLE chat_conversations ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
    
    -- اضافه کردن updated_at اگر وجود ندارد
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns 
                   WHERE table_name = 'chat_conversations' AND column_name = 'updated_at') THEN
        ALTER TABLE chat_conversations ADD COLUMN updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 4. ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX IF NOT EXISTS idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);

-- 5. فعال‌سازی RLS
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- 6. حذف policies قدیمی و ایجاد جدید
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

-- 7. فعال‌سازی Real-time
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- 8. بررسی ساختار نهایی
SELECT 'Final table structure:' as info;
SELECT column_name, data_type, is_nullable, column_default
FROM information_schema.columns 
WHERE table_name = 'chat_conversations' 
AND table_schema = 'public'
ORDER BY ordinal_position;
