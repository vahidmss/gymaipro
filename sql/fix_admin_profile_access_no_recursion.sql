-- رفع مشکل infinite recursion در RLS policies
-- این کد را در Supabase Studio > SQL Editor اجرا کنید
-- این نسخه از recursion جلوگیری می‌کند

-- 1. حذف تمام policy های قدیمی که ممکن است مشکل ایجاد کنند
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can delete all profiles" ON profiles;

-- 2. Policy برای مشاهده پروفایل خود کاربر (اولویت اول - بدون recursion)
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- 3. Policy برای مشاهده تمام پروفایل‌ها توسط کاربران احراز هویت شده
-- این policy به کاربران عادی اجازه می‌دهد پروفایل‌های دیگر را ببینند
CREATE POLICY "Authenticated users can view all profiles" ON profiles
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- 4. Policy برای به‌روزرسانی پروفایل خود کاربر
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- 5. Policy برای به‌روزرسانی پروفایل‌ها توسط ادمین
-- استفاده از SECURITY DEFINER function برای جلوگیری از recursion
-- این function با دسترسی owner اجرا می‌شود و RLS را bypass می‌کند
CREATE OR REPLACE FUNCTION check_admin_role()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    user_role TEXT;
    user_id UUID;
BEGIN
    -- گرفتن user_id از auth context
    user_id := auth.uid();
    
    IF user_id IS NULL THEN
        RETURN FALSE;
    END IF;
    
    -- خواندن مستقیم از profiles بدون RLS (به دلیل SECURITY DEFINER)
    SELECT role INTO user_role
    FROM public.profiles
    WHERE id = user_id
    LIMIT 1;
    
    RETURN COALESCE(user_role, '') = 'admin';
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;

-- Policy برای مشاهده تمام پروفایل‌ها توسط ادمین (با استفاده از function)
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT
    USING (check_admin_role());

-- Policy برای به‌روزرسانی پروفایل‌ها توسط ادمین (با استفاده از function)
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE
    USING (check_admin_role());

-- Policy برای حذف پروفایل‌ها توسط ادمین (با استفاده از function)
CREATE POLICY "Admins can delete all profiles" ON profiles
    FOR DELETE
    USING (check_admin_role());

-- 6. اصلاح policies برای chat_conversations
DROP POLICY IF EXISTS "Admins can view all conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Admins can delete all conversations" ON chat_conversations;
DROP POLICY IF EXISTS "Admins can update all conversations" ON chat_conversations;

CREATE POLICY "Admins can view all conversations" ON chat_conversations
    FOR SELECT
    USING (check_admin_role());

CREATE POLICY "Admins can delete all conversations" ON chat_conversations
    FOR DELETE
    USING (check_admin_role());

CREATE POLICY "Admins can update all conversations" ON chat_conversations
    FOR UPDATE
    USING (check_admin_role());

-- 7. اصلاح policies برای public_chat_messages
DROP POLICY IF EXISTS "Admins can view all public chat messages" ON public_chat_messages;
DROP POLICY IF EXISTS "Admins can delete public chat messages" ON public_chat_messages;

CREATE POLICY "Admins can view all public chat messages" ON public_chat_messages
    FOR SELECT
    USING (check_admin_role());

CREATE POLICY "Admins can delete public chat messages" ON public_chat_messages
    FOR UPDATE
    USING (check_admin_role());

-- بررسی نتیجه
SELECT 'Profile access policies updated successfully (no recursion)' as status;

