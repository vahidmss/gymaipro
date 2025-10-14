-- مرحله 3: ایجاد توابع SQL

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_ai_chat_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    NEW.last_message_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

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
    total_count INTEGER;
BEGIN
    -- دریافت تمام پیام‌ها
    SELECT messages, ai_chat_sessions.message_count 
    INTO all_messages, total_count
    FROM ai_chat_sessions 
    WHERE id = session_uuid;
    
    -- اگر پیام‌ها کمتر از حد مجاز هستن، همه رو برگردون
    IF total_count <= max_messages THEN
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
    total_count INTEGER;
BEGIN
    -- دریافت تمام پیام‌ها
    SELECT messages, ai_chat_sessions.message_count 
    INTO all_messages, total_count
    FROM ai_chat_sessions 
    WHERE id = session_uuid;
    
    -- اگر پیام‌ها کمتر از حد مجاز هستن، کاری نکن
    IF total_count <= max_recent_messages THEN
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
