-- ایجاد جدول اشتراک‌های مربی
CREATE TABLE IF NOT EXISTS trainer_subscriptions (
    id TEXT PRIMARY KEY,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    trainer_id UUID NOT NULL REFERENCES profiles(id) ON DELETE CASCADE,
    service_type TEXT NOT NULL CHECK (service_type IN ('training', 'diet', 'consulting', 'package')),
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'active', 'expired', 'cancelled', 'suspended')),
    original_amount INTEGER NOT NULL,
    final_amount INTEGER NOT NULL,
    discount_amount INTEGER DEFAULT 0,
    discount_code TEXT,
    discount_percentage REAL DEFAULT 0.0,
    payment_transaction_id TEXT REFERENCES payment_transactions(id),
    purchase_date TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    program_registration_date TIMESTAMPTZ,
    first_usage_date TIMESTAMPTZ,
    expiry_date TIMESTAMPTZ NOT NULL,
    program_status TEXT DEFAULT 'not_started' CHECK (program_status IN ('not_started', 'in_progress', 'completed', 'delayed')),
    trainer_delay_days INTEGER DEFAULT 0,
    cancellation_reason TEXT,
    metadata JSONB,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_user_id ON trainer_subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_trainer_id ON trainer_subscriptions(trainer_id);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_status ON trainer_subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_service_type ON trainer_subscriptions(service_type);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_expiry_date ON trainer_subscriptions(expiry_date);
CREATE INDEX IF NOT EXISTS idx_trainer_subscriptions_purchase_date ON trainer_subscriptions(purchase_date);

-- RLS (Row Level Security)
ALTER TABLE trainer_subscriptions ENABLE ROW LEVEL SECURITY;

-- سیاست‌های دسترسی
CREATE POLICY "Users can view their own subscriptions" ON trainer_subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Trainers can view their subscriptions" ON trainer_subscriptions
    FOR SELECT USING (auth.uid() = trainer_id);

CREATE POLICY "Users can insert their own subscriptions" ON trainer_subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Trainers can update program status" ON trainer_subscriptions
    FOR UPDATE USING (auth.uid() = trainer_id)
    WITH CHECK (auth.uid() = trainer_id);

-- تریگر برای به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_trainer_subscriptions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_trainer_subscriptions_updated_at
    BEFORE UPDATE ON trainer_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_trainer_subscriptions_updated_at();
