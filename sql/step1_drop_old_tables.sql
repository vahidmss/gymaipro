-- مرحله 1: حذف جداول و توابع قدیمی

-- حذف جداول قدیمی
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
