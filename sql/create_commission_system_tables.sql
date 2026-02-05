-- ایجاد جداول سیستم کمیسیون و برداشت مربی

-- 1. جدول تنظیمات کمیسیون
CREATE TABLE IF NOT EXISTS commission_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    commission_percentage REAL NOT NULL CHECK (commission_percentage >= 0 AND commission_percentage <= 100),
    hold_days INTEGER NOT NULL DEFAULT 3 CHECK (hold_days >= 0),
    is_active BOOLEAN DEFAULT true,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ایجاد ایندکس
CREATE INDEX IF NOT EXISTS idx_commission_settings_is_active ON commission_settings(is_active);

-- RLS
ALTER TABLE commission_settings ENABLE ROW LEVEL SECURITY;

-- Policy: فقط ادمین‌ها می‌تونن ببینن و تغییر بدن
CREATE POLICY "Admins can manage commission settings" ON commission_settings
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- Policy: همه می‌تونن تنظیمات فعال رو ببینن
CREATE POLICY "Anyone can view active commission settings" ON commission_settings
    FOR SELECT USING (is_active = true);

-- 2. جدول درخواست‌های برداشت
CREATE TABLE IF NOT EXISTS payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL CHECK (amount > 0),
    final_amount INTEGER CHECK (final_amount >= 0),
    card_number TEXT NOT NULL,
    card_owner_name TEXT NOT NULL,
    bank_name TEXT,
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed')),
    penalty_amount INTEGER DEFAULT 0 CHECK (penalty_amount >= 0),
    penalty_reason TEXT,
    admin_notes TEXT,
    reviewed_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    reviewed_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_payout_requests_trainer_id ON payout_requests(trainer_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON payout_requests(status);
CREATE INDEX IF NOT EXISTS idx_payout_requests_created_at ON payout_requests(created_at);

-- RLS
ALTER TABLE payout_requests ENABLE ROW LEVEL SECURITY;

-- Policy: مربی می‌تونه درخواست‌های خودش رو ببینه و ایجاد کنه
CREATE POLICY "Trainers can manage their own payout requests" ON payout_requests
    FOR ALL USING (auth.uid() = trainer_id)
    WITH CHECK (auth.uid() = trainer_id);

-- Policy: ادمین‌ها می‌تونن همه درخواست‌ها رو ببینن و مدیریت کنن
CREATE POLICY "Admins can manage all payout requests" ON payout_requests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 3. جدول درآمد پلتفرم
CREATE TABLE IF NOT EXISTS platform_revenue (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    transaction_id TEXT REFERENCES payment_transactions(id),
    subscription_id TEXT REFERENCES trainer_subscriptions(id),
    trainer_id UUID REFERENCES profiles(id),
    amount INTEGER NOT NULL CHECK (amount >= 0),
    commission_percentage REAL NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_platform_revenue_transaction_id ON platform_revenue(transaction_id);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_subscription_id ON platform_revenue(subscription_id);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_trainer_id ON platform_revenue(trainer_id);
CREATE INDEX IF NOT EXISTS idx_platform_revenue_created_at ON platform_revenue(created_at);

-- RLS
ALTER TABLE platform_revenue ENABLE ROW LEVEL SECURITY;

-- Policy: فقط ادمین‌ها می‌تونن ببینن
CREATE POLICY "Admins can view platform revenue" ON platform_revenue
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM profiles 
            WHERE profiles.id = auth.uid() 
            AND profiles.role = 'admin'
        )
    );

-- 4. اضافه کردن فیلدهای جدید به جدول wallets
ALTER TABLE wallets 
ADD COLUMN IF NOT EXISTS trainer_earnings INTEGER DEFAULT 0 CHECK (trainer_earnings >= 0),
ADD COLUMN IF NOT EXISTS trainer_withdrawable INTEGER DEFAULT 0 CHECK (trainer_withdrawable >= 0);

-- ایجاد ایندکس برای فیلدهای جدید
CREATE INDEX IF NOT EXISTS idx_wallets_trainer_earnings ON wallets(trainer_earnings) WHERE trainer_earnings > 0;
CREATE INDEX IF NOT EXISTS idx_wallets_trainer_withdrawable ON wallets(trainer_withdrawable) WHERE trainer_withdrawable > 0;

-- تریگر برای به‌روزرسانی updated_at در commission_settings
CREATE OR REPLACE FUNCTION update_commission_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_commission_settings_updated_at
    BEFORE UPDATE ON commission_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_commission_settings_updated_at();

-- تریگر برای به‌روزرسانی updated_at در payout_requests
CREATE OR REPLACE FUNCTION update_payout_requests_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_payout_requests_updated_at
    BEFORE UPDATE ON payout_requests
    FOR EACH ROW
    EXECUTE FUNCTION update_payout_requests_updated_at();

-- ایجاد یک رکورد پیش‌فرض برای تنظیمات کمیسیون (20% کمیسیون، 3 روز انتظار)
INSERT INTO commission_settings (commission_percentage, hold_days, is_active)
VALUES (20.0, 3, true)
ON CONFLICT DO NOTHING;

