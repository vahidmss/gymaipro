-- رفع سریع مشکل chat_conversations
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. حذف جدول قدیمی اگر وجود دارد
DROP TABLE IF EXISTS chat_conversations CASCADE;

-- 2. ایجاد جدول جدید با ساختار صحیح
CREATE TABLE chat_conversations (
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

-- 3. ایجاد ایندکس‌ها
CREATE INDEX idx_chat_conversations_user_id ON chat_conversations(user_id);
CREATE INDEX idx_chat_conversations_last_message_at ON chat_conversations(last_message_at DESC);

-- 4. فعال‌سازی RLS
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies
CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own conversations" ON chat_conversations
    FOR DELETE USING (auth.uid() = user_id);

-- 6. فعال‌سازی Real-time
ALTER PUBLICATION supabase_realtime ADD TABLE chat_conversations;

-- 7. بررسی نتیجه
SELECT 'Chat conversations table created successfully' as status;
SELECT column_name, data_type FROM information_schema.columns 
WHERE table_name = 'chat_conversations' ORDER BY ordinal_position;
