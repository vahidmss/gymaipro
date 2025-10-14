-- Payment System Database Schema for GymAI Pro
-- This script creates all necessary tables for the payment system

-- Enable necessary extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. Payment Transactions Table
CREATE TABLE IF NOT EXISTS payment_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    amount INTEGER NOT NULL CHECK (amount > 0),
    final_amount INTEGER NOT NULL CHECK (final_amount > 0),
    discount_amount INTEGER DEFAULT 0 CHECK (discount_amount >= 0),
    discount_code VARCHAR(50),
    type VARCHAR(20) NOT NULL CHECK (type IN ('payment', 'refund', 'walletCharge', 'walletPayment', 'subscription', 'aiProgram', 'trainerService')),
    status VARCHAR(20) NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled', 'refunded')),
    payment_method VARCHAR(20) NOT NULL CHECK (payment_method IN ('direct', 'wallet', 'mixed')),
    gateway VARCHAR(20) NOT NULL CHECK (gateway IN ('zibal', 'zarinpal', 'wallet')),
    gateway_transaction_id VARCHAR(255),
    gateway_tracking_code VARCHAR(255),
    description TEXT NOT NULL,
    metadata JSONB,
    user_ip INET,
    user_name VARCHAR(255),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    completed_at TIMESTAMP WITH TIME ZONE,
    expires_at TIMESTAMP WITH TIME ZONE
);

-- 2. Subscriptions Table
CREATE TABLE IF NOT EXISTS subscriptions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    plan_id UUID,
    type VARCHAR(20) NOT NULL CHECK (type IN ('monthly', 'yearly', 'lifetime')),
    status VARCHAR(20) NOT NULL DEFAULT 'active' CHECK (status IN ('active', 'expired', 'cancelled', 'suspended')),
    start_date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    end_date TIMESTAMP WITH TIME ZONE NOT NULL,
    auto_renew BOOLEAN DEFAULT false,
    payment_transaction_id UUID REFERENCES payment_transactions(id),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Wallets Table
CREATE TABLE IF NOT EXISTS wallets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INTEGER DEFAULT 0 CHECK (balance >= 0),
    blocked_amount INTEGER DEFAULT 0 CHECK (blocked_amount >= 0),
    total_charged INTEGER DEFAULT 0 CHECK (total_charged >= 0),
    total_spent INTEGER DEFAULT 0 CHECK (total_spent >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Wallet Transactions Table
CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    wallet_id UUID NOT NULL REFERENCES wallets(id) ON DELETE CASCADE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('charge', 'payment', 'refund', 'bonus', 'block', 'unblock')),
    amount INTEGER NOT NULL,
    balance_after INTEGER NOT NULL,
    description TEXT NOT NULL,
    reference_id VARCHAR(255),
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Discount Codes Table
CREATE TABLE IF NOT EXISTS discount_codes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    code VARCHAR(50) NOT NULL UNIQUE,
    type VARCHAR(20) NOT NULL CHECK (type IN ('percentage', 'fixed')),
    value INTEGER NOT NULL CHECK (value > 0),
    max_usage INTEGER,
    used_count INTEGER DEFAULT 0,
    max_usage_per_user INTEGER DEFAULT 1,
    min_amount INTEGER DEFAULT 0,
    max_discount_amount INTEGER,
    is_active BOOLEAN DEFAULT true,
    is_new_user_only BOOLEAN DEFAULT false,
    expiry_date TIMESTAMP WITH TIME ZONE,
    description TEXT,
    created_by UUID REFERENCES auth.users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Discount Usages Table
