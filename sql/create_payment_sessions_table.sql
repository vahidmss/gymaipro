-- جدول جلسات پرداخت
CREATE TABLE IF NOT EXISTS payment_sessions (
  id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
  session_id VARCHAR(255) UNIQUE NOT NULL,
  user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  amount INTEGER NOT NULL CHECK (amount > 0),
  status VARCHAR(50) DEFAULT 'pending' CHECK (status IN ('pending', 'processing', 'completed', 'failed', 'cancelled')),
  gateway VARCHAR(50),
  gateway_ref VARCHAR(255),
  expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  completed_at TIMESTAMP WITH TIME ZONE,
  metadata JSONB DEFAULT '{}'::jsonb
);

-- ایندکس‌ها
CREATE INDEX IF NOT EXISTS idx_payment_sessions_user_id ON payment_sessions(user_id);
CREATE INDEX IF NOT EXISTS idx_payment_sessions_session_id ON payment_sessions(session_id);
CREATE INDEX IF NOT EXISTS idx_payment_sessions_status ON payment_sessions(status);
CREATE INDEX IF NOT EXISTS idx_payment_sessions_expires_at ON payment_sessions(expires_at);

-- RLS Policies
ALTER TABLE payment_sessions ENABLE ROW LEVEL SECURITY;

-- کاربران فقط جلسات خود را ببینند
CREATE POLICY "Users can view their own payment sessions" ON payment_sessions
  FOR SELECT USING (auth.uid() = user_id);

-- کاربران فقط جلسات خود را ایجاد کنند
CREATE POLICY "Users can create their own payment sessions" ON payment_sessions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

-- کاربران فقط جلسات خود را به‌روزرسانی کنند
CREATE POLICY "Users can update their own payment sessions" ON payment_sessions
  FOR UPDATE USING (auth.uid() = user_id);

-- Service role می‌تواند همه عملیات انجام دهد
CREATE POLICY "Service role can do everything" ON payment_sessions
  FOR ALL USING (auth.role() = 'service_role');

-- تابع پاک کردن جلسات منقضی شده
CREATE OR REPLACE FUNCTION cleanup_expired_payment_sessions()
RETURNS void AS $$
BEGIN
  DELETE FROM payment_sessions 
  WHERE expires_at < NOW() 
  AND status IN ('pending', 'processing');
END;
$$ LANGUAGE plpgsql;

-- تابع به‌روزرسانی updated_at
CREATE OR REPLACE FUNCTION update_payment_sessions_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- تریگر برای به‌روزرسانی updated_at
CREATE TRIGGER payment_sessions_updated_at_trigger
  BEFORE UPDATE ON payment_sessions
  FOR EACH ROW
  EXECUTE FUNCTION update_payment_sessions_updated_at();
