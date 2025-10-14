-- جداول مربوط به چت هوش مصنوعی

-- جدول اصلی چت‌های هوش مصنوعی
CREATE TABLE IF NOT EXISTS ai_chat_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    title VARCHAR(255) NOT NULL DEFAULT 'چت جدید',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}'::jsonb
);

-- جدول پیام‌های چت هوش مصنوعی
CREATE TABLE IF NOT EXISTS ai_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES ai_chat_sessions(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    message_type VARCHAR(20) NOT NULL CHECK (message_type IN ('user', 'ai')),
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    metadata JSONB DEFAULT '{}'::jsonb,
    tokens_used INTEGER DEFAULT 0,
    model_used VARCHAR(100) DEFAULT 'gpt-4o-mini'
);

-- جدول تنظیمات چت هوش مصنوعی برای هر کاربر
CREATE TABLE IF NOT EXISTS ai_chat_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE UNIQUE,
    model VARCHAR(100) DEFAULT 'gpt-4o-mini',
    temperature DECIMAL(3,2) DEFAULT 0.7,
    max_tokens INTEGER DEFAULT 1000,
    system_prompt TEXT DEFAULT '',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایندکس‌ها برای بهبود عملکرد
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_user_id ON ai_chat_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_sessions_created_at ON ai_chat_sessions(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_session_id ON ai_chat_messages(session_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_user_id ON ai_chat_messages(user_id);
CREATE INDEX IF NOT EXISTS idx_ai_chat_messages_timestamp ON ai_chat_messages(timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_ai_chat_settings_user_id ON ai_chat_settings(user_id);

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_ai_chat_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ai_chat_sessions_updated_at
    BEFORE UPDATE ON ai_chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_chat_sessions_updated_at();

-- تریگر برای به‌روزرسانی updated_at در تنظیمات
CREATE OR REPLACE FUNCTION update_ai_chat_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_ai_chat_settings_updated_at
    BEFORE UPDATE ON ai_chat_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_chat_settings_updated_at();

-- RLS (Row Level Security) policies
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_messages ENABLE ROW LEVEL SECURITY;
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

-- Policy برای ai_chat_messages
CREATE POLICY "Users can view their own AI chat messages" ON ai_chat_messages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat messages" ON ai_chat_messages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat messages" ON ai_chat_messages
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat messages" ON ai_chat_messages
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

-- تابع برای ایجاد تنظیمات پیش‌فرض چت
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
CREATE TRIGGER trigger_create_default_ai_chat_settings
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_ai_chat_settings();