CREATE TABLE IF NOT EXISTS discount_usages (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    discount_code_id UUID NOT NULL REFERENCES discount_codes(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    transaction_id UUID NOT NULL REFERENCES payment_transactions(id) ON DELETE CASCADE,
    discount_amount INTEGER NOT NULL,
    used_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(discount_code_id, user_id, transaction_id)
);

-- 7. Payment Plans Table
CREATE TABLE IF NOT EXISTS payment_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    name VARCHAR(255) NOT NULL,
    description TEXT,
    type VARCHAR(20) NOT NULL CHECK (type IN ('subscription', 'one_time', 'ai_program', 'trainer_service')),
    price INTEGER NOT NULL CHECK (price > 0),
    duration_days INTEGER,
    access_level VARCHAR(20) NOT NULL CHECK (access_level IN ('basic', 'premium', 'vip')),
    features JSONB,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 8. Subscription History Table
CREATE TABLE IF NOT EXISTS subscription_history (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    subscription_id UUID NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    action VARCHAR(20) NOT NULL CHECK (action IN ('created', 'activated', 'renewed', 'cancelled', 'expired', 'suspended')),
    old_status VARCHAR(20),
    new_status VARCHAR(20),
    reason TEXT,
    metadata JSONB,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_payment_transactions_user_id ON payment_transactions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_status ON payment_transactions(status);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_gateway ON payment_transactions(gateway);
CREATE INDEX IF NOT EXISTS idx_payment_transactions_created_at ON payment_transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_subscriptions_user_id ON subscriptions(user_id);
CREATE INDEX IF NOT EXISTS idx_subscriptions_status ON subscriptions(status);
CREATE INDEX IF NOT EXISTS idx_subscriptions_end_date ON subscriptions(end_date);

CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);

CREATE INDEX IF NOT EXISTS idx_wallet_transactions_wallet_id ON wallet_transactions(wallet_id);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_type ON wallet_transactions(type);
CREATE INDEX IF NOT EXISTS idx_wallet_transactions_created_at ON wallet_transactions(created_at);

CREATE INDEX IF NOT EXISTS idx_discount_codes_code ON discount_codes(code);
CREATE INDEX IF NOT EXISTS idx_discount_codes_is_active ON discount_codes(is_active);
CREATE INDEX IF NOT EXISTS idx_discount_codes_expiry_date ON discount_codes(expiry_date);

CREATE INDEX IF NOT EXISTS idx_discount_usages_discount_code_id ON discount_usages(discount_code_id);
CREATE INDEX IF NOT EXISTS idx_discount_usages_user_id ON discount_usages(user_id);

CREATE INDEX IF NOT EXISTS idx_payment_plans_type ON payment_plans(type);
CREATE INDEX IF NOT EXISTS idx_payment_plans_is_active ON payment_plans(is_active);

CREATE INDEX IF NOT EXISTS idx_subscription_history_subscription_id ON subscription_history(subscription_id);

-- Row Level Security (RLS) Policies

-- Enable RLS on all tables
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_codes ENABLE ROW LEVEL SECURITY;
ALTER TABLE discount_usages ENABLE ROW LEVEL SECURITY;
ALTER TABLE payment_plans ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_history ENABLE ROW LEVEL SECURITY;

-- Payment Transactions RLS Policies
CREATE POLICY "Users can view their own payment transactions" ON payment_transactions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own payment transactions" ON payment_transactions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own payment transactions" ON payment_transactions
    FOR UPDATE USING (auth.uid() = user_id);

-- Subscriptions RLS Policies
CREATE POLICY "Users can view their own subscriptions" ON subscriptions
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own subscriptions" ON subscriptions
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own subscriptions" ON subscriptions
    FOR UPDATE USING (auth.uid() = user_id);

-- Wallets RLS Policies
CREATE POLICY "Users can view their own wallet" ON wallets
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own wallet" ON wallets
    FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
    FOR UPDATE USING (auth.uid() = user_id);

-- Wallet Transactions RLS Policies
CREATE POLICY "Users can view their own wallet transactions" ON wallet_transactions
    FOR SELECT USING (auth.uid() = (SELECT user_id FROM wallets WHERE id = wallet_id));

CREATE POLICY "Users can insert their own wallet transactions" ON wallet_transactions
    FOR INSERT WITH CHECK (auth.uid() = (SELECT user_id FROM wallets WHERE id = wallet_id));

-- Discount Codes RLS Policies (public read, admin write)
CREATE POLICY "Anyone can view active discount codes" ON discount_codes
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins can manage discount codes" ON discount_codes
    FOR ALL USING (auth.uid() = created_by);

-- Discount Usages RLS Policies
CREATE POLICY "Users can view their own discount usages" ON discount_usages
    FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert their own discount usages" ON discount_usages
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Payment Plans RLS Policies (public read)
CREATE POLICY "Anyone can view active payment plans" ON payment_plans
    FOR SELECT USING (is_active = true);

-- Subscription History RLS Policies
CREATE POLICY "Users can view their own subscription history" ON subscription_history
    FOR SELECT USING (auth.uid() = (SELECT user_id FROM subscriptions WHERE id = subscription_id));

-- Create functions for automatic updates
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers for updated_at
CREATE TRIGGER update_payment_transactions_updated_at BEFORE UPDATE ON payment_transactions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_subscriptions_updated_at BEFORE UPDATE ON subscriptions
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_wallets_updated_at BEFORE UPDATE ON wallets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_discount_codes_updated_at BEFORE UPDATE ON discount_codes
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_payment_plans_updated_at BEFORE UPDATE ON payment_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- Insert sample payment plans
INSERT INTO payment_plans (name, description, type, price, duration_days, access_level, features) VALUES
('اشتراک ماهانه', 'دسترسی کامل به تمام ویژگی‌های اپلیکیشن', 'subscription', 50000, 31, 'premium', '{"ai_programs": true, "trainer_services": true, "premium_features": true}'),
('اشتراک سالانه', 'دسترسی کامل به تمام ویژگی‌های اپلیکیشن برای یک سال', 'subscription', 500000, 365, 'premium', '{"ai_programs": true, "trainer_services": true, "premium_features": true}'),
('برنامه هوش مصنوعی', 'ساخت برنامه تمرینی با هوش مصنوعی', 'ai_program', 25000, NULL, 'basic', '{"ai_generation": true}'),
('خدمات مربی', 'درخواست برنامه از مربی حرفه‌ای', 'trainer_service', 100000, NULL, 'premium', '{"trainer_consultation": true}');

-- Insert sample discount codes
INSERT INTO discount_codes (code, type, value, max_usage, min_amount, description, is_new_user_only) VALUES
('WELCOME20', 'percentage', 20, 100, 0, 'کد تخفیف خوش آمدید - 20% تخفیف', true),
('FIRST50', 'fixed', 50000, 50, 100000, 'تخفیف ویژه اولین خرید - 50,000 تومان', false),
('VIP30', 'percentage', 30, 20, 200000, 'تخفیف ویژه VIP - 30% تخفیف', false);

-- Create a function to automatically create wallet for new users
CREATE OR REPLACE FUNCTION create_user_wallet()
RETURNS TRIGGER AS $$
BEGIN
    INSERT INTO wallets (user_id) VALUES (NEW.id);
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create trigger to create wallet for new users
CREATE TRIGGER create_wallet_for_new_user
    AFTER INSERT ON auth.users
    FOR EACH ROW EXECUTE FUNCTION create_user_wallet();

-- Create a function to update subscription status based on end_date
CREATE OR REPLACE FUNCTION update_expired_subscriptions()
RETURNS void AS $$
BEGIN
    UPDATE subscriptions 
    SET status = 'expired', updated_at = NOW()
    WHERE status = 'active' AND end_date < NOW();
END;
$$ language 'plpgsql';

-- Create a function to update discount codes status based on expiry_date
CREATE OR REPLACE FUNCTION update_expired_discount_codes()
RETURNS void AS $$
BEGIN
    UPDATE discount_codes 
    SET is_active = false, updated_at = NOW()
    WHERE is_active = true AND expiry_date IS NOT NULL AND expiry_date < NOW();
END;
$$ language 'plpgsql';
