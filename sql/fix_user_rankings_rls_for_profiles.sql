-- رفع مشکل RLS برای user_rankings وقتی user_id به profiles.id اشاره می‌کند (نه auth.uid())
-- جدول user_id REFERENCES profiles(id) است؛ پالیسی "view own" با auth.uid() = user_id برای profile-id کاربران خطا می‌داد.

ALTER TABLE public.user_rankings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own ranking" ON public.user_rankings;

-- SELECT: کاربر می‌تواند رتبه خود را ببیند (با profile id یا auth id)
CREATE POLICY "Users can view their own ranking" ON public.user_rankings
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = user_rankings.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- INSERT
DROP POLICY IF EXISTS "Users can insert their own ranking" ON public.user_rankings;
CREATE POLICY "Users can insert their own ranking" ON public.user_rankings
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_id AND profiles.auth_user_id = auth.uid())
  );

DROP POLICY IF EXISTS "Users can update their own ranking" ON public.user_rankings;
CREATE POLICY "Users can update their own ranking" ON public.user_rankings
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (SELECT 1 FROM public.profiles WHERE profiles.id = user_rankings.user_id AND profiles.auth_user_id = auth.uid())
  );

SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'user_rankings'
ORDER BY policyname;
