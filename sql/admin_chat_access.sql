-- اضافه کردن دسترسی ادمین به چت‌های خصوصی
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. Policy برای مشاهده تمام مکالمات توسط ادمین
DROP POLICY IF EXISTS "Admins can view all conversations" ON chat_conversations;

CREATE POLICY "Admins can view all conversations" ON chat_conversations
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 2. Policy برای حذف مکالمات توسط ادمین
DROP POLICY IF EXISTS "Admins can delete all conversations" ON chat_conversations;

CREATE POLICY "Admins can delete all conversations" ON chat_conversations
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 3. Policy برای به‌روزرسانی مکالمات توسط ادمین (برای ارسال هشدار)
DROP POLICY IF EXISTS "Admins can update all conversations" ON chat_conversations;

CREATE POLICY "Admins can update all conversations" ON chat_conversations
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 4. Policy برای مشاهده تمام پیام‌های چت عمومی توسط ادمین
DROP POLICY IF EXISTS "Admins can view all public chat messages" ON public_chat_messages;

CREATE POLICY "Admins can view all public chat messages" ON public_chat_messages
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 5. Policy برای حذف پیام‌های چت عمومی توسط ادمین
DROP POLICY IF EXISTS "Admins can delete public chat messages" ON public_chat_messages;

CREATE POLICY "Admins can delete public chat messages" ON public_chat_messages
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles
            WHERE profiles.id = auth.uid()
            AND profiles.role = 'admin'
        )
    );

-- 6. Policy برای مشاهده تمام پروفایل‌ها توسط ادمین
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;

CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role = 'admin'
        )
    );

-- 7. Policy برای به‌روزرسانی پروفایل‌ها توسط ادمین (برای تغییر نقش)
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role = 'admin'
        )
    );

-- 8. Policy برای حذف پروفایل‌ها توسط ادمین
DROP POLICY IF EXISTS "Admins can delete all profiles" ON profiles;

CREATE POLICY "Admins can delete all profiles" ON profiles
    FOR DELETE
    USING (
        EXISTS (
            SELECT 1 FROM profiles p
            WHERE p.id = auth.uid()
            AND p.role = 'admin'
        )
    );

-- بررسی نتیجه
SELECT 'Admin access policies created successfully' as status;

