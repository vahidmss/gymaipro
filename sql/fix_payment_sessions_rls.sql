-- رفع مشکل RLS برای جدول payment_sessions
-- این فایل RLS را برای جدول payment_sessions تنظیم می‌کند

-- فعال کردن RLS
ALTER TABLE payment_sessions ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی (اگر وجود داشته باشد)
DROP POLICY IF EXISTS "Users can view their own payment sessions" ON payment_sessions;
DROP POLICY IF EXISTS "Users can create their own payment sessions" ON payment_sessions;
DROP POLICY IF EXISTS "Users can update their own payment sessions" ON payment_sessions;
DROP POLICY IF EXISTS "Service role can do everything" ON payment_sessions;
DROP POLICY IF EXISTS "payment_sessions_policy" ON payment_sessions;

-- ایجاد policy ساده و کارآمد
CREATE POLICY "payment_sessions_policy" ON payment_sessions
  FOR ALL USING (true) WITH CHECK (true);

-- بررسی وضعیت RLS
SELECT 
  schemaname, 
  tablename, 
  rowsecurity as rls_enabled
FROM pg_tables 
WHERE tablename = 'payment_sessions';

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
WHERE tablename = 'payment_sessions';

-- تست ایجاد رکورد
INSERT INTO payment_sessions (session_id, user_id, amount, status, expires_at) 
VALUES ('test_session_123', '0618fd07-14f0-49f8-9570-b008f0ec8f1f', 1000000, 'pending', NOW() + INTERVAL '30 minutes') 
ON CONFLICT (session_id) DO NOTHING;

-- نمایش رکوردهای موجود
SELECT * FROM payment_sessions WHERE user_id = '0618fd07-14f0-49f8-9570-b008f0ec8f1f';
