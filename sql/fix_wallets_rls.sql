-- رفع مشکل RLS برای جدول wallets
-- این فایل RLS policies را برای جدول wallets اضافه می‌کند

-- فعال کردن RLS برای جدول wallets
ALTER TABLE wallets ENABLE ROW LEVEL SECURITY;

-- کاربران فقط کیف پول خود را ببینند
CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (auth.uid() = user_id);

-- کاربران فقط کیف پول خود را ایجاد کنند
CREATE POLICY "Users can create their own wallet" ON wallets
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- کاربران فقط کیف پول خود را به‌روزرسانی کنند
CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (auth.uid() = user_id);

-- Service role می‌تواند همه عملیات انجام دهد
CREATE POLICY "Service role can do everything on wallets" ON wallets
  FOR ALL USING (auth.role() = 'service_role');

-- Edge Function می‌تواند کیف پول را به‌روزرسانی کند
CREATE POLICY "Edge function can update wallets" ON wallets
  FOR UPDATE USING (true);

-- Edge Function می‌تواند کیف پول جدید ایجاد کند
CREATE POLICY "Edge function can create wallets" ON wallets
  FOR INSERT WITH CHECK (true);

-- نمایش policies موجود
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
FROM pg_policies 
WHERE tablename = 'wallets';
