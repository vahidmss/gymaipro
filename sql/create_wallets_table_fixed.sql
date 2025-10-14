-- ایجاد جدول wallets با ساختار درست
-- این فایل جدول wallets را با تمام ستون‌های مورد نیاز ایجاد می‌کند

-- حذف جدول قدیمی (اگر وجود داشته باشد)
DROP TABLE IF EXISTS wallets CASCADE;

-- ایجاد جدول wallets جدید
CREATE TABLE wallets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL UNIQUE REFERENCES auth.users(id) ON DELETE CASCADE,
    balance INTEGER DEFAULT 0 CHECK (balance >= 0),
    blocked_amount INTEGER DEFAULT 0 CHECK (blocked_amount >= 0),
    total_charged INTEGER DEFAULT 0 CHECK (total_charged >= 0),
    total_spent INTEGER DEFAULT 0 CHECK (total_spent >= 0),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- ایجاد ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_wallets_user_id ON wallets(user_id);
CREATE INDEX IF NOT EXISTS idx_wallets_balance ON wallets(balance);

-- فعال کردن RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- ایجاد policy ساده
CREATE POLICY "wallets_policy" ON wallets
  FOR ALL USING (true) WITH CHECK (true);

-- تست ایجاد رکورد
INSERT INTO wallets (user_id, balance) 
VALUES ('0618fd07-14f0-49f8-9570-b008f0ec8f1f', 0) 
ON CONFLICT (user_id) DO NOTHING;

-- نمایش ساختار جدول
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'wallets' 
ORDER BY ordinal_position;

-- نمایش رکوردهای موجود
SELECT * FROM wallets WHERE user_id = '0618fd07-14f0-49f8-9570-b008f0ec8f1f';
