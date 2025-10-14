-- جداول بهینه‌شده برای چت هوش مصنوعی (Hybrid Approach)

-- جدول اصلی session ها (بدون تغییر)
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'چت جدید',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb,
    
    -- فیلدهای جدید برای بهینه‌سازی
    message_count INTEGER DEFAULT 0,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    summary TEXT DEFAULT '', -- خلاصه چت‌های قدیمی
    is_summarized BOOLEAN DEFAULT false
);

-- جدول پیام‌ها (فقط برای پیام‌های اخیر)
CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('user', 'ai', 'summary')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    tokens_used INTEGER DEFAULT 0,
    model_used VARCHAR(100) DEFAULT 'gpt-4o-mini',
    
    -- فیلد جدید برای تشخیص پیام‌های اخیر
    is_recent BOOLEAN DEFAULT true
);

-- جدول چت‌های قدیمی (JSON format)
CREATE TABLE IF NOT EXISTS ai_chat_history (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    messages JSONB NOT NULL, -- تمام پیام‌های قدیمی
    message_count INTEGER NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    archived_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_user_id ON ai_chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_updated_at ON ai_chat_sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session_id ON ai_chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_recent ON ai_chat_messages(session_id, is_recent) WHERE is_recent = true;
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_timestamp ON ai_chat_messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ai_chat_history_session_id ON ai_chat_history(session_id);

-- تریگر برای به‌روزرسانی آمار session
CREATE OR REPLACE FUNCTION update_chat_session_stats()
RETURNS TRIGGER AS $$
BEGIN
    -- به‌روزرسانی تعداد پیام‌ها و زمان آخرین پیام
    UPDATE ai_chat_sessions 
    SET 
        message_count = message_count + 1,
        last_message_at = NEW.timestamp,
        updated_at = NOW()
    WHERE id = NEW.session_id;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_chat_session_stats
    AFTER INSERT ON ai_chat_messages
    FOR EACH ROW
    EXECUTE FUNCTION update_chat_session_stats();

-- تابع برای آرشیو کردن پیام‌های قدیمی
CREATE OR REPLACE FUNCTION archive_old_messages(session_uuid UUID, max_recent_messages INTEGER DEFAULT 20)
RETURNS VOID AS $$
DECLARE
    old_messages JSONB;
    message_count INTEGER;
BEGIN
    -- دریافت پیام‌های قدیمی
    SELECT 
        jsonb_agg(
            jsonb_build_object(
                'id', id,
                'content', content,
                'message_type', message_type,
                'timestamp', timestamp,
                'tokens_used', tokens_used,
                'model_used', model_used
            ) ORDER BY timestamp
        ),
        COUNT(*)
    INTO old_messages, message_count
    FROM ai_chat_messages 
    WHERE session_id = session_uuid 
    AND is_recent = true
    AND id NOT IN (
        SELECT id FROM ai_chat_messages 
        WHERE session_id = session_uuid 
        AND is_recent = true 
        ORDER BY timestamp DESC 
        LIMIT max_recent_messages
    );
    
    -- اگر پیام قدیمی وجود داشت، آرشیو کن
    IF old_messages IS NOT NULL AND jsonb_array_length(old_messages) > 0 THEN
        -- ذخیره در جدول آرشیو
        INSERT INTO ai_chat_history (session_id, user_id, messages, message_count)
        SELECT session_uuid, user_id, old_messages, message_count
        FROM ai_chat_sessions WHERE id = session_uuid;
        
        -- حذف پیام‌های قدیمی از جدول اصلی
        DELETE FROM ai_chat_messages 
        WHERE session_id = session_uuid 
        AND is_recent = true
        AND id NOT IN (
            SELECT id FROM ai_chat_messages 
            WHERE session_id = session_uuid 
            AND is_recent = true 
            ORDER BY timestamp DESC 
            LIMIT max_recent_messages
        );
        
        -- به‌روزرسانی خلاصه session
        UPDATE ai_chat_sessions 
        SET 
            summary = 'چت‌های قبلی آرشیو شدند. ' || message_count || ' پیام در آرشیو موجود است.',
            is_summarized = true
        WHERE id = session_uuid;
    END IF;
END;
$$ LANGUAGE plpgsql;

-- تابع برای دریافت تمام پیام‌های یک session (اخیر + آرشیو)
CREATE OR REPLACE FUNCTION get_complete_chat_history(session_uuid UUID)
RETURNS TABLE (
    id UUID,
    content TEXT,
    message_type VARCHAR(20),
    timestamp TIMESTAMP WITH TIME ZONE,
    tokens_used INTEGER,
    model_used VARCHAR(100),
    is_from_archive BOOLEAN
) AS $$
BEGIN
    -- پیام‌های آرشیو شده
    RETURN QUERY
    SELECT 
        (msg->>'id')::UUID as id,
        msg->>'content' as content,
        msg->>'message_type' as message_type,
        (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE as timestamp,
        (msg->>'tokens_used')::INTEGER as tokens_used,
        msg->>'model_used' as model_used,
        true as is_from_archive
    FROM ai_chat_history h,
         jsonb_array_elements(h.messages) as msg
    WHERE h.session_id = session_uuid
    ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE;
    
    -- پیام‌های اخیر
    RETURN QUERY
    SELECT 
        m.id,
        m.content,
        m.message_type,
        m.timestamp,
        m.tokens_used,
        m.model_used,
        false as is_from_archive
    FROM ai_chat_messages m
    WHERE m.session_id = session_uuid
    AND m.is_recent = true
    ORDER BY m.timestamp;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_history ENABLE ROW LEVEL SECURITY;

-- Policy برای ai_chat_sessions
CREATE POLICY "Users can view their own AI chat sessions" ON ai_chat_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat sessions" ON ai_chat_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat sessions" ON ai_chat_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat sessions" ON ai_chat_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Policy برای ai_chat_messages
CREATE POLICY "Users can view their own AI chat messages" ON ai_chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat messages" ON ai_chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat messages" ON ai_chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat messages" ON ai_chat_messages
    FOR DELETE USING (auth.uid() = user_id);

-- Policy برای ai_chat_history
CREATE POLICY "Users can view their own AI chat history" ON ai_chat_history
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat history" ON ai_chat_history
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat history" ON ai_chat_history
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat history" ON ai_chat_history
    FOR DELETE USING (auth.uid() = user_id);
