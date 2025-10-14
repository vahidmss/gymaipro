-- مرحله 4: ایجاد تریگرها و RLS Policies

-- تریگر برای به‌روزرسانی updated_at
DROP TRIGGER IF EXISTS trigger_update_ai_chat_sessions_updated_at ON ai_chat_sessions;
CREATE TRIGGER trigger_update_ai_chat_sessions_updated_at
    BEFORE UPDATE ON ai_chat_sessions
    FOR EACH ROW
    EXECUTE FUNCTION update_ai_chat_sessions_updated_at();

-- تریگر برای ایجاد تنظیمات پیش‌فرض هنگام ثبت‌نام کاربر جدید
DROP TRIGGER IF EXISTS trigger_create_default_ai_chat_settings ON auth.users;
CREATE TRIGGER trigger_create_default_ai_chat_settings
    AFTER INSERT ON auth.users
    FOR EACH ROW
    EXECUTE FUNCTION create_default_ai_chat_settings();

-- RLS Policies
ALTER TABLE ai_chat_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE ai_chat_settings ENABLE ROW LEVEL SECURITY;

-- Policy برای ai_chat_sessions
DROP POLICY IF EXISTS "Users can view their own AI chat sessions" ON ai_chat_sessions;
DROP POLICY IF EXISTS "Users can insert their own AI chat sessions" ON ai_chat_sessions;
DROP POLICY IF EXISTS "Users can update their own AI chat sessions" ON ai_chat_sessions;
DROP POLICY IF EXISTS "Users can delete their own AI chat sessions" ON ai_chat_sessions;

CREATE POLICY "Users can view their own AI chat sessions" ON ai_chat_sessions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat sessions" ON ai_chat_sessions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat sessions" ON ai_chat_sessions
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat sessions" ON ai_chat_sessions
    FOR DELETE USING (auth.uid() = user_id);

-- Policy برای ai_chat_settings
DROP POLICY IF EXISTS "Users can view their own AI chat settings" ON ai_chat_settings;
DROP POLICY IF EXISTS "Users can insert their own AI chat settings" ON ai_chat_settings;
DROP POLICY IF EXISTS "Users can update their own AI chat settings" ON ai_chat_settings;
DROP POLICY IF EXISTS "Users can delete their own AI chat settings" ON ai_chat_settings;

CREATE POLICY "Users can view their own AI chat settings" ON ai_chat_settings
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own AI chat settings" ON ai_chat_settings
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own AI chat settings" ON ai_chat_settings
    FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Users can delete their own AI chat settings" ON ai_chat_settings
    FOR DELETE USING (auth.uid() = user_id);
