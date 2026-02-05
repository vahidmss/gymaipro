-- جدول ثبت عملیات ادمین روی کیف پول‌ها
CREATE TABLE IF NOT EXISTS admin_wallet_actions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    admin_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    target_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    action_type VARCHAR(20) NOT NULL CHECK (action_type IN ('charge', 'adjustment')),
    amount INTEGER NOT NULL,
    balance_before INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    available_balance_before INTEGER,
    available_balance_after INTEGER,
    description TEXT,
    wallet_id TEXT REFERENCES wallets(id) ON DELETE SET NULL,
    transaction_id TEXT REFERENCES wallet_transactions(id) ON DELETE SET NULL,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایجاد ایندکس‌ها برای جستجوی سریع‌تر
CREATE INDEX IF NOT EXISTS idx_admin_wallet_actions_admin_id ON admin_wallet_actions(admin_id);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_actions_target_user_id ON admin_wallet_actions(target_user_id);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_actions_action_type ON admin_wallet_actions(action_type);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_actions_created_at ON admin_wallet_actions(created_at);
CREATE INDEX IF NOT EXISTS idx_admin_wallet_actions_wallet_id ON admin_wallet_actions(wallet_id);

-- فعال کردن RLS
ALTER TABLE admin_wallet_actions ENABLE ROW LEVEL SECURITY;

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

-- Policy برای ادمین‌ها: می‌توانند تمام عملیات را ببینند
CREATE POLICY "Admins can view all wallet actions" ON admin_wallet_actions
    FOR SELECT USING (check_admin_role());

-- Policy برای ادمین‌ها: می‌توانند عملیات جدید ثبت کنند
CREATE POLICY "Admins can insert wallet actions" ON admin_wallet_actions
    FOR INSERT WITH CHECK (
        check_admin_role()
        AND admin_id = auth.uid()
    );

-- Policy برای کاربران: می‌توانند عملیات مربوط به خودشان را ببینند
CREATE POLICY "Users can view their own wallet actions" ON admin_wallet_actions
    FOR SELECT USING (target_user_id = auth.uid());

-- بررسی نتیجه
SELECT 'Admin wallet actions table created successfully' as status;

