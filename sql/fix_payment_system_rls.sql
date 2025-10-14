-- رفع کامل مشکلات RLS سیستم پرداخت
-- این فایل تمام RLS policies مورد نیاز را اضافه می‌کند

-- 1. رفع مشکل RLS برای جدول wallets
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی (اگر وجود داشته باشد)
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can create their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Service role can do everything on wallets" ON wallets;
DROP POLICY IF EXISTS "Edge function can update wallets" ON wallets;
DROP POLICY IF EXISTS "Edge function can create wallets" ON wallets;

-- ایجاد policies جدید برای wallets
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their own wallet" ON wallets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);

-- Service role و Edge Function دسترسی کامل دارند
CREATE POLICY "Service role can do everything on wallets" ON wallets
  FOR ALL USING (auth.role() = 'service_role');

-- 2. رفع مشکل RLS برای جدول wallet_transactions
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی
DROP POLICY IF EXISTS "Users can view their wallet transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Service role can do everything on wallet_transactions" ON wallet_transactions;

-- ایجاد policies جدید برای wallet_transactions
CREATE POLICY "Users can view their wallet transactions" ON wallet_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM wallets 
      WHERE wallets.id = wallet_transactions.wallet_id 
      AND wallets.user_id = auth.uid()
    )
  );

CREATE POLICY "Service role can do everything on wallet_transactions" ON wallet_transactions
  FOR ALL USING (auth.role() = 'service_role');

-- 3. رفع مشکل RLS برای جدول payment_transactions
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی
DROP POLICY IF EXISTS "Users can view their payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Users can create their payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Service role can do everything on payment_transactions" ON payment_transactions;

-- ایجاد policies جدید برای payment_transactions
CREATE POLICY "Users can view their payment transactions" ON payment_transactions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their payment transactions" ON payment_transactions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can do everything on payment_transactions" ON payment_transactions
  FOR ALL USING (auth.role() = 'service_role');

-- 4. رفع مشکل RLS برای جدول subscriptions
ALTER TABLE subscriptions ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی
DROP POLICY IF EXISTS "Users can view their subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Users can create their subscriptions" ON subscriptions;
DROP POLICY IF EXISTS "Service role can do everything on subscriptions" ON subscriptions;

-- ایجاد policies جدید برای subscriptions
CREATE POLICY "Users can view their subscriptions" ON subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can create their subscriptions" ON subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Service role can do everything on subscriptions" ON subscriptions
  FOR ALL USING (auth.role() = 'service_role');

-- 5. نمایش وضعیت RLS
SELECT 
  schemaname, 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename IN ('wallets', 'wallet_transactions', 'payment_transactions', 'subscriptions', 'payment_sessions')
ORDER BY tablename;

-- 6. نمایش policies موجود
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename IN ('wallets', 'wallet_transactions', 'payment_transactions', 'subscriptions', 'payment_sessions')
ORDER BY tablename, policyname;
