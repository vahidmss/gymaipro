-- اصلاح توابع SQL برای حل مشکل ambiguous column

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
