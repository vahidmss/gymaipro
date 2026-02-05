-- رفع مشکل دسترسی ادمین به داشبورد
-- این کد را در Supabase Studio > SQL Editor اجرا کنید
-- بعد از اجرا، از اپ خارج شوید و دوباره وارد شوید

-- 1. بررسی نقش کاربر فعلی (جایگزین کنید با user_id واقعی)
-- SELECT id, username, role FROM profiles WHERE role = 'admin';

-- 2. اطمینان از وجود function check_admin_role
-- این function با SECURITY DEFINER اجرا می‌شود و RLS را bypass می‌کند
DROP FUNCTION IF EXISTS check_admin_role();
CREATE FUNCTION check_admin_role()
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
    -- این مهم است چون RLS را bypass می‌کند
    SELECT role INTO user_role
    FROM public.profiles
    WHERE id = user_id
    LIMIT 1;
    
    RETURN COALESCE(user_role, '') = 'admin';
EXCEPTION
    WHEN OTHERS THEN
        -- در صورت خطا، false برمی‌گرداند
        RETURN FALSE;
END;
$$;

-- اعطای دسترسی execute به authenticated users
GRANT EXECUTE ON FUNCTION check_admin_role() TO authenticated;

-- 3. حذف policy های قدیمی که ممکن است مشکل ایجاد کنند
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Admins can view all profiles" ON profiles;
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;
DROP POLICY IF EXISTS "Admins can update all profiles" ON profiles;

-- 4. ایجاد policy های جدید (بدون recursion)
-- Policy برای مشاهده پروفایل خود کاربر (اولویت اول)
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- Policy برای مشاهده تمام پروفایل‌ها توسط کاربران احراز هویت شده
CREATE POLICY "Authenticated users can view all profiles" ON profiles
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- Policy برای مشاهده تمام پروفایل‌ها توسط ادمین (با استفاده از function)
CREATE POLICY "Admins can view all profiles" ON profiles
    FOR SELECT
    USING (check_admin_role());

-- Policy برای به‌روزرسانی پروفایل خود کاربر
CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- Policy برای به‌روزرسانی پروفایل‌ها توسط ادمین
CREATE POLICY "Admins can update all profiles" ON profiles
    FOR UPDATE
    USING (check_admin_role());

-- 5. بررسی نقش کاربران (برای debug)
-- این کوئری را اجرا کنید تا ببینید نقش کاربران چیست
SELECT 
    id,
    username,
    role,
    created_at
FROM profiles
WHERE role = 'admin'
ORDER BY created_at DESC;

-- 6. اگر نقش کاربر به admin تغییر داده شده اما هنوز کار نمی‌کند:
-- این کوئری را اجرا کنید (user_id را با ID واقعی کاربر جایگزین کنید)
-- UPDATE profiles SET role = 'admin' WHERE id = 'USER_ID_HERE';

-- 7. بررسی RLS status
SELECT 
    schemaname,
    tablename,
    rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'profiles' AND schemaname = 'public';

-- 8. بررسی policies موجود
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual,
    with_check
FROM pg_policies
WHERE tablename = 'profiles'
ORDER BY policyname;

-- نتیجه
SELECT 'Admin access policies updated successfully. Please logout and login again.' as status;

