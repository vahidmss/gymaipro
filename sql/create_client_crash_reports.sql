-- گزارش کرش کلاینت — جایگزین Crashlytics برای توزیع سایدلود ایران
-- این اسکریپت را یک‌بار روی Supabase اجرا کنید.

CREATE TABLE IF NOT EXISTS public.client_crash_reports (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
  error_message TEXT NOT NULL,
  stack_trace TEXT,
  fingerprint TEXT,
  app_version TEXT,
  build_number TEXT,
  platform TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_client_crash_reports_created_at
  ON public.client_crash_reports (created_at DESC);

CREATE INDEX IF NOT EXISTS idx_client_crash_reports_fingerprint
  ON public.client_crash_reports (fingerprint);

ALTER TABLE public.client_crash_reports ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "users insert own crash reports"
  ON public.client_crash_reports;
CREATE POLICY "users insert own crash reports"
  ON public.client_crash_reports
  FOR INSERT
  TO authenticated
  WITH CHECK (user_id IS NULL OR user_id = auth.uid());

DROP POLICY IF EXISTS "admins read crash reports"
  ON public.client_crash_reports;
CREATE POLICY "admins read crash reports"
  ON public.client_crash_reports
  FOR SELECT
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );

DROP POLICY IF EXISTS "admins delete crash reports"
  ON public.client_crash_reports;
CREATE POLICY "admins delete crash reports"
  ON public.client_crash_reports
  FOR DELETE
  TO authenticated
  USING (
    EXISTS (
      SELECT 1 FROM public.profiles
      WHERE id = auth.uid() AND role = 'admin'
    )
  );
