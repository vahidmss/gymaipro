-- رفع خطای RLS برای شارژ دستی کیف پول توسط ادمین
-- خطا: new row violates row-level security policy for table "wallet_transactions"
-- این اسکریپت را در Supabase Studio > SQL Editor اجرا کنید.

-- 1. تابع check_admin_role را به‌روز می‌کنیم تا هم id و هم auth_user_id را چک کند
CREATE OR REPLACE FUNCTION check_admin_role()
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
STABLE
AS $$
DECLARE
    user_role TEXT;
    uid UUID;
BEGIN
    uid := auth.uid();
    IF uid IS NULL THEN
        RETURN FALSE;
    END IF;

    -- اگر ستون auth_user_id وجود دارد، هر دو را چک کن
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public' AND table_name = 'profiles' AND column_name = 'auth_user_id'
    ) THEN
        SELECT role INTO user_role
        FROM public.profiles
        WHERE id = uid OR auth_user_id = uid
        LIMIT 1;
    ELSE
        SELECT role INTO user_role
        FROM public.profiles
        WHERE id = uid
        LIMIT 1;
    END IF;

    RETURN COALESCE(user_role, '') = 'admin';
EXCEPTION
    WHEN OTHERS THEN
        RETURN FALSE;
END;
$$;

GRANT EXECUTE ON FUNCTION check_admin_role() TO authenticated;

-- 2. پالیسی‌های ادمین برای wallet_transactions (درج تراکنش شارژ)
DROP POLICY IF EXISTS "Admins can view all wallet transactions" ON wallet_transactions;
CREATE POLICY "Admins can view all wallet transactions" ON wallet_transactions
    FOR SELECT
    USING (check_admin_role());

DROP POLICY IF EXISTS "Admins can create wallet transactions" ON wallet_transactions;
CREATE POLICY "Admins can create wallet transactions" ON wallet_transactions
    FOR INSERT
    WITH CHECK (check_admin_role());

DROP POLICY IF EXISTS "Admins can update wallet transactions" ON wallet_transactions;
CREATE POLICY "Admins can update wallet transactions" ON wallet_transactions
    FOR UPDATE
    USING (check_admin_role());

-- 3. پالیسی‌های ادمین برای wallets (در صورت نبود)
DROP POLICY IF EXISTS "Admins can view all wallets" ON wallets;
CREATE POLICY "Admins can view all wallets" ON wallets
    FOR SELECT
    USING (check_admin_role());

DROP POLICY IF EXISTS "Admins can update all wallets" ON wallets;
CREATE POLICY "Admins can update all wallets" ON wallets
    FOR UPDATE
    USING (check_admin_role());

DROP POLICY IF EXISTS "Admins can create wallets" ON wallets;
CREATE POLICY "Admins can create wallets" ON wallets
    FOR INSERT
    WITH CHECK (check_admin_role());

SELECT 'Admin wallet and wallet_transactions RLS fixed. Try charging again.' AS status;
