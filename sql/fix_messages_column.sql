-- اضافه کردن فیلد messages به جدول ai_chat_sessions

-- بررسی وجود جدول
DO $$
BEGIN
    -- اگر جدول وجود دارد، فیلد messages را اضافه کن
    IF EXISTS (SELECT FROM information_schema.tables WHERE table_name = 'ai_chat_sessions') THEN
        -- اضافه کردن فیلد messages اگر وجود ندارد
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ai_chat_sessions' AND column_name = 'messages') THEN
            ALTER TABLE ai_chat_sessions ADD COLUMN messages JSONB DEFAULT '[]'::jsonb;
        END IF;
        
        -- اضافه کردن فیلد message_count اگر وجود ندارد
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ai_chat_sessions' AND column_name = 'message_count') THEN
            ALTER TABLE ai_chat_sessions ADD COLUMN message_count INTEGER DEFAULT 0;
        END IF;
        
        -- اضافه کردن فیلد settings اگر وجود ندارد
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ai_chat_sessions' AND column_name = 'settings') THEN
            ALTER TABLE ai_chat_sessions ADD COLUMN settings JSONB DEFAULT '{
                "model": "gpt-4o-mini",
                "temperature": 0.7,
                "max_tokens": 800
            }'::jsonb;
        END IF;
        
        -- اضافه کردن فیلد total_tokens_used اگر وجود ندارد
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ai_chat_sessions' AND column_name = 'total_tokens_used') THEN
            ALTER TABLE ai_chat_sessions ADD COLUMN total_tokens_used INTEGER DEFAULT 0;
        END IF;
        
        -- اضافه کردن فیلد last_message_at اگر وجود ندارد
        IF NOT EXISTS (SELECT FROM information_schema.columns WHERE table_name = 'ai_chat_sessions' AND column_name = 'last_message_at') THEN
            ALTER TABLE ai_chat_sessions ADD COLUMN last_message_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
        END IF;
        
        RAISE NOTICE 'فیلدهای مورد نیاز به جدول ai_chat_sessions اضافه شدند';
    ELSE
        RAISE NOTICE 'جدول ai_chat_sessions وجود ندارد. لطفاً ابتدا مرحله 2 را اجرا کنید';
    END IF;
END $$;
