-- =====================================================
-- رفع مشکل RLS برای جدول chat_conversations
-- =====================================================

-- حذف سیاست‌های قدیمی chat_conversations
DROP POLICY IF EXISTS "Users can view their own conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can insert conversations" ON chat_conversations;
DROP POLICY IF EXISTS "System can update conversations" ON chat_conversations;

-- ایجاد سیاست‌های جدید و صحیح
-- کاربران می‌توانند گفتگوهای خودشان را ببینند
CREATE POLICY "Users can view their own conversations" ON chat_conversations
    FOR SELECT USING (auth.uid() = user_id);

-- سیستم می‌تواند گفتگوها را درج کند (برای تریگر update_chat_conversation)
CREATE POLICY "System can insert conversations" ON chat_conversations
    FOR INSERT WITH CHECK (true);

-- سیستم می‌تواند گفتگوها را به‌روزرسانی کند (برای تریگر update_chat_conversation)
CREATE POLICY "System can update conversations" ON chat_conversations
    FOR UPDATE USING (true);

-- کاربران می‌توانند گفتگوهای خودشان را به‌روزرسانی کنند
CREATE POLICY "Users can update their own conversations" ON chat_conversations
    FOR UPDATE USING (auth.uid() = user_id);

-- پیام تأیید
DO $$
BEGIN
    RAISE NOTICE 'سیاست‌های RLS برای chat_conversations اصلاح شدند!';
    RAISE NOTICE 'حالا سیستم چت باید بدون خطا کار کند.';
END $$; 