-- مرحله 2: ایجاد جداول جدید

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
