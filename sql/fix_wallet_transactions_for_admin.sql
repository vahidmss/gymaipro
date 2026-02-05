-- اصلاح جدول wallet_transactions برای پشتیبانی از عملیات ادمین
-- این کد را در Supabase Studio > SQL Editor اجرا کنید

-- 1. اضافه کردن type 'adjustment' به check constraint
-- ابتدا constraint قدیمی را حذف می‌کنیم
ALTER TABLE wallet_transactions 
DROP CONSTRAINT IF EXISTS wallet_transactions_type_check;

-- اضافه کردن constraint جدید با type 'adjustment'
ALTER TABLE wallet_transactions 
ADD CONSTRAINT wallet_transactions_type_check 
CHECK (type IN ('charge', 'payment', 'refund', 'bonus', 'block', 'unblock', 'adjustment'));

-- 2. اضافه کردن فیلد balance_before اگر وجود ندارد
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wallet_transactions' 
        AND column_name = 'balance_before'
    ) THEN
        ALTER TABLE wallet_transactions 
        ADD COLUMN balance_before INTEGER;
    END IF;
END $$;

-- 3. اضافه کردن فیلد user_id اگر وجود ندارد
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'wallet_transactions' 
        AND column_name = 'user_id'
    ) THEN
        ALTER TABLE wallet_transactions 
        ADD COLUMN user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 4. اضافه کردن foreign key برای admin_wallet_actions به profiles
-- ابتدا foreign key های قدیمی را حذف می‌کنیم (اگر وجود دارند)
ALTER TABLE admin_wallet_actions 
DROP CONSTRAINT IF EXISTS admin_wallet_actions_admin_id_fkey;

ALTER TABLE admin_wallet_actions 
DROP CONSTRAINT IF EXISTS admin_wallet_actions_target_user_id_fkey;

-- اضافه کردن foreign key به profiles (نه auth.users)
-- اما چون admin_id و target_user_id به auth.users reference دارند،
-- باید از طریق auth.users به profiles دسترسی داشته باشیم
-- در واقع، foreign key به profiles نمی‌توانیم اضافه کنیم چون profiles.id = auth.users.id
-- پس باید join را در کد انجام دهیم

-- بررسی نتیجه
SELECT 'Wallet transactions table updated successfully' as status;

