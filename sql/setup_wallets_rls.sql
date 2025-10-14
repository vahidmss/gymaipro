-- تنظیم RLS برای جدول wallets موجود
-- این فایل RLS را برای جدول wallets که از قبل وجود دارد تنظیم می‌کند

-- فعال کردن RLS
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی (اگر وجود داشته باشد)
DROP POLICY IF EXISTS "wallets_policy" ON wallets;
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can create their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;
DROP POLICY IF EXISTS "Service role can do everything on wallets" ON wallets;
DROP POLICY IF EXISTS "Edge function can update wallets" ON wallets;
DROP POLICY IF EXISTS "Edge function can create wallets" ON wallets;
DROP POLICY IF EXISTS "Allow all operations on wallets" ON wallets;

-- ایجاد policy ساده و کارآمد
CREATE POLICY "wallets_policy" ON wallets
  FOR ALL USING (true) WITH CHECK (true);

-- بررسی وضعیت RLS
SELECT 
  schemaname, 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'wallets';

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
WHERE tablename = 'wallets';

-- تست ایجاد رکورد
INSERT INTO wallets (user_id, balance) 
VALUES ('0618fd07-14f0-49f8-9570-b008f0ec8f1f', 0) 
ON CONFLICT (user_id) DO NOTHING;

-- نمایش رکوردهای موجود
SELECT * FROM wallets WHERE user_id = '0618fd07-14f0-49f8-9570-b008f0ec8f1f';
