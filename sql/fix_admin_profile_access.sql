-- رفع مشکل دسترسی ادمین به پروفایل خودش
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. حذف policy های قدیمی که ممکن است مشکل ایجاد کنند
DROP POLICY IF EXISTS "Users can view their own profile" ON profiles;
DROP POLICY IF EXISTS "Authenticated users can view public profiles" ON profiles;

-- 2. Policy برای مشاهده پروفایل خود کاربر (اولویت اول)
CREATE POLICY "Users can view their own profile" ON profiles
    FOR SELECT
    USING (auth.uid() = id);

-- 3. Policy برای مشاهده تمام پروفایل‌ها توسط کاربران احراز هویت شده
CREATE POLICY "Authenticated users can view all profiles" ON profiles
    FOR SELECT
    USING (auth.role() = 'authenticated');

-- 4. Policy برای مشاهده تمام پروفایل‌ها توسط ادمین (برای پنل ادمین)
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

-- 5. Policy برای به‌روزرسانی پروفایل خود کاربر
DROP POLICY IF EXISTS "Users can update their own profile" ON profiles;

CREATE POLICY "Users can update their own profile" ON profiles
    FOR UPDATE
    USING (auth.uid() = id);

-- 6. Policy برای به‌روزرسانی پروفایل‌ها توسط ادمین (برای تغییر نقش)
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

-- 7. Policy برای حذف پروفایل‌ها توسط ادمین
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
SELECT 'Profile access policies updated successfully' as status;

