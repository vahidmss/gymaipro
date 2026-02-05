-- رفع مشکل RLS برای food_logs وقتی user_id به profiles.id اشاره می‌کند (نه auth.uid())
-- خطا: new row violates row-level security policy for table "food_logs"

ALTER TABLE public.food_logs ENABLE ROW LEVEL SECURITY;

-- حذف policies قدیمی
DROP POLICY IF EXISTS "Users can view their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can insert their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can update their own food logs" ON public.food_logs;
DROP POLICY IF EXISTS "Users can delete their own food logs" ON public.food_logs;

-- SELECT: کاربر می‌تواند لاگ‌های خود را ببیند
-- وقتی user_id = auth.uid() (legacy) یا user_id برابر profile.id جاری با auth_user_id = auth.uid()
CREATE POLICY "Users can view their own food logs" ON public.food_logs
  FOR SELECT USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = food_logs.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- INSERT: کاربر می‌تواند لاگ برای خودش ایجاد کند
CREATE POLICY "Users can insert their own food logs" ON public.food_logs
  FOR INSERT WITH CHECK (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- UPDATE: کاربر می‌تواند لاگ‌های خود را به‌روزرسانی کند
CREATE POLICY "Users can update their own food logs" ON public.food_logs
  FOR UPDATE USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = food_logs.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- DELETE: کاربر می‌تواند لاگ‌های خود را حذف کند
CREATE POLICY "Users can delete their own food logs" ON public.food_logs
  FOR DELETE USING (
    user_id = auth.uid() OR
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE profiles.id = food_logs.user_id
      AND profiles.auth_user_id = auth.uid()
    )
  );

-- نمایش وضعیت
SELECT schemaname, tablename, policyname, cmd
FROM pg_policies
WHERE tablename = 'food_logs'
ORDER BY policyname;
