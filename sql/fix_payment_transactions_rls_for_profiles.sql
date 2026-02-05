-- رفع مشکل RLS برای payment_transactions وقتی user_id به profiles reference می‌کند
-- این فایل RLS را برای جدول payment_transactions تنظیم می‌کند تا با profileId کار کند

-- فعال کردن RLS
ALTER TABLE payment_transactions ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی (اگر وجود داشته باشد)
DROP POLICY IF EXISTS "Users can view their own payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Users can view their payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Users can create their own payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Users can create their payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Users can update their own payment transactions" ON payment_transactions;
DROP POLICY IF EXISTS "Service role can do everything on payment_transactions" ON payment_transactions;

-- ایجاد policies جدید که هم با auth.uid() و هم با profileId کار می‌کند
-- Policy برای SELECT: کاربر می‌تواند تراکنش‌های خود را ببیند
-- اگر user_id = auth.uid() باشد (auth.users.id) یا user_id در profiles با auth_user_id = auth.uid() باشد
CREATE POLICY "Users can view their payment transactions" ON payment_transactions
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = payment_transactions.user_id 
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- Policy برای INSERT: کاربر می‌تواند تراکنش برای خودش ایجاد کند
-- اگر user_id = auth.uid() باشد یا user_id در profiles با auth_user_id = auth.uid() باشد
CREATE POLICY "Users can create their payment transactions" ON payment_transactions
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = payment_transactions.user_id 
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- Policy برای UPDATE: کاربر می‌تواند تراکنش‌های خود را به‌روزرسانی کند
CREATE POLICY "Users can update their payment transactions" ON payment_transactions
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM profiles 
      WHERE profiles.id = payment_transactions.user_id 
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- Service role می‌تواند همه عملیات انجام دهد
CREATE POLICY "Service role can do everything on payment_transactions" ON payment_transactions
  FOR ALL USING (auth.role() = 'service_role');

-- نمایش وضعیت RLS
SELECT 
  schemaname, 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'payment_transactions';

-- نمایش policies موجود
SELECT 
  schemaname, 
  tablename, 
  policyname, 
  permissive, 
  roles, 
  cmd, 
  qual 
FROM pg_policies 
WHERE tablename = 'payment_transactions'
ORDER BY policyname;

