-- آپدیت جداول چت هوش مصنوعی (JSON Approach)
-- این فایل فقط تغییرات جدید را اعمال می‌کند

-- حذف جداول قدیمی اگر وجود دارند
DROP TABLE IF EXISTS ai_chat_messages CASCADE;
DROP TABLE IF EXISTS ai_chat_sessions CASCADE;
DROP TABLE IF EXISTS ai_chat_settings CASCADE;

-- حذف توابع قدیمی
DROP FUNCTION IF EXISTS update_ai_chat_sessions_updated_at() CASCADE;
DROP FUNCTION IF EXISTS add_chat_message(UUID, TEXT, VARCHAR, INTEGER, VARCHAR) CASCADE;
DROP FUNCTION IF EXISTS get_recent_messages(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS summarize_old_messages(UUID, INTEGER) CASCADE;
DROP FUNCTION IF EXISTS create_default_ai_chat_settings() CASCADE;

-- حذف تریگرهای قدیمی
DROP TRIGGER IF EXISTS trigger_update_ai_chat_sessions_updated_at ON ai_chat_sessions;
DROP TRIGGER IF EXISTS trigger_create_default_ai_chat_settings ON auth.users;

-- جدول اصلی چت‌ها (هر چت = یک سطر)
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'چت جدید',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    
    -- تمام پیام‌ها به صورت JSON
    messages JSONB DEFAULT '[]'::jsonb,
    message_count INTEGER DEFAULT 0,
    
    -- تنظیمات چت
    settings JSONB DEFAULT '{
        "model": "gpt-4o-mini",
        "temperature": 0.7,
        "max_tokens": 800
    }'::jsonb,
    
    -- آمار
    total_tokens_used INTEGER DEFAULT 0,
    last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- جدول تنظیمات چت کاربر (اختیاری)
