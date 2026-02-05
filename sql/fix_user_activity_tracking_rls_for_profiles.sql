-- رفع مشکل RLS برای user_activity_tracking وقتی user_id به profiles.id اشاره می‌کند (نه auth.uid())
-- جدول user_id REFERENCES profiles(id) است؛ پالیسی قبلی auth.uid() = user_id باعث خطا می‌شد.

ALTER TABLE public.user_activity_tracking ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view their own activity tracking" ON public.user_activity_tracking;
DROP POLICY IF EXISTS "Users can insert their own activity tracking" ON public.user_activity_tracking;
DROP POLICY IF EXISTS "Users can update their own activity tracking" ON public.user_activity_tracking;

-- SELECT
CREATE POLICY "Users can view their own activity tracking" ON public.user_activity_tracking
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = user_activity_tracking.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- INSERT
CREATE POLICY "Users can insert their own activity tracking" ON public.user_activity_tracking
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- UPDATE
CREATE POLICY "Users can update their own activity tracking" ON public.user_activity_tracking
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = user_activity_tracking.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'user_activity_tracking'
ORDER BY policyname;
