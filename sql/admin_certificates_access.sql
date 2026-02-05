-- دسترسی ادمین به جدول certificates
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- اطمینان از وجود function check_admin_role
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

-- Policy برای مشاهده تمام مدارک توسط ادمین
DROP POLICY IF EXISTS "Admins can view all certificates" ON public.certificates;
CREATE POLICY "Admins can view all certificates" ON public.certificates
    FOR SELECT
    USING (check_admin_role());

-- Policy برای به‌روزرسانی مدارک توسط ادمین (تایید/رد)
DROP POLICY IF EXISTS "Admins can update certificates" ON public.certificates;
CREATE POLICY "Admins can update certificates" ON public.certificates
    FOR UPDATE
    USING (check_admin_role())
    WITH CHECK (check_admin_role());

-- Policy برای حذف مدارک توسط ادمین
DROP POLICY IF EXISTS "Admins can delete certificates" ON public.certificates;
CREATE POLICY "Admins can delete certificates" ON public.certificates
    FOR DELETE
    USING (check_admin_role());

-- بررسی نتیجه
SELECT 'Admin certificates access policies created successfully' as status;