CREATE TABLE IF NOT EXISTS ai_chat_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    default_model VARCHAR(100) DEFAULT 'gpt-4o-mini',
    default_temperature DECIMAL(3,2) DEFAULT 0.7,
    default_max_tokens INTEGER DEFAULT 800,
    system_prompt TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_user_id ON ai_chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_updated_at ON ai_chat_sessions(updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_active ON ai_chat_sessions(user_id, is_active) WHERE is_active = true;
CREATE INDEX IF NOT EXISTS idx_ai_chat_settings_user_id ON ai_chat_settings(user_id);

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_ai_chat_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_message_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ai_chat_sessions_updated_at
    BEFORE UPDATE ON ai_chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_chat_sessions_updated_at();

-- تابع برای اضافه کردن پیام جدید
CREATE OR REPLACE FUNCTION add_chat_message(
    session_uuid UUID,
    message_content TEXT,
    message_type VARCHAR(20),
    tokens_used INTEGER DEFAULT 0,
    model_used VARCHAR(100) DEFAULT 'gpt-4o-mini'
)
RETURNS VOID AS $$
DECLARE
    new_message JSONB;
    current_messages JSONB;
BEGIN
    -- ساخت پیام جدید
    new_message := jsonb_build_object(
        'id', gen_random_uuid(),
        'content', message_content,
        'message_type', message_type,
        'timestamp', NOW(),
        'tokens_used', tokens_used,
        'model_used', model_used
    );
    
    -- دریافت پیام‌های فعلی
    SELECT messages INTO current_messages 
    FROM ai_chat_sessions 
    WHERE id = session_uuid;
    
    -- اضافه کردن پیام جدید
    current_messages := current_messages || jsonb_build_array(new_message);
    
    -- به‌روزرسانی session
    UPDATE ai_chat_sessions 
    SET 
        messages = current_messages,
        message_count = jsonb_array_length(current_messages),
        total_tokens_used = total_tokens_used + tokens_used,
        updated_at = NOW(),
        last_message_at = NOW()
    WHERE id = session_uuid;
END;
$$ LANGUAGE plpgsql;

-- تابع برای دریافت پیام‌های اخیر (برای OpenAI)
CREATE OR REPLACE FUNCTION get_recent_messages(
    session_uuid UUID,
    max_messages INTEGER DEFAULT 20
)
RETURNS JSONB AS $$
DECLARE
    all_messages JSONB;
    recent_messages JSONB;
    message_count INTEGER;
BEGIN
    -- دریافت تمام پیام‌ها
    SELECT messages, message_count 
    INTO all_messages, message_count
    FROM ai_chat_sessions 
    WHERE id = session_uuid;
    
    -- اگر پیام‌ها کمتر از حد مجاز هستن، همه رو برگردون
    IF message_count <= max_messages THEN
        RETURN all_messages;
    END IF;
    
    -- فقط آخرین پیام‌ها رو برگردون
    recent_messages := (
        SELECT jsonb_agg(msg ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE)
        FROM (
            SELECT msg
            FROM jsonb_array_elements(all_messages) as msg
            ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE DESC
            LIMIT max_messages
        ) as recent
    );
    
    RETURN recent_messages;
END;
$$ LANGUAGE plpgsql;

-- تابع برای خلاصه‌سازی پیام‌های قدیمی
CREATE OR REPLACE FUNCTION summarize_old_messages(
    session_uuid UUID,
    max_recent_messages INTEGER DEFAULT 20
)
RETURNS VOID AS $$
DECLARE
    all_messages JSONB;
    recent_messages JSONB;
    old_messages JSONB;
    summary_message JSONB;
    message_count INTEGER;
BEGIN
    -- دریافت تمام پیام‌ها
    SELECT messages, message_count 
    INTO all_messages, message_count
    FROM ai_chat_sessions 
    WHERE id = session_uuid;
    
    -- اگر پیام‌ها کمتر از حد مجاز هستن، کاری نکن
    IF message_count <= max_recent_messages THEN
        RETURN;
    END IF;
    
    -- جدا کردن پیام‌های قدیمی و اخیر
    old_messages := (
        SELECT jsonb_agg(msg ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE)
        FROM (
            SELECT msg
            FROM jsonb_array_elements(all_messages) as msg
            ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE DESC
            OFFSET max_recent_messages
        ) as old
    );
    
    recent_messages := (
        SELECT jsonb_agg(msg ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE)
        FROM (
            SELECT msg
            FROM jsonb_array_elements(all_messages) as msg
            ORDER BY (msg->>'timestamp')::TIMESTAMP WITH TIME ZONE DESC
            LIMIT max_recent_messages
        ) as recent
    );
    
    -- ایجاد پیام خلاصه
    summary_message := jsonb_build_object(
        'id', gen_random_uuid(),
        'content', 'خلاصه چت‌های قبلی: ' || jsonb_array_length(old_messages) || ' پیام آرشیو شدند.',
        'message_type', 'summary',
        'timestamp', NOW(),
        'tokens_used', 0,
        'model_used', 'system'
    );
    
    -- ترکیب خلاصه + پیام‌های اخیر
    recent_messages := jsonb_build_array(summary_message) || recent_messages;
    
    -- به‌روزرسانی session
    UPDATE ai_chat_sessions 
    SET 
        messages = recent_messages,
        message_count = jsonb_array_length(recent_messages),
        updated_at = NOW()
    WHERE id = session_uuid;
END;
$$ LANGUAGE plpgsql;

-- RLS Policies
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_settings ENABLE ROW LEVEL SECURITY;

-- Policy برای ai_chat_sessions
CREATE POLICY "Users can view their own AI chat sessions" ON ai_chat_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat sessions" ON ai_chat_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat sessions" ON ai_chat_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat sessions" ON ai_chat_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Policy برای ai_chat_settings
CREATE POLICY "Users can view their own AI chat settings" ON ai_chat_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat settings" ON ai_chat_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat settings" ON ai_chat_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat settings" ON ai_chat_settings
    FOR DELETE USING (auth.uid() = user_id);

-- تابع برای ایجاد تنظیمات پیش‌فرض
CREATE OR REPLACE FUNCTION create_default_ai_chat_settings()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO ai_chat_settings (user_id, system_prompt)
    VALUES (NEW.id, 'شما یک مربی ورزشی و متخصص تغذیه هوش مصنوعی هستید که به کاربران در زمینه‌های ورزش و تغذیه کمک می‌کنید.')
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای ایجاد تنظیمات پیش‌فرض هنگام ثبت‌نام کاربر جدید
-- این تریگر بعد از ایجاد جداول اضافه می‌شود
