-- اجرای یکجا فیکسهای RLS برای جداولی که user_id به profiles.id اشاره می‌کند
-- این فایل را یک بار در Supabase → SQL Editor اجرا کنید.

-- ========== 1. food_logs ==========
ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can insert their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can update their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can delete their own food logs" ON public.food_logs;

CREATE POLICY "Users can view their own food logs" ON public.food_logs
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = food_logs.user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can insert their own food logs" ON public.food_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can update their own food logs" ON public.food_logs
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = food_logs.user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can delete their own food logs" ON public.food_logs
  FOR DELETE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = food_logs.user_id AND profiles.auth_user_id = auth.uid())
  );

-- ========== 2. user_activity_tracking ==========
ALTER TABLE public.user_activity_tracking ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own activity tracking" ON public.user_activity_tracking;
DROP POLICY IF EXISTS "Users can insert their own activity tracking" ON public.user_activity_tracking;
DROP POLICY IF EXISTS "Users can update their own activity tracking" ON public.user_activity_tracking;

CREATE POLICY "Users can view their own activity tracking" ON public.user_activity_tracking
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_activity_tracking.user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can insert their own activity tracking" ON public.user_activity_tracking
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can update their own activity tracking" ON public.user_activity_tracking
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_activity_tracking.user_id AND profiles.auth_user_id = auth.uid())
  );

-- ========== 3. user_rankings ==========
ALTER TABLE public.user_rankings ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view their own ranking" ON public.user_rankings;
DROP POLICY IF EXISTS "Users can insert their own ranking" ON public.user_rankings;
DROP POLICY IF EXISTS "Users can update their own ranking" ON public.user_rankings;

CREATE POLICY "Users can view their own ranking" ON public.user_rankings
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_rankings.user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can insert their own ranking" ON public.user_rankings
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_id AND profiles.auth_user_id = auth.uid())
  );
CREATE POLICY "Users can update their own ranking" ON public.user_rankings
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_rankings.user_id AND profiles.auth_user_id = auth.uid())
  );

-- نمایش وضعیت
SELECT tablename, policyname, cmd FROM pg_policies
WHERE tablename IN ('food_logs', 'user_activity_tracking', 'user_rankings')
ORDER BY tablename, policyname;
