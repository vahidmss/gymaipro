-- اضافه کردن دسترسی ادمین به کیف پول‌ها و تراکنش‌های کیف پول
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- اطمینان از وجود function check_admin_role
-- اگر قبلاً ایجاد نشده، آن را ایجاد می‌کنیم
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

-- 1. Policy برای مشاهده تمام کیف پول‌ها توسط ادمین
DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;

CREATE POLICY "Admins can view all wallets" ON wallets
    FOR SELECT
    USING (check_admin_role());

-- 2. Policy برای به‌روزرسانی کیف پول‌ها توسط ادمین (برای شارژ دستی)
DROP POLICY IF EXISTS "Admins can update all wallets" ON wallets;

CREATE POLICY "Admins can update all wallets" ON wallets
    FOR UPDATE
    USING (check_admin_role());

-- 3. Policy برای ایجاد کیف پول توسط ادمین (در صورت نیاز)
DROP POLICY IF EXISTS "Admins can create wallets" ON wallets;

CREATE POLICY "Admins can create wallets" ON wallets
    FOR INSERT
    WITH CHECK (check_admin_role());

-- 4. Policy برای مشاهده تمام تراکنش‌های کیف پول توسط ادمین
DROP POLICY IF EXISTS "Admins can view all wallet transactions" ON wallet_transactions;

CREATE POLICY "Admins can view all wallet transactions" ON wallet_transactions
    FOR SELECT
    USING (check_admin_role());

-- 5. Policy برای ایجاد تراکنش‌های کیف پول توسط ادمین (برای شارژ دستی)
DROP POLICY IF EXISTS "Admins can create wallet transactions" ON wallet_transactions;

CREATE POLICY "Admins can create wallet transactions" ON wallet_transactions
    FOR INSERT
    WITH CHECK (check_admin_role());

-- 6. Policy برای به‌روزرسانی تراکنش‌های کیف پول توسط ادمین
DROP POLICY IF EXISTS "Admins can update wallet transactions" ON wallet_transactions;

CREATE POLICY "Admins can update wallet transactions" ON wallet_transactions
    FOR UPDATE
    USING (check_admin_role());

-- بررسی نتیجه
SELECT 'Admin wallet access policies created successfully' as status;

