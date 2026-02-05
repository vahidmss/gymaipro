-- رفع خطای RLS برای wallet_transactions و trainer_subscriptions وقتی user_id = profiles.id است
-- و رفع infinite recursion در policy برای relation "profiles" (42P17).
--
-- علت بازگشت بی‌نهایت: پالیسی‌های جداول دیگر به profiles ارجاع می‌دادند؛
-- هنگام خواندن profiles، همان پالیسی‌ها دوباره profiles را می‌خواندند.
-- راه‌حل: تابع SECURITY DEFINER که با حقوق مالک profiles را می‌خواند و در پالیسی‌ها فقط از تابع استفاده می‌شود.
--
-- این اسکریپت را در Supabase Dashboard > SQL Editor اجرا کنید.

-- ========== 0. تابع کمکی (بدون ایجاد بازگشت در RLS) ==========
CREATE OR REPLACE FUNCTION public.current_user_profile_id()
RETURNS UUID
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT id FROM public.profiles WHERE auth_user_id = auth.uid() LIMIT 1;
$$;

COMMENT ON FUNCTION public.current_user_profile_id() IS 'Profile id for current auth user; use in RLS to avoid referencing profiles table (prevents infinite recursion).';


-- ========== 1. wallet_transactions ==========
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their wallet transactions" ON wallet_transactions;
DROP POLICY IF EXISTS "Users can create their wallet transactions" ON wallet_transactions;

-- SELECT: بدون ارجاع به profiles؛ فقط wallets و تابع
CREATE POLICY "Users can view their wallet transactions" ON wallet_transactions
  FOR SELECT USING (
    EXISTS (
      SELECT 1 FROM wallets w
      WHERE w.id = wallet_transactions.wallet_id
        AND (w.user_id = auth.uid() OR w.user_id = public.current_user_profile_id())
    )
  );

-- INSERT: بدون ارجاع به profiles
CREATE POLICY "Users can create their wallet transactions" ON wallet_transactions
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );


-- ========== 2. trainer_subscriptions ==========
ALTER TABLE trainer_subscriptions ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can insert their own subscriptions" ON trainer_subscriptions;
DROP POLICY IF EXISTS "Users can insert their subscriptions" ON trainer_subscriptions;
DROP POLICY IF EXISTS "Users can view their own subscriptions" ON trainer_subscriptions;
DROP POLICY IF EXISTS "Trainers can view their subscriptions" ON trainer_subscriptions;
DROP POLICY IF EXISTS "Trainers can update program status" ON trainer_subscriptions;

-- INSERT
CREATE POLICY "Users can insert their own subscriptions" ON trainer_subscriptions
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );

-- SELECT برای کاربر
CREATE POLICY "Users can view their own subscriptions" ON trainer_subscriptions
  FOR SELECT USING (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );

-- SELECT برای مربی
CREATE POLICY "Trainers can view their subscriptions" ON trainer_subscriptions
  FOR SELECT USING (
    trainer_id = auth.uid() OR trainer_id = public.current_user_profile_id()
  );

-- UPDATE برای مربی
CREATE POLICY "Trainers can update program status" ON trainer_subscriptions
  FOR UPDATE USING (
    trainer_id = auth.uid() OR trainer_id = public.current_user_profile_id()
  )
  WITH CHECK (
    trainer_id = auth.uid() OR trainer_id = public.current_user_profile_id()
  );


-- ========== 3. wallets ==========
DROP POLICY IF EXISTS "Users can view their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can create their own wallet" ON wallets;
DROP POLICY IF EXISTS "Users can update their own wallet" ON wallets;

CREATE POLICY "Users can view their own wallet" ON wallets
  FOR SELECT USING (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );

CREATE POLICY "Users can create their own wallet" ON wallets
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );

CREATE POLICY "Users can update their own wallet" ON wallets
  FOR UPDATE USING (
    user_id = auth.uid() OR user_id = public.current_user_profile_id()
  );

SELECT 'RLS updated: recursion fix applied (policies use current_user_profile_id() instead of profiles).' AS status;
